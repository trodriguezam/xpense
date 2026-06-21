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
    private static let contenedorICloud = "iCloud.cl.trodriguezam.xpense"

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

    private init() {
        container = NSPersistentCloudKitContainer(name: "Compartido",
                                                  managedObjectModel: StoreCompartido.modelo())
        configurarStores()
        container.loadPersistentStores { desc, error in
            if let error {
                StoreCompartido.log.error("No se pudo cargar el store compartido (\(desc.url?.lastPathComponent ?? "?", privacy: .public)): \(error.localizedDescription, privacy: .public)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        try? container.viewContext.setQueryGenerationFrom(.current)
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
