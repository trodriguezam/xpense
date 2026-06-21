# xpense

App de seguimiento de gastos con Apple Pay, **pensada para Chile (CLP)**. Tono "mañana en
el sur": mirar tus gastos sin apuro ni culpa (nada de rojo de pánico). Idioma base **español
de Chile**.

## Monorepo: dos implementaciones de la MISMA app

Este repo contiene dos apps independientes que deben comportarse igual de cara al usuario:

| | [`ios-native/`](ios-native/CLAUDE.md) | [`react-native/`](react-native/CLAUDE.md) |
|---|---|---|
| Stack | Swift + SwiftUI + SwiftData | Expo (React Native) + TypeScript + SQLite |
| Se compila en | **Mac** (Xcode) | **Windows** (la nube de EAS Build compila iOS) |
| Captura Apple Pay | Atajos → **App Intent** (2º plano, no abre app) | Atajos → **URL scheme** `xpense://agregar` |
| Datos | Local + **sync iCloud** (SwiftData/CloudKit) | Local SQLite (sin sync multi-dispositivo) |
| Categorización | Reglas base + **aprendizaje** + alias | Solo reglas base |

**Antes de tocar código, identifica en cuál de las dos estás.** Cada subcarpeta tiene su
propio `CLAUDE.md` con detalles de stack, build y arquitectura. Lee el del subproyecto.

## Reglas de negocio (deben ser idénticas en ambas versiones)

Si cambias una de estas reglas, cámbiala en **las dos** implementaciones o la paridad se rompe:

- **Moneda**: CLP, enteros sin decimales. Formato `es_CL` (`$1.234`). Nunca floats para dinero.
- **Semana chilena**: empieza el **lunes**. Mes = mes calendario.
- **10 categorías base chilenas** (mismo orden, mismos nombres en español como clave canónica):
  Supermercado, Restaurantes y café, Transporte, Bencina, Cuentas y servicios, Salud,
  Entretenimiento, Compras, Hogar, Otros. El usuario puede crear categorías propias.
- **Límite por categoría**: semanal o mensual, opcional. Umbral de aviso configurable (0.5–0.95).
- **Niveles de alerta** (mismo cálculo en ambas):
  `0 sinLímite | 1 conCalma | 2 cerca (fracción ≥ umbral y gastado > 0) | 3 superado (fracción ≥ 1)`.
- **Avisos**: notificación local **una vez por nivel por periodo** (no spamear). Tono amable.
- **Categorización por comercio**: mismas reglas chilenas (Jumbo→Supermercado, Copec→Bencina,
  Uber→Transporte, etc.). Ver `categorizador.ts` / `AutoCategorizador.swift` — la lista de
  reglas base debe mantenerse en paridad.
- **Origen** de una transacción: `"manual"` | `"applepay"`.

## Paleta "mañana en el sur" (bruma, arena, musgo, cobre)

Identidad visual compartida; cada color tiene variante día/noche. Fuente de verdad:
[`ios-native/Shared/Shared.swift`](ios-native/Shared/Shared.swift) (`enum Paleta`) y
[`react-native/src/theme.ts`](react-native/src/theme.ts). Convenciones:
`musgo` = primario, `cobre` = "cerca del límite", `teja` = "límite superado" (cálido, **no** rojo).

## Convención de nombres

El código de dominio está **en español** (`agregarTransaccion`, `MotorPresupuesto`,
`sugerirCategoria`, `Avisos`). Mantén ese idioma al escribir código nuevo — no mezcles
inglés en nombres de funciones/variables de negocio. Comentarios en español.

## Pipeline de mutación (mismo concepto en ambas)

Toda mutación de datos pasa por una capa que encadena: **BD → evaluar avisos → actualizar
widget → refrescar UI**. En RN es `src/lib/acciones.ts`; en Swift las vistas llaman a
`MotorPresupuesto` + `Avisos` + `SnapshotWidget`. No escribas a la BD saltándote ese flujo.

## Apple Pay (contexto importante)

Apple **no** expone los pagos de Apple Pay a apps de terceros en Chile (FinanceKit solo
Apple Card / EE.UU.). La única vía es la **automatización de Atajos** con el gatillo
**"Wallet"** (iOS 17+), que pasa comercio + monto a la app. La guía de configuración vive
dentro de cada app, en Ajustes (no en un README externo).

## Bundle IDs / App Groups

Las dos apps usan grupos distintos (no comparten datos entre sí):
- Nativa: `cl.trodriguezam.xpense` · App Group `group.cl.trodriguezam.xpense`
- RN: `cl.trodriguezam.xpense.rn` · App Group `group.cl.trodriguezam.xpense.rn`

El App Group debe calzar en **todos** los lugares donde aparece (entitlements, código que
escribe el snapshot del widget, config del target del widget). Team ID: `9T6BFX3WVY`.
