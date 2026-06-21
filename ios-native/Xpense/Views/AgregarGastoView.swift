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
    @State private var tarjetaTexto = ""
    @State private var fecha = Date.now
    @State private var categoria: Categoria?
    @State private var sugeridaAuto = false
    @State private var confirmarBorrado = false

    private var monto: Int { Int(montoTexto.filter(\.isNumber)) ?? 0 }
    private var editando: Bool { transaccion != nil }

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
                    HStack {
                        TextField("Tarjeta (opcional)", text: $tarjetaTexto)
                        if !tarjetas.isEmpty {
                            Menu {
                                Button("Ninguna") { tarjetaTexto = "" }
                                ForEach(tarjetas) { t in
                                    Button(t.nombre) { tarjetaTexto = t.nombre }
                                }
                            } label: {
                                Image(systemName: "creditcard").foregroundStyle(Paleta.musgo)
                            }
                        }
                    }
                } header: { Text("Tarjeta") }

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
                    Button("Guardar") { guardar() }.disabled(monto <= 0)
                }
            }
            .confirmationDialog("¿Eliminar este gasto?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) { eliminar() }
                Button("Cancelar", role: .cancel) {}
            }
            .onAppear {
                guard let tx = transaccion, montoTexto.isEmpty else { return }
                montoTexto = String(tx.monto)
                comercio = tx.comercio
                comercioOriginal = tx.comercio
                tarjetaTexto = tx.tarjeta?.nombre ?? ""
                fecha = tx.fecha
                categoria = tx.categoria
            }
        }
    }

    private func guardar() {
        let tarjeta = tarjetaTexto.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : Tarjeta.obtenerOCrear(nombre: tarjetaTexto, contexto: contexto)
        if let tx = transaccion {
            tx.monto = monto
            tx.comercio = comercio
            tx.fecha = fecha
            tx.categoria = categoria
            tx.tarjeta = tarjeta
        } else {
            contexto.insert(Transaccion(monto: monto, comercio: comercio, fecha: fecha,
                                        origen: "manual", categoria: categoria, tarjeta: tarjeta))
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
