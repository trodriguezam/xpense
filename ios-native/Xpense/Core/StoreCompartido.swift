// StoreCompartido.swift — Fase 2b. Store dedicado para los grupos compartidos.
//
// SwiftData NO soporta CloudKit compartido (solo .automatic/.private/.none), así
// que las entidades del grupo viven en un `NSPersistentCloudKitContainer` aparte
// (Core Data), que SÍ es la API oficial para CKShare: un store **privado** (mis
// grupos) + un store **compartido** (grupos donde soy invitado). SwiftData sigue
// dueño de todo lo privado de la app. Ver `docs/grupos-compartidos.md`.
//
// El modelo se define en código (NSManagedObjectModel programático) para no
// depender de un .xcdatamodeld en el bundle. Sin iCloud (p. ej. simulador), el
// contenedor degrada a local con calma — la app no debe caerse por esto.
import CoreData
import CloudKit
import os

// MARK: - Entidades compartidas (Core Data)

@objc(GrupoCompartidoMO)
final class GrupoCompartidoMO: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var nombre: String?
    @NSManaged var creadoEl: Date?
    @NSManaged var miembros: NSSet?
    @NSManaged var aportes: NSSet?
}

@objc(MiembroGrupoMO)
final class MiembroGrupoMO: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var nombre: String?
    @NSManaged var usuarioID: String?   // CKShare participant / userRecordID
    @NSManaged var rol: String?         // "dueno" | "miembro"
    @NSManaged var grupo: GrupoCompartidoMO?
}

@objc(AporteCompartidoMO)
final class AporteCompartidoMO: NSManagedObject {
    @NSManaged var id: String?
    @NSManaged var monto: Int64
    @NSManaged var comercio: String?
    @NSManaged var fecha: Date?
    @NSManaged var autorID: String?     // usuarioID de quien lo creó ("editar lo propio")
    @NSManaged var nombreTarjeta: String?
    @NSManaged var grupo: GrupoCompartidoMO?
}

// MARK: - Contenedor

final class StoreCompartido {
    static let shared = StoreCompartido()
    private static let log = Logger(subsystem: "cl.trodriguezam.xpense", category: "StoreCompartido")
    // Contenedor CloudKit DEDICADO a los grupos compartidos. Debe ser distinto del
    // que usa SwiftData (`iCloud.cl.trodriguezam.xpense`): dos NSPCC/mirroring sobre
    // el mismo contenedor entran en conflicto y `container.share(...)` revienta.
    static let contenedorICloud = "iCloud.cl.trodriguezam.xpense.grupos"

    let container: NSPersistentCloudKitContainer
    var contexto: NSManagedObjectContext { container.viewContext }

    private static let archivoPrivado = "Compartido.sqlite"
    private static let archivoCompartido = "Compartido-shared.sqlite"

    /// La tienda de la base **compartida** de CloudKit (donde caen los grupos a los
    /// que me invitaron). La necesita `acceptShareInvitations`.
    var tiendaCompartida: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores
            .first { $0.url?.lastPathComponent == Self.archivoCompartido }
    }

    /// La tienda de la base **privada** (mis grupos). Con dos stores, los objetos
    /// nuevos hay que asignarlos explícitamente a uno o Core Data no sabe a cuál
    /// van y `container.share` falla.
    var tiendaPrivada: NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores
            .first { $0.url?.lastPathComponent == Self.archivoPrivado }
    }

    /// `true` cuando el mirroring de CloudKit terminó su **setup** inicial. Antes de
    /// eso NO se puede llamar `container.share(...)`: el delegate de mirroring aún es
    /// nil y el framework hace `fatalError` (no se puede atrapar). Ver `esperarMirroring`.
    private(set) var mirroringListo = false

    private init() {
        container = NSPersistentCloudKitContainer(name: "Compartido",
                                                  managedObjectModel: StoreCompartido.modelo())
        configurarStores()
        // Observa los eventos del mirroring para saber cuándo el setup terminó.
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container, queue: .main) { [weak self] nota in
            guard let evento = nota.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
            if evento.type == .setup, evento.endDate != nil, evento.error == nil {
                self?.mirroringListo = true
            }
        }
        container.loadPersistentStores { desc, error in
            if let error {
                StoreCompartido.log.error("No se pudo cargar el store compartido (\(desc.url?.lastPathComponent ?? "?", privacy: .public)): \(error.localizedDescription, privacy: .public)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Espera (con timeout) a que el mirroring de CloudKit esté listo para compartir.
    /// Devuelve `true` si quedó listo. Evita el `fatalError` de `container.share`
    /// cuando se toca "Invitar" justo al abrir la app, antes de que CloudKit arranque.
    func esperarMirroring(timeout: TimeInterval = 12) async -> Bool {
        if mirroringListo { return true }
        let pasoNanos: UInt64 = 400_000_000   // 0.4 s
        var transcurrido: TimeInterval = 0
        while transcurrido < timeout {
            try? await Task.sleep(nanoseconds: pasoNanos)
            transcurrido += 0.4
            if mirroringListo { return true }
        }
        return mirroringListo
    }

    /// Dos descripciones de store apuntando al MISMO contenedor de CloudKit: una a
    /// la base privada y otra a la compartida (requisito de CKShare con Core Data).
    private func configurarStores() {
        let base = NSPersistentContainer.defaultDirectoryURL()
        let privada = descripcion(url: base.appendingPathComponent(Self.archivoPrivado), scope: .private)
        let compartida = descripcion(url: base.appendingPathComponent(Self.archivoCompartido), scope: .shared)
        container.persistentStoreDescriptions = [privada, compartida]
    }

    private func descripcion(url: URL, scope: CKDatabase.Scope) -> NSPersistentStoreDescription {
        let d = NSPersistentStoreDescription(url: url)
        let opciones = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.contenedorICloud)
        opciones.databaseScope = scope
        d.cloudKitContainerOptions = opciones
        d.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        d.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        return d
    }

    func guardar() {
        guard contexto.hasChanges else { return }
        do { try contexto.save() }
        catch { Self.log.error("Error guardando store compartido: \(error.localizedDescription, privacy: .public)") }
    }

    // MARK: - Espejo del grupo local

    /// Devuelve el espejo Core Data del grupo local (por `idCompartido`), creándolo
    /// la primera vez junto con el miembro "dueño" (yo). Es lo que se comparte por
    /// CKShare. No referencia la `Transaccion` privada: vive en otra zona/cuenta.
    func espejo(idCompartido: String?, nombre: String, usuarioID: String?) -> GrupoCompartidoMO {
        if let idCompartido, let existente = buscarGrupo(id: idCompartido) {
            return existente
        }
        let g = GrupoCompartidoMO(context: contexto)
        g.id = idCompartido ?? UUID().uuidString
        g.nombre = nombre
        g.creadoEl = Date()
        let yo = MiembroGrupoMO(context: contexto)
        yo.id = UUID().uuidString
        yo.nombre = String(localized: "Yo")
        yo.usuarioID = usuarioID
        yo.rol = "dueno"
        yo.grupo = g
        // Con stores privado+compartido, asignar explícitamente al privado: si no,
        // Core Data no sabe a cuál store va el objeto nuevo y `share(...)` revienta.
        if let priv = tiendaPrivada {
            contexto.assign(g, to: priv)
            contexto.assign(yo, to: priv)
        }
        guardar()
        return g
    }

    func buscarGrupo(id: String) -> GrupoCompartidoMO? {
        let req = NSFetchRequest<GrupoCompartidoMO>(entityName: "GrupoCompartido")
        req.predicate = NSPredicate(format: "id == %@", id)
        req.fetchLimit = 1
        return try? contexto.fetch(req).first
    }

    // MARK: - Modelo programático

    private static func modelo() -> NSManagedObjectModel {
        let modelo = NSManagedObjectModel()

        let grupo = entidad("GrupoCompartido", clase: GrupoCompartidoMO.self)
        let miembro = entidad("MiembroGrupo", clase: MiembroGrupoMO.self)
        let aporte = entidad("AporteCompartido", clase: AporteCompartidoMO.self)

        // Regla CloudKit: atributos opcionales o con default; relaciones opcionales; sin unique.
        grupo.properties = [
            atributo("id", .stringAttributeType),
            atributo("nombre", .stringAttributeType),
            atributo("creadoEl", .dateAttributeType),
        ]
        miembro.properties = [
            atributo("id", .stringAttributeType),
            atributo("nombre", .stringAttributeType),
            atributo("usuarioID", .stringAttributeType),
            atributo("rol", .stringAttributeType),
        ]
        aporte.properties = [
            atributo("id", .stringAttributeType),
            atributo("monto", .integer64AttributeType, opcional: false, defaultValue: 0),
            atributo("comercio", .stringAttributeType),
            atributo("fecha", .dateAttributeType),
            atributo("autorID", .stringAttributeType),
            atributo("nombreTarjeta", .stringAttributeType),
        ]

        // Relaciones (todas opcionales para CloudKit).
        let grupoAMiembros = relacion("miembros", destino: miembro, aMuchos: true)
        let miembroAGrupo = relacion("grupo", destino: grupo, aMuchos: false)
        grupoAMiembros.inverseRelationship = miembroAGrupo
        miembroAGrupo.inverseRelationship = grupoAMiembros
        miembroAGrupo.deleteRule = .nullifyDeleteRule
        grupoAMiembros.deleteRule = .cascadeDeleteRule

        let grupoAAportes = relacion("aportes", destino: aporte, aMuchos: true)
        let aporteAGrupo = relacion("grupo", destino: grupo, aMuchos: false)
        grupoAAportes.inverseRelationship = aporteAGrupo
        aporteAGrupo.inverseRelationship = grupoAAportes
        aporteAGrupo.deleteRule = .nullifyDeleteRule
        grupoAAportes.deleteRule = .cascadeDeleteRule

        grupo.properties += [grupoAMiembros, grupoAAportes]
        miembro.properties += [miembroAGrupo]
        aporte.properties += [aporteAGrupo]

        modelo.entities = [grupo, miembro, aporte]
        return modelo
    }

    private static func entidad(_ nombre: String, clase: NSManagedObject.Type) -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = nombre
        e.managedObjectClassName = NSStringFromClass(clase)
        return e
    }

    private static func atributo(_ nombre: String, _ tipo: NSAttributeType,
                                 opcional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = nombre
        a.attributeType = tipo
        a.isOptional = opcional
        if let defaultValue { a.defaultValue = defaultValue }
        return a
    }

    private static func relacion(_ nombre: String, destino: NSEntityDescription,
                                 aMuchos: Bool) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = nombre
        r.destinationEntity = destino
        r.isOptional = true
        r.minCount = 0
        r.maxCount = aMuchos ? 0 : 1   // 0 = "to-many"
        return r
    }
}
