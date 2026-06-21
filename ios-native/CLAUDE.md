# xpense — versión nativa (Swift / SwiftUI / SwiftData)

Lee primero el [`CLAUDE.md` raíz](../CLAUDE.md) para las reglas de negocio compartidas y la
paleta. Este archivo cubre solo lo específico de la app nativa.

Se compila en **Mac** con Xcode 15+, target **iOS 17+**. Idioma fuente: español; inglés vía
`Shared/Localizable.xcstrings`.

## Build (importante: el `.xcodeproj` NO está versionado)

El proyecto se genera con **XcodeGen** desde `project.yml`. Nunca edites el `.xcodeproj` a
mano para cambios estructurales — edita `project.yml` y regenera:

```bash
brew install xcodegen        # una vez
cd ios-native
xcodegen generate
open Xpense.xcodeproj
```

Si agregas/quitas archivos fuente, targets, entitlements o capabilities → va en `project.yml`.
Team ID y bundle IDs también viven ahí. Ver también la memoria `ios-native-build`.

## Arquitectura

Dos targets (`project.yml`): la **app** (`Xpense/`) y el **widget** (`XpenseWidget/`), que
comparten la carpeta `Shared/` y un **App Group**.

```
Xpense/
  Models/Modelos.swift          @Model SwiftData (ver "Regla CloudKit" abajo)
  Core/Persistencia.swift       ModelContainer en App Group + CloudKit; seed de categorías
  Core/AutoCategorizador.swift  comercio → categoría: reglas base + APRENDIZAJE + alias
  Core/MotorPresupuesto.swift   rangos semana(lunes)/mes, niveles de alerta, gasto
  Core/Avisos.swift             notificaciones locales (1 por nivel por periodo)
  Core/SnapshotWidget.swift     escribe el JSON (Snapshot) que dibuja el widget
  Intents/RegistrarGastoIntent.swift  App Intent de Atajos (captura Apple Pay en 2º plano)
  Views/                        SwiftUI (Root, Home, Agregar, Categorías, Tarjetas, Ajustes…)
Shared/Shared.swift             enum Paleta, formato clp(), modelos Snapshot/ItemSnapshot
Shared/Localizable.xcstrings    traducciones (es fuente, en target)
XpenseWidget/XpenseWidget.swift widget chico y mediano (lee el Snapshot del App Group)
```

El entry point ([`XpenseApp.swift`](Xpense/XpenseApp.swift)) inyecta `Persistencia.contenedor`
vía `.modelContainer`. Las vistas obtienen el `ModelContext` del environment y llaman a
`MotorPresupuesto`. Tras mutar, dispara avisos (`Avisos`) y reescribe el snapshot
(`SnapshotWidget`) — no rompas ese encadenamiento.

## Modelos `@Model` + CloudKit (cuidado al editar)

`Modelos.swift`: `Categoria`, `Transaccion`, `Tarjeta`, `ReglaAprendida`. **Regla de oro
de CloudKit** (está comentada en el archivo): todo atributo debe tener **valor por defecto u
ser opcional**, las relaciones deben ser **opcionales**, y **no se permite `.unique`**.
Si agregas una propiedad sin default ni opcional, el contenedor CloudKit deja de inicializar.

`Persistencia.crearContenedor()` degrada con calma: App Group + CloudKit → solo App Group →
local. No conviertas eso en un `try!` — la app debe abrir aunque iCloud falle.

CloudKit puede **duplicar** el sembrado de categorías (incluso en distinto idioma);
`limpiarDuplicados` los une por `claveBase`/clave canónica. Por eso las categorías base
guardan `claveBase` (clave en español) además del `nombre` mostrado (idioma del dispositivo).

## Diferencias con la versión RN (esta tiene MÁS)

Esta versión va por delante. Funciones que existen aquí y **no** en `react-native/`:
- **Tarjetas** (`Tarjeta`): asociar gastos a tarjeta, con límite mensual y aviso propios.
- **Categorización con aprendizaje** (`ReglaAprendida`): aprende de correcciones manuales y
  alias de comercio, con matching por tokens/prefijo. La RN solo tiene reglas base estáticas.
- **Sync iCloud real** (CloudKit) y limpieza de duplicados.
- **App Intent** en segundo plano (no abre la app). La RN usa URL scheme.
- **Grupos de gastos** (`Grupo`, `Persona`): pozo común mensual, tarjetas con dueño
  (`Tarjeta.dueno`) y aporte al pozo por tarjeta (`aportaAlPozoPorDefecto`) con override
  por gasto (`Transaccion.aporteAlPozo`). Cálculo en `MotorPresupuesto.pozo`. **Local primero**:
  la sincronización entre cuentas iCloud distintas (CKShare) es fase pendiente.

Las **reglas base** de `AutoCategorizador.reglas` sí deben mantenerse en paridad con
`react-native/src/lib/categorizador.ts`.

## Captura de Apple Pay

`RegistrarGastoIntent` es un App Intent expuesto a la automatización de Atajos (gatillo
**"Wallet"**). Corre en segundo plano: registra el gasto, lo categoriza, evalúa avisos y
actualiza el widget sin abrir la app.

## Convenciones

Código y comentarios en **español** (`MotorPresupuesto`, `sugerir`, `Avisos`). Colores
siempre desde `Paleta` (con variante día/noche), nunca hex sueltos en las vistas. Dinero con
`clp(_:)`. Íconos = **SF Symbols**.
