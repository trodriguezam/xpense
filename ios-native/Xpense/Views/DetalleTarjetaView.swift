import SwiftUI
import SwiftData

struct DetalleTarjetaView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Bindable var tarjeta: Tarjeta

    @State private var tieneLimite = false
    @State private var limiteTexto = ""
    @State private var confirmarBorrado = false
    @State private var borrada = false

    private var limite: Int { Int(limiteTexto.filter(\.isNumber)) ?? 0 }
    private var estado: EstadoTarjeta { MotorPresupuesto.estadoTarjeta(tarjeta, contexto: contexto) }
    private var txsMes: [Transaccion] {
        MotorPresupuesto.transacciones(en: MotorPresupuesto.rango(.mensual), contexto: contexto)
            .filter { $0.tarjeta?.persistentModelID == tarjeta.persistentModelID }
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Paleta.musgo))
                        Text(clp(estado.gastado))
                            .font(.system(.title2, design: .serif).weight(.medium))
                        Spacer()
                        if tieneLimite, limite > 0 {
                            Text("de \(clp(limite))").font(.caption).foregroundStyle(Paleta.piedra)
                        }
                    }
                    if tieneLimite, limite > 0 {
                        TalloProgreso(fraccion: estado.fraccion, nivel: estado.nivel)
                    }
                }
                .listRowBackground(Paleta.superficie)
            } header: {
                Text("Gastado este mes")
            }

            Section("Límite mensual") {
                Toggle("Definir un límite", isOn: $tieneLimite)
                if tieneLimite {
                    HStack {
                        Text("$").foregroundStyle(Paleta.piedra)
                        TextField("Monto", text: $limiteTexto).keyboardType(.numberPad)
                    }
                    VStack(alignment: .leading) {
                        let pct = "\(Int(tarjeta.umbralAviso * 100)) %"
                        Text("Avisar al llegar al \(pct)")
                            .font(.subheadline)
                        Slider(value: $tarjeta.umbralAviso, in: 0...1, step: 0.05)
                    }
                }
            }

            Section("Movimientos del mes") {
                if txsMes.isEmpty {
                    Text("Nada por aquí todavía.").foregroundStyle(Paleta.piedra)
                } else {
                    ForEach(txsMes) { FilaTransaccion(tx: $0) }
                }
            }

            Section {
                Button("Eliminar tarjeta", role: .destructive) { confirmarBorrado = true }
                    .frame(maxWidth: .infinity)
            } footer: {
                Text("Los gastos de la tarjeta no se borran; solo dejan de tener tarjeta.")
            }
        }
        .confirmationDialog("¿Eliminar esta tarjeta?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                borrada = true
                contexto.delete(tarjeta)
                SnapshotWidget.trasCambio(contexto: contexto)
                cerrar()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Paleta.bruma)
        .navigationTitle(tarjeta.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tieneLimite = (tarjeta.limiteMonto ?? 0) > 0
            limiteTexto = tarjeta.limiteMonto.map(String.init) ?? ""
        }
        .onDisappear { guardar() }
    }

    private func guardar() {
        guard !borrada else { return }
        tarjeta.limiteMonto = (tieneLimite && limite > 0) ? limite : nil
        SnapshotWidget.trasCambio(contexto: contexto)
    }
}
