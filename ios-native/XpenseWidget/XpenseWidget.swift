// XpenseWidget.swift — consumo por categoría, en la pantalla de inicio.
import WidgetKit
import SwiftUI

struct Entrada: TimelineEntry {
    let date: Date
    let snapshot: Snapshot?
}

struct Proveedor: TimelineProvider {
    func placeholder(in context: Context) -> Entrada {
        Entrada(date: .now, snapshot: ejemplo)
    }
    func getSnapshot(in context: Context, completion: @escaping (Entrada) -> Void) {
        completion(Entrada(date: .now, snapshot: Snapshot.leer() ?? ejemplo))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entrada>) -> Void) {
        let entrada = Entrada(date: .now, snapshot: Snapshot.leer())
        let proxima = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entrada], policy: .after(proxima)))
    }
    private var ejemplo: Snapshot {
        Snapshot(actualizadoEl: .now, totalMes: 412_500, mensaje: "Vas con calma este mes.",
                 items: [
                    .init(nombre: "Supermercado", icono: "cart.fill", colorHex: "#5E7561",
                          gastado: 180_000, limite: 250_000, fraccion: 0.72),
                    .init(nombre: "Restaurantes y café", icono: "cup.and.saucer.fill", colorHex: "#8A6E4B",
                          gastado: 84_000, limite: 100_000, fraccion: 0.84),
                    .init(nombre: "Transporte", icono: "bus.fill", colorHex: "#6E8B8F",
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
                switch familia {
                case .systemSmall: chico(s)
                default: mediano(s)
                }
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "leaf").foregroundStyle(Paleta.salvia)
                    Text("Abre xpense para empezar")
                        .font(.caption2).multilineTextAlignment(.center)
                        .foregroundStyle(Paleta.piedra)
                }
            }
        }
        .containerBackground(Paleta.bruma, for: .widget)
    }

    private func chico(_ s: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("xpense", systemImage: "leaf.fill")
                .font(.caption2.weight(.semibold)).foregroundStyle(Paleta.musgo)
            Text(clp(s.totalMes))
                .font(.system(.title3, design: .serif).weight(.medium))
                .minimumScaleFactor(0.6)
                .foregroundStyle(Paleta.corteza)
            Text("este mes").font(.caption2).foregroundStyle(Paleta.piedra)
            Spacer(minLength: 0)
            ForEach(s.items.prefix(2)) { barraMini($0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mediano(_ s: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label("xpense", systemImage: "leaf.fill")
                    .font(.caption.weight(.semibold)).foregroundStyle(Paleta.musgo)
                Spacer()
                Text("\(clp(s.totalMes)) este mes")
                    .font(.caption).foregroundStyle(Paleta.piedra)
            }
            ForEach(s.items.prefix(4)) { barra($0) }
            Spacer(minLength: 0)
        }
    }

    private func color(_ it: ItemSnapshot) -> Color {
        guard it.limite != nil else { return Color(hex: it.colorHex) }
        if it.fraccion >= 1 { return Paleta.teja }
        if it.fraccion >= 0.8 { return Paleta.cobre }
        return Color(hex: it.colorHex)
    }

    private func barra(_ it: ItemSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(it.nombre).font(.caption2.weight(.medium)).foregroundStyle(Paleta.corteza)
                    .lineLimit(1)
                Spacer()
                Text(it.limite != nil ? "\(clp(it.gastado)) / \(clp(it.limite!))" : clp(it.gastado))
                    .font(.system(size: 9)).foregroundStyle(Paleta.piedra)
            }
            barraFondo(it)
        }
    }

    private func barraMini(_ it: ItemSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(it.nombre).font(.system(size: 9, weight: .medium))
                .lineLimit(1).foregroundStyle(Paleta.corteza)
            barraFondo(it)
        }
    }

    private func barraFondo(_ it: ItemSnapshot) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Paleta.arena)
                Capsule().fill(color(it))
                    .frame(width: max(6, geo.size.width * min(it.limite != nil ? it.fraccion : 1, 1)))
            }
        }
        .frame(height: 6)
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
