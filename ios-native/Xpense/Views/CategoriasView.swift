import SwiftUI
import SwiftData

struct CategoriasView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]
    @State private var mostrarNueva = false

    /// (categoría, estado) ordenadas; se parten en dos grupos: con y sin gastos
    /// este periodo. Las con gastos van arriba.
    private var porGrupo: (con: [(Categoria, EstadoCategoria)], sin: [(Categoria, EstadoCategoria)]) {
        let estados = categorias.map { ($0, MotorPresupuesto.estado($0, contexto: contexto)) }
        return (estados.filter { $0.1.gastado > 0 }, estados.filter { $0.1.gastado == 0 })
    }

    var body: some View {
        NavigationStack {
            List {
                let grupos = porGrupo
                if !grupos.con.isEmpty {
                    Section("Con gastos") {
                        ForEach(grupos.con, id: \.0.persistentModelID) { fila($0.0, $0.1) }
                    }
                }
                if !grupos.sin.isEmpty {
                    Section(grupos.con.isEmpty ? "" : "Sin gastos aún") {
                        ForEach(grupos.sin, id: \.0.persistentModelID) { fila($0.0, $0.1) }
                    }
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

    @ViewBuilder
    private func fila(_ cat: Categoria, _ e: EstadoCategoria) -> some View {
        NavigationLink(value: cat) {
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
        .swipeEliminar {
            contexto.delete(cat)
            SnapshotWidget.trasCambio(contexto: contexto)
        }
    }
}

struct NuevaCategoriaView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @State private var nombre = ""
    @State private var icono = "leaf.fill"
    @State private var colorHex = "#5E7561"

    var body: some View {
        NavigationStack {
            Form {
                Section("Nombre") { TextField("Ej: Mascotas", text: $nombre) }
                Section {
                    HStack(spacing: 12) {
                        IconoCategoria(icono: icono, colorHex: colorHex)
                        Text(nombre.isEmpty ? String(localized: "Tu categoría") : nombre)
                            .foregroundStyle(Paleta.corteza)
                    }
                    SelectorIconoColor(icono: $icono, colorHex: $colorHex)
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
