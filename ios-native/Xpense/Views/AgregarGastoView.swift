import SwiftUI
import SwiftData

struct AgregarGastoView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]

    @State private var montoTexto = ""
    @State private var comercio = ""
    @State private var nota = ""
    @State private var fecha = Date.now
    @State private var categoria: Categoria?
    @State private var sugeridaAuto = false

    private var monto: Int { Int(montoTexto.filter(\.isNumber)) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("$").font(.system(.title2, design: .serif)).foregroundStyle(Paleta.piedra)
                        TextField("0", text: $montoTexto)
                            .keyboardType(.numberPad)
                            .font(.system(.title2, design: .serif))
                    }
                } header: { Text("Monto (CLP)") }

                Section {
                    TextField("Ej: Jumbo, Copec, Uber…", text: $comercio)
                        .onChange(of: comercio) {
                            if let s = AutoCategorizador.sugerir(comercio: comercio, entre: categorias) {
                                categoria = s
                                sugeridaAuto = true
                            } else if sugeridaAuto {
                                categoria = nil
                                sugeridaAuto = false
                            }
                        }
                } header: { Text("Comercio") }

                Section {
                    Picker("Categoría", selection: $categoria) {
                        Text("Sin categoría").tag(Categoria?.none)
                        ForEach(categorias) { c in
                            Label(c.nombre, systemImage: c.icono).tag(Optional(c))
                        }
                    }
                    if sugeridaAuto {
                        Label("Sugerida según el comercio", systemImage: "sparkles")
                            .font(.caption).foregroundStyle(Paleta.musgo)
                    }
                    DatePicker("Fecha", selection: $fecha, displayedComponents: .date)
                    TextField("Nota (opcional)", text: $nota)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .navigationTitle("Nuevo gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }.disabled(monto <= 0)
                }
            }
        }
    }

    private func guardar() {
        let tx = Transaccion(monto: monto, comercio: comercio, fecha: fecha,
                             nota: nota, origen: "manual", categoria: categoria)
        contexto.insert(tx)
        SnapshotWidget.trasCambio(contexto: contexto)
        cerrar()
    }
}
