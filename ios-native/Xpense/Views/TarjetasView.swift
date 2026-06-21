import SwiftUI
import SwiftData

struct TarjetasView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Tarjeta.nombre) private var tarjetas: [Tarjeta]

    var body: some View {
        NavigationStack {
            Group {
                if tarjetas.isEmpty {
                    ContentUnavailableView("Sin tarjetas aún",
                        systemImage: "creditcard",
                        description: Text("Aparecen solas al registrar un gasto con tarjeta, o cuando configuras la captura de Apple Pay. Luego puedes ponerles un límite mensual."))
                } else {
                    List {
                        ForEach(tarjetas) { t in
                            NavigationLink(value: t) {
                                let e = MotorPresupuesto.estadoTarjeta(t, contexto: contexto)
                                HStack(spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)
                                        .frame(width: 34, height: 34)
                                        .background(Circle().fill(Paleta.musgo))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(t.nombre).foregroundStyle(Paleta.corteza)
                                        if let lim = t.limiteMonto, lim > 0 {
                                            Text("\(clp(e.gastado)) de \(clp(lim)) este mes")
                                                .font(.caption).foregroundStyle(Paleta.piedra)
                                        } else {
                                            Text("\(clp(e.gastado)) este mes · sin límite")
                                                .font(.caption).foregroundStyle(Paleta.piedra)
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete { idx in
                            for i in idx { contexto.delete(tarjetas[i]) }
                            SnapshotWidget.trasCambio(contexto: contexto)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Paleta.bruma)
            .navigationTitle("Tarjetas")
            .navigationDestination(for: Tarjeta.self) { DetalleTarjetaView(tarjeta: $0) }
        }
    }
}
