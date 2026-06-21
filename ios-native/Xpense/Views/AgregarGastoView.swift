import SwiftUI
import SwiftData

/// Crea un gasto nuevo o edita uno existente (si `transaccion` viene con valor).
struct AgregarGastoView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Query(sort: \Categoria.nombre) private var categorias: [Categoria]
    @Query(sort: \Tarjeta.nombre) private var tarjetas: [Tarjeta]

    var transaccion: Transaccion? = nil

    @State private var montoTexto = ""
    @State private var comercio = ""
    @State private var comercioOriginal = ""        // nombre crudo al abrir (para el alias)
    @State private var tarjeta: Tarjeta?
    @State private var fecha = Date.now
    @State private var categoria: Categoria?
    @State private var sugeridaAuto = false
    @State private var confirmarBorrado = false
    @State private var aporte: AporteOpcion = .porDefecto

    /// Override del aporte al pozo para este gasto. `porDefecto` respeta la tarjeta.
    private enum AporteOpcion: Hashable {
        case porDefecto, si, no
        var valor: Bool? {
            switch self {
            case .porDefecto: return nil
            case .si: return true
            case .no: return false
            }
        }
        init(_ v: Bool?) { self = v == nil ? .porDefecto : (v! ? .si : .no) }
    }

    private var monto: Int { Int(montoTexto.filter(\.isNumber)) ?? 0 }
    private var editando: Bool { transaccion != nil }
    /// La tarjeta elegida pertenece a una persona de un grupo.
    private var tarjetaEnGrupo: Bool { tarjeta?.dueno?.grupo != nil }

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
                            if let s = AutoCategorizador.clasificar(comercio: comercio, entre: categorias, contexto: contexto) {
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
                }

                Section {
                    if tarjetas.isEmpty {
                        Label {
                            Text("Aún no tienes tarjetas. Agrégalas en la pestaña Tarjetas, o aparecen solas al pagar con Apple Pay.")
                                .font(.subheadline).foregroundStyle(Paleta.piedra)
                        } icon: {
                            Image(systemName: "creditcard").foregroundStyle(Paleta.piedra)
                        }
                    } else {
                        Picker("Tarjeta", selection: $tarjeta) {
                            Text("Elige una tarjeta").tag(Tarjeta?.none)
                            ForEach(tarjetas) { t in
                                Label(t.nombre, systemImage: "creditcard.fill").tag(Optional(t))
                            }
                        }
                    }
                } header: { Text("Tarjeta") }

                if tarjetaEnGrupo {
                    Section {
                        Picker("Aporta al pozo", selection: $aporte) {
                            Text("Según la tarjeta").tag(AporteOpcion.porDefecto)
                            Text("Sí").tag(AporteOpcion.si)
                            Text("No").tag(AporteOpcion.no)
                        }
                        .pickerStyle(.segmented)
                    } header: { Text("Pozo del grupo") } footer: {
                        let pred = (tarjeta?.aportaAlPozoPorDefecto ?? false)
                            ? String(localized: "aporta") : String(localized: "no aporta")
                        Text("Por defecto, esta tarjeta \(pred) al pozo. Puedes cambiarlo solo para este gasto.")
                    }
                }

                if editando {
                    Section {
                        Button("Eliminar gasto", role: .destructive) { confirmarBorrado = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .navigationTitle(editando ? String(localized: "Editar gasto") : String(localized: "Nuevo gasto"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { cerrar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }.disabled(monto <= 0 || tarjeta == nil)
                }
            }
            .alert("¿Eliminar este gasto?", isPresented: $confirmarBorrado) {
                Button("Eliminar", role: .destructive) { eliminar() }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .onAppear {
                guard let tx = transaccion, montoTexto.isEmpty else { return }
                montoTexto = String(tx.monto)
                comercio = tx.comercio
                comercioOriginal = tx.comercio
                tarjeta = tx.tarjeta
                fecha = tx.fecha
                categoria = tx.categoria
                aporte = AporteOpcion(tx.aporteAlPozo)
            }
        }
    }

    private func guardar() {
        // Si la tarjeta no está en un grupo, no tiene sentido un override de pozo.
        let aporteFinal = tarjetaEnGrupo ? aporte.valor : nil
        if let tx = transaccion {
            tx.monto = monto
            tx.comercio = comercio
            tx.fecha = fecha
            tx.categoria = categoria
            tx.tarjeta = tarjeta
            tx.aporteAlPozo = aporteFinal
        } else {
            contexto.insert(Transaccion(monto: monto, comercio: comercio, fecha: fecha,
                                        origen: "manual", categoria: categoria, tarjeta: tarjeta,
                                        aporteAlPozo: aporteFinal))
        }
        // Aprende de esta clasificación manual. Si editando y se renombró el
        // comercio, indexa por el nombre CRUDO original y guarda el alias nuevo.
        let crudo = (editando && !comercioOriginal.isEmpty) ? comercioOriginal : comercio
        let alias = (editando && comercioOriginal != comercio) ? comercio : nil
        AutoCategorizador.aprender(comercio: crudo, nombreDisplay: alias,
                                   categoria: categoria, contexto: contexto)
        SnapshotWidget.trasCambio(contexto: contexto)
        cerrar()
    }

    private func eliminar() {
        if let tx = transaccion {
            contexto.delete(tx)
            SnapshotWidget.trasCambio(contexto: contexto)
        }
        cerrar()
    }
}
