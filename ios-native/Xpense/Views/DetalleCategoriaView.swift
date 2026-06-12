import SwiftUI
import SwiftData

struct DetalleCategoriaView: View {
    @Environment(\.modelContext) private var contexto
    @Bindable var categoria: Categoria

    @State private var tieneLimite = false
    @State private var limiteTexto = ""

    private var limite: Int { Int(limiteTexto.filter(\.isNumber)) ?? 0 }
    private var estado: EstadoCategoria { MotorPresupuesto.estado(categoria, contexto: contexto) }
    private var txsPeriodo: [Transaccion] {
        MotorPresupuesto.transacciones(en: MotorPresupuesto.rango(categoria.periodoEnum), contexto: contexto)
            .filter { $0.categoria?.persistentModelID == categoria.persistentModelID }
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        IconoCategoria(icono: categoria.icono, colorHex: categoria.colorHex)
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
                categoria.periodoEnum == .semanal
                    ? Text("Gastado esta semana") : Text("Gastado este mes")
            }

            Section("Límite") {
                Toggle("Definir un límite", isOn: $tieneLimite)
                if tieneLimite {
                    HStack {
                        Text("$").foregroundStyle(Paleta.piedra)
                        TextField("Monto", text: $limiteTexto).keyboardType(.numberPad)
                    }
                    Picker("Periodo", selection: Binding(
                        get: { categoria.periodoEnum },
                        set: { categoria.periodo = $0.rawValue })) {
                        ForEach(Periodo.allCases) { Text($0.etiqueta).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    VStack(alignment: .leading) {
                        let pct = "\(Int(categoria.umbralAviso * 100)) %"
                        Text("Avisar al llegar al \(pct)")
                            .font(.subheadline)
                        Slider(value: $categoria.umbralAviso, in: 0...1, step: 0.05)
                    }
                }
            }

            Section("Movimientos del periodo") {
                if txsPeriodo.isEmpty {
                    Text("Nada por aquí todavía.").foregroundStyle(Paleta.piedra)
                } else {
                    ForEach(txsPeriodo) { FilaTransaccion(tx: $0) }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Paleta.bruma)
        .navigationTitle(categoria.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            tieneLimite = (categoria.limiteMonto ?? 0) > 0
            limiteTexto = categoria.limiteMonto.map(String.init) ?? ""
        }
        .onDisappear { guardar() }
    }

    private func guardar() {
        categoria.limiteMonto = (tieneLimite && limite > 0) ? limite : nil
        SnapshotWidget.trasCambio(contexto: contexto)
    }
}
