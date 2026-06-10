import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Transaccion.fecha, order: .reverse) private var transacciones: [Transaccion]
    @Query private var categorias: [Categoria]
    @State private var mostrarAgregar = false

    private var estados: [EstadoCategoria] {
        MotorPresupuesto.estados(contexto: contexto)
            .filter { $0.nivel != .sinLimite }
            .sorted { $0.fraccion > $1.fraccion }
    }
    private var totalMes: Int { MotorPresupuesto.totalMes(contexto: contexto) }
    private var saludo: String {
        let h = Calendar.current.component(.hour, from: .now)
        return h < 12 ? "Buenos días" : (h < 20 ? "Buenas tardes" : "Buenas noches")
    }
    private var mesActual: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_CL")
        f.dateFormat = "MMMM"
        return f.string(from: .now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text(saludo)
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(Paleta.piedra)
                        Text("Tu \(mesActual), en calma")
                            .font(.system(.largeTitle, design: .serif).weight(.medium))
                            .foregroundStyle(Paleta.corteza)
                    }
                    .padding(.top, 8)

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
                    }

                    if !transacciones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Últimos movimientos")
                                .font(.system(.title3, design: .serif).weight(.medium))
                                .foregroundStyle(Paleta.corteza)
                            ForEach(transacciones.prefix(5)) { tx in
                                FilaTransaccion(tx: tx)
                            }
                        }
                        .tarjeta()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Paleta.bruma)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarAgregar = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrarAgregar) { AgregarGastoView() }
        }
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
                    Text(tx.fecha.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "es_CL"))))
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
