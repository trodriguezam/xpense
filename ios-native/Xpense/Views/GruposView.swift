import SwiftUI
import SwiftData
import CloudKit
import CoreData

/// Grupos de gastos compartidos (familia, arrendatarios…). Cada grupo tiene
/// personas, y las tarjetas de cada persona pueden aportar a un "pozo común".
/// Versión local primero: la sincronización entre cuentas iCloud distintas
/// (CKShare) es una fase posterior; el modelo ya queda listo para ello.
struct GruposView: View {
    @Environment(\.modelContext) private var contexto
    @Query(sort: \Grupo.creadoEl) private var grupos: [Grupo]
    @State private var mostrarNuevo = false
    @State private var nombreNuevo = ""
    /// Grupos a los que ME invitaron (viven en el store compartido NSPCC, no en
    /// SwiftData). Se recargan al aparecer y ante cambios remotos de CloudKit.
    @State private var compartidos: [GrupoCompartidoMO] = []

    var body: some View {
        NavigationStack {
            Group {
                if grupos.isEmpty && compartidos.isEmpty {
                    ContentUnavailableView {
                        Label("Sin grupos aún", systemImage: "person.2")
                    } description: {
                        Text("Crea un grupo (familia, arrendatarios…) para juntar los gastos de varias personas en un pozo común.")
                    } actions: {
                        Button("Crear grupo") { mostrarNuevo = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            ForEach(grupos) { g in
                                NavigationLink(value: g) {
                                    let p = MotorPresupuesto.pozo(g, contexto: contexto)
                                    filaGrupo(nombre: g.nombre, total: p.total,
                                              personas: (g.personas ?? []).count)
                                }
                                .swipeEliminar {
                                    contexto.delete(g)
                                    SnapshotWidget.trasCambio(contexto: contexto)
                                }
                            }
                        }
                        if !compartidos.isEmpty {
                            Section("Compartidos conmigo") {
                                ForEach(compartidos, id: \.objectID) { g in
                                    NavigationLink(value: g) {
                                        filaGrupo(nombre: g.nombre ?? "—",
                                                  total: pozoCompartido(g),
                                                  personas: (g.miembros as? Set<MiembroGrupoMO>)?.count ?? 0)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Paleta.bruma)
            .navigationTitle("Grupos")
            .navigationDestination(for: Grupo.self) { DetalleGrupoView(grupo: $0) }
            .navigationDestination(for: GrupoCompartidoMO.self) { DetalleGrupoCompartidoView(grupo: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { mostrarNuevo = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("Nuevo grupo", isPresented: $mostrarNuevo) {
                TextField("Nombre (ej: Casa, Familia)", text: $nombreNuevo)
                Button("Crear") { crearGrupo() }
                    .disabled(nombreNuevo.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancelar", role: .cancel) { nombreNuevo = "" }
            }
            .onAppear { recargarCompartidos() }
            .onReceive(NotificationCenter.default.publisher(
                for: .NSPersistentStoreRemoteChange)) { _ in
                recargarCompartidos()
            }
        }
    }

    @ViewBuilder
    private func filaGrupo(nombre: String, total: Int, personas: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Paleta.musgo))
            VStack(alignment: .leading, spacing: 2) {
                Text(nombre).foregroundStyle(Paleta.corteza)
                Text("\(clp(total)) en el pozo este mes · \(personas) personas")
                    .font(.caption).foregroundStyle(Paleta.piedra)
            }
        }
    }

    /// Suma los aportes del mes de un grupo compartido (lo que se ve del pozo común).
    private func pozoCompartido(_ g: GrupoCompartidoMO) -> Int {
        let rango = MotorPresupuesto.rango(.mensual)
        let aportes = (g.aportes as? Set<AporteCompartidoMO>) ?? []
        return aportes
            .filter { ap in
                guard let f = ap.fecha else { return false }
                return f >= rango.inicio && f < rango.fin
            }
            .reduce(0) { $0 + Int($1.monto) }
    }

    /// Carga los grupos que están en la base **compartida** (los que me invitaron).
    private func recargarCompartidos() {
        let ctx = StoreCompartido.shared.contexto
        let req = NSFetchRequest<GrupoCompartidoMO>(entityName: "GrupoCompartido")
        let todos = (try? ctx.fetch(req)) ?? []
        let tienda = StoreCompartido.shared.tiendaCompartida
        compartidos = todos.filter { $0.objectID.persistentStore === tienda }
    }

    private func crearGrupo() {
        let limpio = nombreNuevo.trimmingCharacters(in: .whitespaces)
        guard !limpio.isEmpty else { return }
        let g = Grupo(nombre: limpio)
        // El usuario local arranca como una persona del grupo.
        let yo = Persona(nombre: String(localized: "Yo"), esYo: true)
        yo.grupo = g
        contexto.insert(g)
        contexto.insert(yo)
        nombreNuevo = ""
        SnapshotWidget.trasCambio(contexto: contexto)
    }
}

// MARK: - Detalle de grupo

struct DetalleGrupoView: View {
    @Environment(\.modelContext) private var contexto
    @Environment(\.dismiss) private var cerrar
    @Bindable var grupo: Grupo

    @State private var mostrarNuevaPersona = false
    @State private var nombrePersona = ""
    @State private var confirmarBorrado = false
    @State private var errorCompartir: String?
    @State private var preparandoCompartir = false

    private var personas: [Persona] {
        (grupo.personas ?? []).sorted { ($0.esYo ? 0 : 1, $0.nombre) < ($1.esYo ? 0 : 1, $1.nombre) }
    }

    var body: some View {
        let pozo = MotorPresupuesto.pozo(grupo, contexto: contexto)
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("POZO COMÚN ESTE MES")
                        .font(.caption2.weight(.semibold)).kerning(1.1)
                        .foregroundStyle(Paleta.piedra)
                    Text(clp(pozo.total))
                        .font(.system(size: 34, design: .serif).weight(.medium))
                        .foregroundStyle(Paleta.corteza)
                    if pozo.total == 0 {
                        Text("Aún nadie aporta. Marca las tarjetas que aportan al pozo en cada persona.")
                            .font(.caption).foregroundStyle(Paleta.piedra)
                    }
                }
                .listRowBackground(Paleta.superficie)
            }

            if pozo.total > 0 {
                Section("Quién aporta") {
                    ForEach(pozo.porPersona, id: \.persona.persistentModelID) { fila in
                        FilaAportePersona(nombre: fila.persona.nombre,
                                          esYo: fila.persona.esYo,
                                          aporte: fila.aporte,
                                          total: pozo.total)
                    }
                }
            }

            Section("Personas") {
                ForEach(personas) { p in
                    NavigationLink(value: p) {
                        HStack {
                            Image(systemName: p.esYo ? "person.crop.circle.fill" : "person.circle")
                                .foregroundStyle(Paleta.musgo)
                            Text(p.nombre).foregroundStyle(Paleta.corteza)
                            if p.esYo {
                                Text("tú").font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(Paleta.arena))
                                    .foregroundStyle(Paleta.piedra)
                            }
                            Spacer()
                            Text("\((p.tarjetas ?? []).count) tarjetas")
                                .font(.caption).foregroundStyle(Paleta.piedra)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !p.esYo {
                            Button(role: .destructive) {
                                contexto.delete(p)
                                SnapshotWidget.trasCambio(contexto: contexto)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                            .tint(Paleta.teja)
                        }
                    }
                }
                Button {
                    mostrarNuevaPersona = true
                } label: {
                    Label("Agregar persona", systemImage: "person.badge.plus")
                }
            }

            Section {
                Button {
                    Task { await invitar() }
                } label: {
                    HStack {
                        Label("Invitar personas", systemImage: "person.crop.circle.badge.plus")
                        Spacer()
                        if preparandoCompartir { ProgressView() }
                    }
                }
                .disabled(preparandoCompartir)
            } header: {
                Text("Compartir")
            } footer: {
                Text(grupo.idCompartido == nil
                     ? "Invita a otras personas por iCloud para que vean el pozo común en sus equipos. Cada quien edita solo sus gastos."
                     : "Este grupo ya se comparte. Vuelve a tocar para gestionar a quién invitaste.")
            }

            Section {
                Button("Eliminar grupo", role: .destructive) { confirmarBorrado = true }
                    .frame(maxWidth: .infinity)
            } footer: {
                Text("Las tarjetas no se borran; solo dejan de pertenecer a una persona.")
            }
        }
        .alert("No se pudo compartir", isPresented: Binding(
            get: { errorCompartir != nil }, set: { if !$0 { errorCompartir = nil } })) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(errorCompartir ?? "")
        }
        .scrollContentBackground(.hidden)
        .background(Paleta.bruma)
        .navigationTitle(grupo.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Persona.self) { DetallePersonaView(persona: $0, grupo: grupo) }
        .alert("Nueva persona", isPresented: $mostrarNuevaPersona) {
            TextField("Nombre", text: $nombrePersona)
            Button("Agregar") { agregarPersona() }
                .disabled(nombrePersona.trimmingCharacters(in: .whitespaces).isEmpty)
            Button("Cancelar", role: .cancel) { nombrePersona = "" }
        }
        .alert("¿Eliminar este grupo?", isPresented: $confirmarBorrado) {
            Button("Eliminar", role: .destructive) {
                contexto.delete(grupo)
                SnapshotWidget.trasCambio(contexto: contexto)
                cerrar()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se eliminan el grupo y sus personas. Las tarjetas y gastos se conservan.")
        }
    }

    private func agregarPersona() {
        let limpio = nombrePersona.trimmingCharacters(in: .whitespaces)
        guard !limpio.isEmpty else { return }
        let p = Persona(nombre: limpio)
        p.grupo = grupo
        contexto.insert(p)
        nombrePersona = ""
        SnapshotWidget.trasCambio(contexto: contexto)
    }

    /// Asegura el espejo Core Data del grupo, crea (o reusa) su CKShare y presenta
    /// la hoja de invitación. CKShare solo funciona con iCloud real (no simulador):
    /// si falla, mostramos el error con calma en vez de caernos.
    @MainActor
    private func invitar() async {
        preparandoCompartir = true
        defer { preparandoCompartir = false }
        // CloudKit debe haber terminado su setup antes de `container.share`, o el
        // framework hace fatalError (no atrapable). Esperamos con timeout.
        guard await StoreCompartido.shared.esperarMirroring() else {
            errorCompartir = String(localized: "iCloud todavía se está preparando. Intenta de nuevo en unos segundos.")
            return
        }
        do {
            let usuarioID = await CompartirGrupo.miUsuarioID()
            let mo = StoreCompartido.shared.espejo(idCompartido: grupo.idCompartido,
                                                   nombre: grupo.nombre, usuarioID: usuarioID)
            if grupo.idCompartido == nil {
                grupo.idCompartido = mo.id
                try? contexto.save()
            }
            if let existente = CompartirGrupo.shareExistente(de: mo) {
                PresentadorCompartir.presentar(share: existente,
                                               container: CompartirGrupo.contenedor,
                                               titulo: grupo.nombre)
            } else {
                let (share, contenedor) = try await CompartirGrupo.compartir(mo)
                PresentadorCompartir.presentar(share: share, container: contenedor,
                                               titulo: grupo.nombre)
            }
        } catch {
            errorCompartir = error.localizedDescription
        }
    }
}

// MARK: - Detalle de grupo compartido (solo lectura, lado invitado)

/// Vista del grupo al que ME invitaron. Vive en el store compartido (CloudKit),
/// así que es de solo lectura por ahora: muestra el pozo común y quién aporta.
/// "Ver todo, editar lo propio" — editar los aportes propios queda para después.
struct DetalleGrupoCompartidoView: View {
    let grupo: GrupoCompartidoMO

    private var miembros: [MiembroGrupoMO] {
        ((grupo.miembros as? Set<MiembroGrupoMO>) ?? [])
            .sorted { ($0.nombre ?? "") < ($1.nombre ?? "") }
    }
    private var aportes: [AporteCompartidoMO] {
        let r = MotorPresupuesto.rango(.mensual)
        return ((grupo.aportes as? Set<AporteCompartidoMO>) ?? [])
            .filter { ($0.fecha ?? .distantPast) >= r.inicio && ($0.fecha ?? .distantPast) < r.fin }
            .sorted { ($0.fecha ?? .distantPast) > ($1.fecha ?? .distantPast) }
    }
    private var total: Int { aportes.reduce(0) { $0 + Int($1.monto) } }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("POZO COMÚN ESTE MES")
                        .font(.caption2.weight(.semibold)).kerning(1.1)
                        .foregroundStyle(Paleta.piedra)
                    Text(clp(total))
                        .font(.system(size: 34, design: .serif).weight(.medium))
                        .foregroundStyle(Paleta.corteza)
                    if total == 0 {
                        Text("Aún nadie aporta a este pozo.")
                            .font(.caption).foregroundStyle(Paleta.piedra)
                    }
                }
                .listRowBackground(Paleta.superficie)
            }
            Section("Personas") {
                ForEach(miembros, id: \.objectID) { m in
                    HStack {
                        Image(systemName: "person.circle").foregroundStyle(Paleta.musgo)
                        Text(m.nombre ?? "—").foregroundStyle(Paleta.corteza)
                        if m.rol == "dueno" {
                            Text("dueño").font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Paleta.arena))
                                .foregroundStyle(Paleta.piedra)
                        }
                    }
                }
            }
            if !aportes.isEmpty {
                Section("Movimientos del periodo") {
                    ForEach(aportes, id: \.objectID) { a in
                        HStack {
                            Text(a.comercio ?? "—").foregroundStyle(Paleta.corteza)
                            Spacer()
                            Text(clp(Int(a.monto))).foregroundStyle(Paleta.piedra)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Paleta.bruma)
        .navigationTitle(grupo.nombre ?? "—")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FilaAportePersona: View {
    let nombre: String
    let esYo: Bool
    let aporte: Int
    let total: Int
    private var fraccion: Double { total > 0 ? Double(aporte) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Cada rama es su propio Text: así el literal interpolado usa
                // LocalizedStringKey (`%@ (tú)`) y el "(tú)" sí se traduce. Con el
                // ternario en uno solo, Swift lo trata como String sin localizar.
                Group {
                    if esYo { Text("\(nombre) (tú)") } else { Text(nombre) }
                }
                .font(.subheadline.weight(.medium)).foregroundStyle(Paleta.corteza)
                Spacer()
                Text(clp(aporte)).font(.subheadline).foregroundStyle(Paleta.piedra)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Paleta.arena)
                    Capsule().fill(Paleta.musgo)
                        .frame(width: max(8, geo.size.width * min(fraccion, 1)))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Detalle de persona

struct DetallePersonaView: View {
    @Environment(\.modelContext) private var contexto
    @Bindable var persona: Persona
    let grupo: Grupo

    @Query(sort: \Tarjeta.nombre) private var todasLasTarjetas: [Tarjeta]

    private var sinDueno: [Tarjeta] {
        todasLasTarjetas.filter { $0.dueno == nil }
    }
    private var misTarjetas: [Tarjeta] {
        (persona.tarjetas ?? []).sorted { $0.nombre < $1.nombre }
    }

    var body: some View {
        Form {
            Section("Nombre") {
                TextField("Nombre", text: $persona.nombre)
                if !persona.esYo {
                    Toggle("Soy yo", isOn: $persona.esYo)
                }
            }

            // Un solo contenedor: cada tarjeta es una fila con su nombre y, a la
            // derecha, el interruptor de "aporta al pozo" (es por-tarjeta). Quitar
            // por swipe. La acción de asignar vive en el mismo contenedor.
            Section {
                ForEach(misTarjetas) { t in
                    HStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(Paleta.musgo))
                        Text(t.nombre).foregroundStyle(Paleta.corteza)
                        Spacer()
                        Toggle("Aporta al pozo", isOn: Binding(
                            get: { t.aportaAlPozoPorDefecto },
                            set: { t.aportaAlPozoPorDefecto = $0; guardar() }))
                            .labelsHidden()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { t.dueno = nil; guardar() } label: {
                            Label("Quitar", systemImage: "minus.circle")
                        }
                        .tint(Paleta.teja)
                    }
                }
                if !sinDueno.isEmpty {
                    Menu {
                        ForEach(sinDueno) { t in
                            Button(t.nombre) { t.dueno = persona; guardar() }
                        }
                    } label: {
                        Label("Asignar una tarjeta", systemImage: "creditcard.and.123")
                            .foregroundStyle(Paleta.musgo)
                    }
                } else if misTarjetas.isEmpty {
                    Text("No hay tarjetas para asignar. Créalas en la pestaña Tarjetas.")
                        .font(.subheadline).foregroundStyle(Paleta.piedra)
                }
            } header: {
                Text("Tarjetas de \(persona.nombre)")
            } footer: {
                Text("El interruptor de la derecha marca si los gastos de esa tarjeta aportan al pozo común. Desliza una tarjeta para quitarla del grupo.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Paleta.bruma)
        .navigationTitle(persona.nombre)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { guardar() }
    }

    private func guardar() {
        SnapshotWidget.trasCambio(contexto: contexto)
    }
}
