# Grupos compartidos — diseño (Fase 2)

Sincronizar un **grupo de gastos** entre personas con cuentas de iCloud distintas,
para que vean el mismo **pozo común** en tiempo real. Decisión de producto:
**CKShare nativo** + permisos **"ver todo, editar lo propio"**.

## Por qué híbrido (y no migrar todo)

SwiftData **no soporta** CloudKit compartido: su `ModelConfiguration` solo permite
`.automatic`, `.private` o `.none` — no hay `.shared`. La API **oficial** de Apple
para CKShare es `NSPersistentCloudKitContainer` (Core Data), que sí maneja stores
privado **y** compartido, `share(_:to:)`, `UICloudSharingController` y la aceptación
de invitaciones.

En vez de migrar TODA la app a Core Data (paso atrás respecto a la dirección de
Apple, y riesgoso para los datos existentes), usamos un **híbrido**:

- **SwiftData** sigue dueño de todo lo privado (transacciones, categorías, tarjetas,
  reglas, snapshot del widget). Sin cambios, a prueba de futuro.
- **Un store dedicado `NSPersistentCloudKitContainer`** maneja SOLO las entidades
  compartidas del grupo, usando la API oficial de sharing.

Cuando Apple agregue CKShare a SwiftData, migrar la porción del grupo de vuelta es
acotado: solo son 3 entidades.

## Modelo de datos compartido (Core Data, store NSPCC)

Espejo mínimo de lo que hoy es SwiftData `Grupo`/`Persona`, más autoría de aportes:

- `GrupoCompartido`: `id`, `nombre`, `creadoEl`.
- `MiembroGrupo`: `id`, `nombre`, `usuarioID` (CKShare participant / userRecordID),
  `rol` (`dueno`|`miembro`), relación → grupo. Reemplaza a `Persona` en lo compartido.
- `AporteCompartido`: `id`, `monto` (CLP, entero), `comercio`, `fecha`,
  `autorID` (usuarioID de quien lo creó), `nombreTarjeta`, relación → grupo.
  Es el gasto que entra al pozo; **no** referencia la `Transaccion` privada (vive en
  otra zona/cuenta). La app puede crear el aporte espejo al guardar un gasto cuya
  tarjeta pertenece a un grupo compartido.

Regla CloudKit (igual que el resto): atributos con default u opcionales, relaciones
opcionales, sin `.unique`.

## Permisos — "ver todo, editar lo propio"

Implementado y testeado en [`PermisosCompartir.swift`](../Xpense/Core/PermisosCompartir.swift):

- `puedeVerPozo` → siempre (todos ven el total y el desglose por persona).
- `puedeEditarGasto(autorID, miUsuarioID)` → solo el autor; el rol no importa.
- `puedeAdministrarGrupo(rol)` → solo el dueño (agregar/quitar personas, invitar,
  renombrar/eliminar).
- `puedeConfigurarTarjeta(rol, duenoTarjetaID, miUsuarioID)` → dueño del grupo o
  dueño de la tarjeta.

El CKShare se crea con `publicPermission = .none` y participantes con
`.readWrite`; la restricción de "editar lo propio" la impone la **app** (CloudKit a
nivel de share da escritura a todos los participantes), validando `autorID` antes de
permitir editar/borrar.

## Flujos

### Crear y compartir
1. El dueño crea el grupo (ya existe, local). Toca **"Invitar personas"**.
2. La app crea un `CKShare` para el `GrupoCompartido` y presenta
   `UICloudSharingController`. El dueño envía el link (Mensajes/Mail).
3. `usuarioID` del dueño se guarda en su `MiembroGrupo` con `rol = .dueno`.

### Aceptar invitación
1. El invitado toca el link → iOS lanza la app con `CKShare.Metadata`.
2. `AppDelegate.application(_:userDidAcceptCloudKitShareWith:)` →
   `CompartirGrupo.aceptarInvitacion` (ya implementado, groundwork).
3. La zona compartida aparece en el store NSPCC compartido; se crea/asocia su
   `MiembroGrupo` con `rol = .miembro`.

### Aporte al pozo
- Al guardar un gasto cuya tarjeta pertenece a una persona de un grupo compartido y
  que aporta (default de tarjeta u override del gasto), la app **inserta/actualiza**
  un `AporteCompartido` con `autorID = miUsuarioID()`.
- El pozo del grupo suma los `AporteCompartido` del mes; el desglose por persona usa
  `autorID`/`usuarioID`. (Hoy `MotorPresupuesto.pozo` lo hace sobre datos locales; en
  2b pasa a leer del store compartido.)

## Configuración

- Entitlements: `CloudKit` + **DOS** `icloud-container-identifiers`:
  `iCloud.cl.trodriguezam.xpense` (SwiftData, datos privados — va primero) y
  `iCloud.cl.trodriguezam.xpense.grupos` (NSPCC de grupos compartidos). **Deben ser
  contenedores distintos**: si SwiftData y el NSPCC comparten contenedor, el mirroring
  del segundo no inicializa y `container.share(...)` revienta con un fatalError
  (`nil while implicitly unwrapping`). Verificado en device el 22-jun-2026. Un
  contenedor recién provisionado da `CKError 1014 "Bad Container"` un par de minutos
  hasta que propaga en los servidores de Apple; luego la hoja de compartir funciona.
- Info.plist: `CKSharingSupported = true` (agregado, permite lanzar la app desde el
  link del share).
- `UIBackgroundModes: remote-notification` (ya está) para sync silencioso.

## Plan de prueba (hardware, no simulador)

CKShare **no** funciona en el simulador. Se prueba con **2 dispositivos reales** y
**2 Apple IDs** distintos (ambos con iCloud activo):

1. Dispositivo A (dueño): crea grupo "Casa", invita por Mensajes al Apple ID B.
2. Dispositivo B: acepta el link → ve el grupo "Casa" y el pozo.
3. A agrega un gasto que aporta → B ve el pozo subir (y viceversa).
4. B intenta editar un gasto de A → la UI lo bloquea (permiso "editar lo propio").
5. Modo avión en B, agrega un aporte, vuelve a conexión → sincroniza sin duplicar.
6. El dueño quita a B del grupo → B deja de ver el pozo.

La lógica de permisos y de cálculo del pozo va cubierta por tests unitarios
([`PermisosCompartirTests`](../XpenseTests/PermisosCompartirTests.swift)); el sync
real es lo único que exige hardware.

## Estado

- ✅ Fase 2a: permisos + tests, `CompartirGrupo` (aceptación), `CKSharingSupported`.
- 🟡 Fase 2b (fundación lista, compila):
  - ✅ `StoreCompartido.swift`: `NSPersistentCloudKitContainer` con stores privado +
    compartido y modelo Core Data **programático** (`GrupoCompartidoMO`, `MiembroGrupoMO`,
    `AporteCompartidoMO`). Degrada a local sin iCloud.
  - ✅ `CompartirGrupo`: `aceptarInvitacion` (vía `acceptShareInvitations`), `compartir`
    (crea el `CKShare` con `container.share`), `shareExistente`, `miUsuarioID`.
  - ✅ Espejo del grupo local: `Grupo.idCompartido` enlaza al `GrupoCompartidoMO`;
    `StoreCompartido.espejo(...)` lo crea con su miembro **dueño** (yo) la primera vez
    que se invita.
  - ⏳ Falta (no bloquea invitar): crear `AporteCompartido` espejo al guardar un gasto
    cuya tarjeta aporta, y que `MotorPresupuesto.pozo` lea del store compartido cuando
    el grupo está compartido. Hoy el pozo sigue calculándose sobre datos locales.
- 🟡 Fase 2c (UI lista, compila, **sin verificar en hardware**):
  - ✅ `CloudSharingSheet.swift`: envuelve `UICloudSharingController` en SwiftUI.
  - ✅ Botón **"Invitar personas"** en `DetalleGrupoView` → crea/espeja el grupo, crea el
    `CKShare` y presenta la hoja. En simulador (sin iCloud) degrada con un aviso amable
    (`CKAccountStatusNoAccount`), no se cae.
  - ⏳ Falta: **probar el sync real en 2 equipos** con 2 Apple IDs (ver Plan de prueba).
