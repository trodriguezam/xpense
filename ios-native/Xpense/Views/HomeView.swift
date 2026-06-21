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
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(saludo)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(Paleta.piedra)
                        Text("Tu \(mesActual), en calma")
                            .font(.system(.largeTitle, design: .serif).weight(.medium))
                            .foregroundStyle(Paleta.corteza)
                    }
                    .padding(.top, 8)
                    .listRowFondoTransparente()

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
                    .tarjeta()
                    .listRowFondoTransparente()

                    if !estados.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Tus límites")
                                .font(.system(.title3, design: .serif).weight(.medium))
                                .foregroundStyle(Paleta.corteza)
                            ForEach(estados) { e in
                                FilaPresupuesto(estado: e)
                            }
                        }
                        .tarjeta()
                        .listRowFondoTransparente()
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
                        .tarjeta()
                        .listRowFondoTransparente()
                    }
                }

                if !transacciones.isEmpty {
                    Section {
                        ForEach(transacciones.prefix(5)) { tx in
                            Button { editarTx = tx } label: {
                                FilaTransaccion(tx: tx)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Paleta.superficie))
                                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Paleta.arena, lineWidth: 1))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeEliminar { eliminar(tx) }
                        }
                    } header: {
                        Text("Últimos movimientos")
                            .font(.system(.title3, design: .serif).weight(.medium))
                            .foregroundStyle(Paleta.corteza)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
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
