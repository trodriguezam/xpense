# xpense 🌿

Seguimiento de gastos con Apple Pay, pensado para Chile. Mirar tus gastos sin apuro ni culpa.

Dos implementaciones de la misma app, con la misma identidad visual ("mañana en el sur":
bruma, arena, musgo, cobre) y las mismas reglas de negocio:

| | `ios-native/` | `react-native/` |
|---|---|---|
| Stack | Swift + SwiftUI + SwiftData | Expo (React Native) + TypeScript + SQLite |
| Se compila en | **Mac** (Xcode) | **Windows** (la nube de EAS Build compila el iOS) |
| Captura Apple Pay | Automatización de Atajos → **App Intent** (segundo plano, no abre la app) | Automatización de Atajos → **URL scheme** `xpense://agregar` (abre la app un instante) |
| Datos | Local + **sync real iCloud** (SwiftData/CloudKit) | Local (SQLite) + respaldo iCloud del equipo |
| Widget | WidgetKit (Swift) | WidgetKit (Swift) vía `@bacons/apple-targets` |
| Notificaciones de límite | UNUserNotificationCenter | expo-notifications |

## Cómo se capturan los pagos de Apple Pay (importante)

Apple **no** expone los pagos de Apple Pay a apps de terceros en Chile: FinanceKit solo
funciona con Apple Card en EE.UU. La vía soportada es la automatización de **Atajos** con el
gatillo **"Wallet"** (iOS 17+): cada vez que pagas con Apple Pay, Atajos recibe el
comercio y el monto, y se los pasa a xpense. La app categoriza automáticamente según el
comercio (Jumbo → Supermercado, Copec → Bencina, etc.), revisa tus límites, actualiza el
widget y te avisa con calma si te acercas a una cuota.

La guía de configuración paso a paso está dentro de cada app, en **Ajustes**.

## Funcionalidades (ambas versiones)

- Registro manual y automático (Apple Pay vía Atajos) de gastos en CLP.
- 10 categorías base chilenas + categorías personalizadas (ícono y color).
- Límite por categoría: **semanal o mensual**, con umbral de aviso configurable (50–95 %).
- Notificación local al acercarte al límite y al superarlo — una vez por nivel por periodo,
  con tono amable (nada de rojo de pánico).
- Widget de pantalla de inicio (chico y mediano) con el consumo por categoría.
- Semana chilena: parte el lunes. Formato moneda `es-CL` sin decimales.

Cada carpeta tiene su README con instrucciones de compilación y prueba en iPhone.
