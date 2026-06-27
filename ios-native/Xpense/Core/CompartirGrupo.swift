// CompartirGrupo.swift — fachada del sharing de grupos vía CKShare (oficial).
//
// Estado: Fase 2a (groundwork). Aquí vive el punto de aceptación de invitaciones
// y la API que consumirá la UI. La creación del CKShare y el store compartido
// (NSPersistentCloudKitContainer privado+compartido) se implementan en Fase 2b/2c
// — ver `docs/grupos-compartidos.md`. No se puede probar en simulador: CKShare
// requiere 2 Apple IDs reales en 2 dispositivos.
import Foundation
import CloudKit
import os

extension Notification.Name {
    /// Se emite cuando se acepta una invitación a un grupo compartido, para que la
    /// UI salte a la pestaña Grupos y muestre el grupo recién aceptado.
    static let grupoCompartidoAceptado = Notification.Name("grupoCompartidoAceptado")
}

enum CompartirGrupo {
    private static let log = Logger(subsystem: "cl.trodriguezam.xpense", category: "CompartirGrupo")

    /// El contenedor de CloudKit del grupo compartido — el DEDICADO a grupos, no el
    /// de SwiftData. Debe calzar con `StoreCompartido.contenedorICloud`.
    static let contenedor = CKContainer(identifier: StoreCompartido.contenedorICloud)

    /// Acepta una invitación a un grupo compartido (la app fue lanzada desde el
    /// link del CKShare). Usa la API oficial de NSPersistentCloudKitContainer, que
    /// inserta la zona compartida en el store compartido y la sincroniza.
    static func aceptarInvitacion(_ metadata: CKShare.Metadata) {
        print("XPDBG aceptarInvitacion: inicio; container=\(metadata.containerIdentifier)")
        let store = StoreCompartido.shared
        guard let tienda = store.tiendaCompartida else {
            print("XPDBG aceptarInvitacion: NO hay tiendaCompartida")
            log.error("No hay tienda compartida cargada para aceptar la invitación.")
            return
        }
        print("XPDBG aceptarInvitacion: tiendaCompartida OK; llamando acceptShareInvitations")
        store.container.acceptShareInvitations(from: [metadata], into: tienda) { _, error in
            if let error {
                print("XPDBG aceptarInvitacion: ERROR \(error)")
                log.error("acceptShareInvitations falló: \(error.localizedDescription, privacy: .public)")
            } else {
                print("XPDBG aceptarInvitacion: ACEPTADA OK")
                log.info("Invitación a grupo compartido aceptada.")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .grupoCompartidoAceptado, object: nil)
                }
            }
        }
    }

    /// Crea (o reusa) el CKShare de un grupo para invitar personas. La UI lo
    /// presenta con `UICloudSharingController` (Fase 2c). Permiso público = ninguno;
    /// los participantes se invitan explícitamente con escritura.
    static func compartir(_ grupo: GrupoCompartidoMO) async throws -> (CKShare, CKContainer) {
        let (_, share, ckContainer) = try await StoreCompartido.shared.container.share([grupo], to: nil)
        share[CKShare.SystemFieldKey.title] = (grupo.nombre ?? "Grupo") as CKRecordValue
        share.publicPermission = .none
        return (share, ckContainer)
    }

    /// El CKShare existente de un grupo (si ya fue compartido), para reabrir la
    /// hoja de gestión de participantes.
    static func shareExistente(de grupo: GrupoCompartidoMO) -> CKShare? {
        try? StoreCompartido.shared.container.fetchShares(matching: [grupo.objectID])[grupo.objectID]
    }

    /// ID estable del usuario actual de iCloud, para atribuir autoría de gastos
    /// ("editar lo propio"). Devuelve nil si no hay iCloud o falla la consulta.
    static func miUsuarioID() async -> String? {
        do {
            let id = try await contenedor.userRecordID()
            return id.recordName
        } catch {
            log.error("No se pudo obtener el userRecordID: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
