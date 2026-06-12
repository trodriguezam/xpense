# xpense — versión nativa (Swift / SwiftUI)

Se compila en un **Mac** con Xcode 15 o superior y se prueba en un iPhone con **iOS 17+**.

## 1. Generar el proyecto

El repo no incluye `.xcodeproj`: se genera con [XcodeGen](https://github.com/yonaskolb/XcodeGen)
a partir de `project.yml` (más limpio para versionar).

```bash
brew install xcodegen
cd ios-native
xcodegen generate
open Xpense.xcodeproj
```

## 2. Configurar identidad (una vez)

En `project.yml` antes de generar, o en Xcode después:

1. `DEVELOPMENT_TEAM`: tu Team ID (Apple Developer pagado).
2. Reemplaza `cl.tuequipo` por tu dominio invertido en: bundle IDs, App Group
   (`group.cl.tuequipo.xpense`) y contenedor iCloud (`iCloud.cl.tuequipo.xpense`).
   Debe ser consistente en `project.yml` y en `Shared/Shared.swift` (`Compartido.appGroup`).
3. Verifica en *Signing & Capabilities* de ambos targets (app y widget) que aparezcan
   **App Groups** (mismo grupo en los dos) y, solo en la app, **iCloud → CloudKit**.

## 3. Correr en tu iPhone

Conecta el iPhone, selecciónalo como destino y ⌘R. La primera vez, acepta el perfil del
desarrollador en Ajustes → General → VPN y administración de dispositivos.

## 4. Activar la captura de Apple Pay

En el iPhone (requiere haber abierto xpense al menos una vez):

1. **Atajos** → **Automatización** → **+**.
2. Gatillo **Wallet** → elige tus tarjetas de Apple Pay → **Ejecutar inmediatamente**.
3. Acción: **Registrar gasto** (aparece bajo xpense).
4. En *Monto* inserta la variable **Cantidad** de la transacción; en *Comercio*, **Comerciante**.

Desde ahí, cada pago con Apple Pay queda registrado **en segundo plano** (el App Intent no
abre la app), se categoriza solo, actualiza el widget y dispara el aviso si corresponde.

## 5. Widget e iCloud

- Widget: mantén presionada la pantalla de inicio → **+** → busca *xpense*.
- La primera sincronización CloudKit puede tardar unos minutos; el esquema se crea solo
  en el entorno *Development* al correr desde Xcode.

## Estructura

```
Xpense/
  Models/Modelos.swift        SwiftData (Categoria, Transaccion) compatible CloudKit
  Core/Persistencia.swift     contenedor en App Group + seed de categorías chilenas
  Core/AutoCategorizador.swift comercio → categoría (Jumbo, Copec, Uber…)
  Core/MotorPresupuesto.swift  rangos semana (lunes) / mes, niveles de alerta
  Core/Avisos.swift            notificaciones locales, 1 por nivel por periodo
  Core/SnapshotWidget.swift    escribe el JSON que dibuja el widget
  Intents/RegistrarGastoIntent.swift  acción de Atajos (captura Apple Pay)
  Views/…                      SwiftUI
Shared/Shared.swift            paleta, formato CLP, modelo del snapshot (app + widget)
XpenseWidget/XpenseWidget.swift widget chico y mediano
```
