import SwiftUI
import SwiftData

struct CategoriasView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]
    @State private var mostrarNueva = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(categorias) { cat in
                    NavigationLink(value: cat) {
                        let e = MotorPresupuesto.estado(cat, contexto: contexto)
                        HStack(spacing: 12) {
                            IconoCategoria(icono: cat.icono, colorHex: cat.colorHex)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(cat.nombre).foregroundStyle(Paleta.corteza)
                                if let lim = cat.limiteMonto, lim > 0 {
                                    Text("\(clp(e.gastado)) de \(clp(lim)) · \(cat.periodoEnum.etiqueta.lowercased())")
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
                    for i in idx where !categorias[i].esPredeterminada {
                        contexto.delete(categorias[i])
                    }
                    SnapshotWidget.trasCambio(contexto: contexto)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .navigationTitle("Categorías")
            .navigationDestination(for: Categoria.self) { DetalleCategoriaView(categoria: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarNueva = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $mostrarNueva) { NuevaCategoriaView() }
        }
    }
}

struct NuevaCategoriaView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @State private var nombre = ""
    @State private var icono = "leaf.fill"
    @State private var colorHex = "#5E7561"

    private let iconos = ["leaf.fill","cart.fill","cup.and.saucer.fill","bus.fill","fuelpump.fill",
                          "bolt.fill","cross.case.fill","popcorn.fill","bag.fill","house.fill",
                          "pawprint.fill","book.fill","gift.fill","airplane","figure.run","tshirt.fill"]
    private let colores = ["#5E7561","#8A6E4B","#6E8B8F","#B5704F","#A9BFA8",
                           "#9C7B9E","#C2A36B","#8FA08A","#7C8577","#2F3A2E"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") { TextField("Ej: Mascotas", text: $nombre) }
                Section("Ícono") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconos, id: \.self) { i in
                            Image(systemName: i)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(i == icono ? Color(hex: colorHex) : Paleta.arena))
                                .foregroundStyle(i == icono ? .white : Paleta.corteza)
                                .onTapGesture { icono = i }
                        }
                    }
                }
                Section("Color") {
                    HStack {
                        ForEach(colores, id: \.self) { c in
                            Circle().fill(Color(hex: c))
                                .frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(.white, lineWidth: c == colorHex ? 3 : 0))
                                .onTapGesture { colorHex = c }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .navigationTitle("Nueva categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { cerrar() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        contexto.insert(Categoria(nombre: nombre, icono: icono, colorHex: colorHex))
                        try? contexto.save()
                        cerrar()
                    }.disabled(nombre.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
