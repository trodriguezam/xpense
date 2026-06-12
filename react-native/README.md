# xpense — versión React Native (Expo)

Pensada para desarrollar **desde Windows**: Windows no puede compilar iOS localmente, así
que la compilación nativa la hace **EAS Build** (la nube de Expo) y tú iteras el JavaScript
en caliente contra tu iPhone.

Requisitos: Node 20+, cuenta [Expo](https://expo.dev) (gratis), cuenta Apple Developer
pagada, iPhone con iOS 17+.

## 1. Instalar

```bash
cd react-native
npm install
npx expo install --fix     # alinea versiones nativas con el SDK
npm i -g eas-cli
eas login
```

En `app.config.ts` cambia `cl.tuequipo` por tu dominio invertido (bundle ID y App Group;
el App Group también está en `src/theme.ts` y `targets/widget/expo-target.config.js` —
deben calzar).

## 2. Primera compilación (development build)

El widget y las notificaciones son código nativo ⇒ **no funcionan en Expo Go**. Se usa un
*development build* propio:

```bash
eas device:create        # registra tu iPhone (abre un link en el teléfono)
eas build --profile development --platform ios
```

EAS te pedirá iniciar sesión con tu Apple ID para crear certificados y perfiles
automáticamente. Al terminar (~15 min), escanea el QR del build desde el iPhone e instala.

## 3. Desarrollo diario desde Windows

```bash
npm start        # expo start --dev-client --tunnel
```

Abre la app instalada en el iPhone y conéctate al servidor (el túnel evita problemas de
red/firewall en Windows). Todo el código TS/TSX recarga al instante. **Solo necesitas
recompilar en EAS** si cambias algo nativo (el widget, plugins, app.config.ts).

## 4. Activar la captura de Apple Pay

Esta versión usa el **URL scheme** `xpense://` (la guía también está en la app, en Ajustes):

1. **Atajos** → **Automatización** → **+** → gatillo **Wallet** → tus tarjetas →
   **Ejecutar inmediatamente**.
2. Acción **Abrir URL** con:
   `xpense://agregar?monto=[Cantidad]&comercio=[Comerciante]`
   (inserta las variables del gatillo donde van los corchetes).

⚠️ Diferencia honesta con la versión nativa: abrir una URL **trae la app al frente** un
instante al pagar. El App Intent nativo de Swift corre en segundo plano sin interrumpir.
Es el costo de capturar Apple Pay sin escribir un módulo nativo propio.

## 5. Widget

`targets/widget/` contiene el widget en Swift; `@bacons/apple-targets` lo agrega como
target de Xcode durante el build de EAS. La app le pasa los datos por el App Group
(`src/lib/widget.ts`). Aparece al mantener presionada la pantalla de inicio → **+** → xpense.

## 6. Datos

SQLite local (`expo-sqlite`). Se incluye en el respaldo iCloud del equipo, pero **no hay
sincronización multi-dispositivo en vivo** — eso solo lo tiene la versión Swift (CloudKit).

## Estructura

```txt
app/                       rutas (expo-router): tabs, modal de gasto, detalle de categoría
src/lib/db.ts              esquema SQLite + seed de categorías chilenas
src/lib/presupuesto.ts     rangos semana (lunes) / mes, niveles de alerta
src/lib/categorizador.ts   comercio → categoría
src/lib/acciones.ts        mutaciones: BD → avisos → widget → refresco UI
src/lib/avisos.ts          notificaciones locales (1 por nivel por periodo)
src/lib/widget.ts          snapshot al App Group + reload del widget
targets/widget/            widget WidgetKit en Swift
```
