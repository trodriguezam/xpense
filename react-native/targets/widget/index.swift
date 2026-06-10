// Widget de xpense (versión React Native).
// Lee el JSON "widget_snapshot" que la app escribe en el App Group.
import WidgetKit
import SwiftUI

let APP_GROUP = "group.cl.tuequipo.xpense.rn"

struct Item: Codable, Identifiable {
    var id: String { nombre }
    let nombre: String
    let colorHex: String
    let gastado: Int
    let limite: Int?
    let fraccion: Double
}

struct Snapshot: Codable {
    let actualizadoEl: String
    let totalMes: Int
    let mensaje: String
    let items: [Item]

    static func leer() -> Snapshot? {
        guard let json = UserDefaults(suiteName: APP_GROUP)?.string(forKey: "widget_snapshot"),
              let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255)
    }
}

let bruma = Color(hex: "#F6F4EE"), arena = Color(hex: "#E7E0D2")
let musgo = Color(hex: "#5E7561"), salvia = Color(hex: "#A9BFA8")
let corteza = Color(hex: "#2F3A2E"), piedra = Color(hex: "#7C8577")
let cobre = Color(hex: "#B5704F"), teja = Color(hex: "#9C4F35")

func clp(_ monto: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = Locale(identifier: "es_CL")
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: monto)) ?? "$\(monto)"
}

struct Entrada: TimelineEntry {
    let date: Date
    let snapshot: Snapshot?
}

struct Proveedor: TimelineProvider {
    func placeholder(in context: Context) -> Entrada { Entrada(date: .now, snapshot: ejemplo) }
    func getSnapshot(in context: Context, completion: @escaping (Entrada) -> Void) {
        completion(Entrada(date: .now, snapshot: Snapshot.leer() ?? ejemplo))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entrada>) -> Void) {
        let proxima = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [Entrada(date: .now, snapshot: Snapshot.leer())],
                            policy: .after(proxima)))
    }
    private var ejemplo: Snapshot {
        Snapshot(actualizadoEl: "", totalMes: 412_500, mensaje: "Vas con calma este mes.",
                 items: [
                    Item(nombre: "Supermercado", colorHex: "#5E7561",
                         gastado: 180_000, limite: 250_000, fraccion: 0.72),
                    Item(nombre: "Restaurantes y café", colorHex: "#8A6E4B",
                         gastado: 84_000, limite: 100_000, fraccion: 0.84),
                    Item(nombre: "Transporte", colorHex: "#6E8B8F",
                         gastado: 32_000, limite: 60_000, fraccion: 0.53),
                 ])
    }
}

struct VistaWidget: View {
    @Environment(\.widgetFamily) var familia
    let entrada: Entrada

    var body: some View {
        Group {
            if let s = entrada.snapshot {
                if familia == .systemSmall { chico(s) } else { mediano(s) }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "leaf").foregroundStyle(salvia)
                    Text("Abre xpense para empezar")
                        .font(.caption2).multilineTextAlignment(.center).foregroundStyle(piedra)
                }
            }
        }
        .containerBackground(bruma, for: .widget)
    }

    func color(_ it: Item) -> Color {
        guard it.limite != nil else { return Color(hex: it.colorHex) }
        if it.fraccion >= 1 { return teja }
        if it.fraccion >= 0.8 { return cobre }
        return Color(hex: it.colorHex)
    }

    func barra(_ it: Item, alto: CGFloat = 6) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(arena)
                Capsule().fill(color(it))
                    .frame(width: max(6, geo.size.width * min(it.limite != nil ? it.fraccion : 1, 1)))
            }
        }
        .frame(height: alto)
    }

    func chico(_ s: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("xpense", systemImage: "leaf.fill")
                .font(.caption2.weight(.semibold)).foregroundStyle(musgo)
            Text(clp(s.totalMes))
                .font(.system(.title3, design: .serif).weight(.medium))
                .minimumScaleFactor(0.6).foregroundStyle(corteza)
            Text("este mes").font(.caption2).foregroundStyle(piedra)
            Spacer(minLength: 0)
            ForEach(s.items.prefix(2)) { it in
                VStack(alignment: .leading, spacing: 2) {
                    Text(it.nombre).font(.system(size: 9, weight: .medium))
                        .lineLimit(1).foregroundStyle(corteza)
                    barra(it)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func mediano(_ s: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("xpense", systemImage: "leaf.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(musgo)
                Spacer()
                Text("\(clp(s.totalMes)) este mes").font(.caption).foregroundStyle(piedra)
            }
            ForEach(s.items.prefix(4)) { it in
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(it.nombre).font(.caption2.weight(.medium))
                            .lineLimit(1).foregroundStyle(corteza)
                        Spacer()
                        Text(it.limite != nil ? "\(clp(it.gastado)) / \(clp(it.limite!))" : clp(it.gastado))
                            .font(.system(size: 9)).foregroundStyle(piedra)
                    }
                    barra(it)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

@main
struct XpenseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "XpenseWidget", provider: Proveedor()) { entrada in
            VistaWidget(entrada: entrada)
        }
        .configurationDisplayName("Consumo por categoría")
        .description("Tus límites y lo que llevas gastado, de un vistazo.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
