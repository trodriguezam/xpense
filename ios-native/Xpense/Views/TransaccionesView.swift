import SwiftUI
import SwiftData

struct TransaccionesView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Transaccion.fecha, order: .reverse) private var transacciones: [Transaccion]
    @State private var mostrarAgregar = false
    @State private var editarTx: Transaccion?
    @State private var busqueda = ""

    private var filtradas: [Transaccion] {
        let q = AutoCategorizador.normalizar(busqueda)
        guard !q.isEmpty else { return transacciones }
        return transacciones.filter {
            AutoCategorizador.normalizar($0.comercio).contains(q)
            || AutoCategorizador.normalizar($0.categoria?.nombre ?? "").contains(q)
        }
    }

    private var porDia: [(Date, [Transaccion])] {
        let grupos = Dictionary(grouping: filtradas) {
            Calendar.current.startOfDay(for: $0.fecha)
        }
        return grupos.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if transacciones.isEmpty {
                    ContentUnavailableView("Sin movimientos aún",
                        systemImage: "leaf",
                        description: Text("Agrega tu primer gasto con el botón +, o configura la automatización de Apple Pay en Ajustes."))
                } else if filtradas.isEmpty {
                    ContentUnavailableView.search(text: busqueda)
                } else {
                    List {
                        ForEach(porDia, id: \.0) { dia, txs in
                            Section {
                                ForEach(txs) { tx in
                                    Button { editarTx = tx } label: {
                                        FilaTransaccion(tx: tx)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { idx in
                                    for i in idx { contexto.delete(txs[i]) }
                                    SnapshotWidget.trasCambio(contexto: contexto)
                                }
                            } header: {
                                Text(dia.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .background(Paleta.bruma)
            .navigationTitle("Gastos")
            .searchable(text: $busqueda, prompt: "Comercio o categoría")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarAgregar = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $mostrarAgregar) { AgregarGastoView() }
            .sheet(item: $editarTx) { AgregarGastoView(transaccion: $0) }
        }
    }
}
