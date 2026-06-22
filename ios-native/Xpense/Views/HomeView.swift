import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Transaccion.fecha, order: .reverse) private var transacciones: [Transaccion]
    @Query private var categorias: [Categoria]
    @State private var mostrarAgregar = false
    @State private var mostrarAjustes = false
    @State private var editarTx: Transaccion?

    private var estados: [EstadoCategoria] {
        MotorPresupuesto.estados(contexto: contexto)
            .filter { $0.nivel != .sinLimite }
            .sorted { $0.fraccion > $1.fraccion }
    }
    private var totalMes: Int { MotorPresupuesto.totalMes(contexto: contexto) }
    private var saludo: String {
        let h = Calendar.current.component(.hour, from: .now)
        if h < 12 { return String(localized: "Buenos días") }
        return h < 20 ? String(localized: "Buenas tardes") : String(localized: "Buenas noches")
    }
    private var mesActual: String {
        Date.now.formatted(.dateTime.month(.wide))
    }

    var body: some View {
        NavigationStack {
            List {
                // Saludo: flota sobre la bruma, sin contenedor.
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(saludo)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(Paleta.piedra)
                        Text("Tu \(mesActual), en calma")
                            .font(.system(.largeTitle, design: .serif).weight(.medium))
                            .foregroundStyle(Paleta.corteza)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 2, trailing: 20))
                }

                // Gastado este mes: contenedor inset-grouped como el resto de la app.
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GASTADO ESTE MES")
                            .font(.caption2.weight(.semibold))
                            .kerning(1.2)
                            .foregroundStyle(Paleta.piedra)
                        Text(clp(totalMes))
                            .font(.system(size: 40, design: .serif).weight(.medium))
                            .foregroundStyle(Paleta.corteza)
                        Text(MotorPresupuesto.mensajeGeneral(estados))
                            .font(.subheadline)
                            .foregroundStyle(Paleta.musgo)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }

                Section {
                    if !estados.isEmpty {
                        ForEach(estados) { e in
                            FilaPresupuesto(estado: e)
                                .padding(.vertical, 4)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "leaf")
                                .font(.title)
                                .foregroundStyle(Paleta.salvia)
                            Text("Aún no defines límites.\nHazlo en Categorías, a tu ritmo.")
                                .multilineTextAlignment(.center)
                                .font(.subheadline)
                                .foregroundStyle(Paleta.piedra)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                } header: {
                    encabezado("Tus límites")
                }

                if !transacciones.isEmpty {
                    Section {
                        ForEach(transacciones.prefix(5)) { tx in
                            Button { editarTx = tx } label: {
                                FilaTransaccion(tx: tx).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .swipeEliminar { eliminar(tx) }
                        }
                    } header: {
                        encabezado("Últimos movimientos")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { mostrarAjustes = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarAgregar = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrarAgregar) { AgregarGastoView() }
            .sheet(isPresented: $mostrarAjustes) { AjustesView() }
            .sheet(item: $editarTx) { AgregarGastoView(transaccion: $0) }
        }
    }

    private func eliminar(_ tx: Transaccion) {
        contexto.delete(tx)
        SnapshotWidget.trasCambio(contexto: contexto)
    }

    /// Encabezado de sección con la voz de la app (serif, sin mayúsculas forzadas).
    private func encabezado(_ titulo: LocalizedStringKey) -> some View {
        Text(titulo)
            .font(.system(.title3, design: .serif).weight(.medium))
            .foregroundStyle(Paleta.corteza)
            .textCase(nil)
            .padding(.top, 4)
    }
}

extension View {
    /// Fila de `List` sin fondo ni separador propios: deja ver la `bruma` y
    /// permite reusar las tarjetas custom dentro de una `List`.
    func listRowFondoTransparente() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}

struct FilaPresupuesto: View {
    let estado: EstadoCategoria
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                IconoCategoria(icono: estado.categoria.icono, colorHex: estado.categoria.colorHex)
                VStack(alignment: .leading, spacing: 1) {
                    Text(estado.categoria.nombre)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Paleta.corteza)
                    Text(estado.categoria.periodoEnum.etiqueta.lowercased())
                        .font(.caption2)
                        .foregroundStyle(Paleta.piedra)
                }
                Spacer()
                Text("\(clp(estado.gastado)) de \(clp(estado.categoria.limiteMonto ?? 0))")
                    .font(.caption)
                    .foregroundStyle(Paleta.piedra)
            }
            TalloProgreso(fraccion: estado.fraccion, nivel: estado.nivel)
        }
    }
}

struct FilaTransaccion: View {
    let tx: Transaccion
    var body: some View {
        HStack(spacing: 12) {
            IconoCategoria(icono: tx.categoria?.icono ?? "leaf.fill",
                           colorHex: tx.categoria?.colorHex ?? "#7C8577")
            VStack(alignment: .leading, spacing: 1) {
                Text(tx.comercio.isEmpty ? "Sin comercio" : tx.comercio)
                    .font(.subheadline)
                    .foregroundStyle(Paleta.corteza)
                HStack(spacing: 4) {
                    if tx.origen == "applepay" {
                        Image(systemName: "wave.3.right.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Paleta.salvia)
                    }
                    Text(tx.fecha.formatted(.dateTime.day().month(.wide)))
                        .font(.caption2)
                        .foregroundStyle(Paleta.piedra)
                }
            }
            Spacer()
            Text(clp(tx.monto))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Paleta.corteza)
        }
    }
}
