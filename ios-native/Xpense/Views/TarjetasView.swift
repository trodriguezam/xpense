import SwiftUI
import SwiftData

struct TarjetasView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Tarjeta.nombre) private var tarjetas: [Tarjeta]
    @State private var mostrarNueva = false
    @State private var nombreNueva = ""

    var body: some View {
        NavigationStack {
            Group {
                if tarjetas.isEmpty {
                    ContentUnavailableView {
                        Label("Sin tarjetas aún", systemImage: "creditcard")
                    } description: {
                        Text("Aparecen solas al pagar con Apple Pay. También puedes agregarlas a mano con el botón +. Luego puedes ponerles un límite mensual.")
                    } actions: {
                        Button("Agregar tarjeta") { mostrarNueva = true }
                            .buttonStyle(.borderedProminent)
                    }
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
                            .swipeEliminar {
                                contexto.delete(t)
                                SnapshotWidget.trasCambio(contexto: contexto)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Paleta.bruma)
            .navigationTitle("Tarjetas")
            .navigationDestination(for: Tarjeta.self) { DetalleTarjetaView(tarjeta: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarNueva = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("Nueva tarjeta", isPresented: $mostrarNueva) {
                TextField("Nombre (ej: Visa de mamá)", text: $nombreNueva)
                Button("Agregar") { crearTarjeta() }
                    .disabled(nombreNueva.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancelar", role: .cancel) { nombreNueva = "" }
            } message: {
                Text("Ponle un nombre para reconocerla. Las de Apple Pay se crean solas.")
            }
        }
    }

    private func crearTarjeta() {
        _ = Tarjeta.obtenerOCrear(nombre: nombreNueva, contexto: contexto)
        nombreNueva = ""
        SnapshotWidget.trasCambio(contexto: contexto)
    }
}
