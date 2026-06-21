# xpense — versión React Native (Expo)

Lee primero el [`CLAUDE.md` raíz](../CLAUDE.md) para las reglas de negocio compartidas y la
paleta. Este archivo cubre solo lo específico de la app Expo.

Pensada para desarrollar **desde Windows**: Windows no compila iOS localmente, así que el
build nativo lo hace **EAS Build** (la nube de Expo) y se itera el JS/TS en caliente contra
un iPhone físico. Requiere Node 20+, SDK Expo ~54, iOS 17+.

## Comandos

```bash
cd react-native
npm install
npx expo install --fix        # alinea versiones nativas con el SDK
npm start                     # = expo start --dev-client --tunnel (desarrollo diario)
npm run build:dev             # eas build --profile development --platform ios
npm run build:preview         # eas build --profile preview --platform ios
npm run doctor                # npx expo-doctor
```

**No funciona en Expo Go**: el widget y las notificaciones son código nativo → se necesita un
*development build* propio (`build:dev`, ~15 min en EAS). Solo hay que **recompilar en EAS**
cuando cambias algo nativo: el widget en `targets/`, plugins o `app.config.ts`. Todo el
código TS/TSX recarga en caliente sin recompilar.

## Arquitectura

```
app/                       rutas expo-router (typedRoutes activado)
  _layout.tsx              migra BD, pide permiso de avisos, maneja deep link xpense://
  (tabs)/                  inicio, movimientos, categorias, ajustes
  agregar.tsx              modal de nuevo gasto
  categoria/[id].tsx       detalle de categoría
src/lib/
  db.ts                    esquema SQLite (expo-sqlite) + seed de 10 categorías chilenas
  presupuesto.ts           rangos semana(lunes)/mes, niveles de alerta, gasto por categoría
  categorizador.ts         comercio → categoría (reglas base estáticas)
  acciones.ts              TODA mutación: BD → avisos → widget → emitir() refresco UI
  avisos.ts                notificaciones locales (1 por nivel por periodo)
  widget.ts                escribe snapshot al App Group + recarga el widget
  store.ts                 mini bus de eventos (useVersionDatos / emitir)
  clp.ts                   formato moneda es_CL
src/theme.ts               paleta "mañana en el sur" (C), fuentes (F), APP_GROUP
src/components/ui.tsx      componentes compartidos
targets/widget/            widget WidgetKit en Swift, vía @bacons/apple-targets
```

## Reglas clave de este código

- **Toda mutación pasa por `src/lib/acciones.ts`.** Cada función ahí ejecuta `trasCambio()`:
  evalúa avisos de todas las categorías, actualiza el widget y llama `emitir()`. No escribas a
  SQLite directo desde una pantalla — pierdes avisos, widget y refresco de UI.
- **Refresco de UI**: las pantallas se suscriben con `useVersionDatos()` (`store.ts`); `emitir()`
  las re-renderiza. No hay Redux/Zustand; es un bus de eventos mínimo a propósito.
- **SQLite síncrono** (`db.runSync`/`getAllSync`). `migrar()` se llama una vez en `_layout.tsx`.
- **Íconos = Ionicons** (`@expo/vector-icons`). Ojo: la versión nativa usa SF Symbols, así que
  los nombres de íconos **no** son los mismos entre apps (ver `BASE` en `db.ts`).

## Captura de Apple Pay (URL scheme)

Esta versión usa el deep link `xpense://agregar?monto=..&comercio=..`, parseado en
[`app/_layout.tsx`](app/_layout.tsx) → `agregarDesdeApplePay`. **Costo honesto**: abrir la
URL trae la app al frente un instante al pagar (la nativa lo hace en 2º plano con un App
Intent). Es el precio de no escribir un módulo nativo propio.

## Diferencias con la versión nativa (esta tiene MENOS)

La nativa va por delante. Aquí **no** existen: tarjetas, categorización con aprendizaje (solo
reglas base estáticas), ni sync iCloud multi-dispositivo (SQLite local + respaldo iCloud del
equipo). Si portas alguna de esas features desde Swift, mantén nombres y reglas en español y
respeta el pipeline de `acciones.ts`.

## Config nativa

`app.config.ts` define bundle ID (`cl.trodriguezam.xpense.rn`), `scheme: "xpense"`, App Group
y plugins. El **App Group debe calzar** en `app.config.ts`, `src/theme.ts` (`APP_GROUP`) y
`targets/widget/expo-target.config.js`. `projectId` de EAS también vive en `app.config.ts`.
Código y comentarios en **español**.
