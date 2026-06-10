import SwiftUI
import SwiftData

struct TransaccionesView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Transaccion.fecha, order: .reverse) private var transacciones: [Transaccion]
    @State private var mostrarAgregar = false

    private var porDia: [(Date, [Transaccion])] {
        let grupos = Dictionary(grouping: transacciones) {
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
                } else {
                    List {
                        ForEach(porDia, id: \.0) { dia, txs in
                            Section {
                                ForEach(txs) { tx in FilaTransaccion(tx: tx) }
                                    .onDelete { idx in
                                        for i in idx { contexto.delete(txs[i]) }
                                        SnapshotWidget.trasCambio(contexto: contexto)
                                    }
                            } header: {
                                Text(dia.formatted(.dateTime.weekday(.wide).day().month(.wide)
                                        .locale(Locale(identifier: "es_CL"))))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Paleta.bruma)
            .navigationTitle("Movimientos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarAgregar = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $mostrarAgregar) { AgregarGastoView() }
        }
    }
}
