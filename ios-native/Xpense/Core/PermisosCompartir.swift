// PermisosCompartir.swift — reglas de permisos del grupo compartido.
// Política elegida: "ver todo, editar lo propio".
//   · Todos los miembros VEN todos los gastos del pozo y el total.
//   · Cada quien EDITA/BORRA solo los gastos que creó (identificados por autorID).
//   · El DUEÑO del grupo administra personas y tarjetas (no edita gastos ajenos).
//
// Funciones puras y sin dependencias de CloudKit/SwiftData a propósito: son la
// fuente de verdad de la autorización y se prueban con tests unitarios, sin
// necesitar dispositivos reales. La capa de sync (Fase 2b/2c) las consume.
import Foundation

/// Rol de un miembro dentro de un grupo compartido.
enum RolMiembro: String, Codable {
    case dueno      // creó el grupo / administra (CKShare owner)
    case miembro    // invitado (CKShare participant con permiso de escritura)
}

enum PermisosCompartir {

    /// Todos los miembros ven todo el pozo (gastos, total, aportes por persona).
    static func puedeVerPozo(rol: RolMiembro) -> Bool {
        true
    }

    /// Editar/borrar un gasto compartido: solo su autor, sin importar el rol.
    /// `autorID` y `miUsuarioID` son IDs estables de usuario de CloudKit
    /// (CKShare.ParticipantID o el record name del usuario).
    static func puedeEditarGasto(autorID: String, miUsuarioID: String) -> Bool {
        !miUsuarioID.isEmpty && autorID == miUsuarioID
    }

    /// Administrar el grupo (agregar/quitar personas, asignar tarjetas, invitar,
    /// renombrar o eliminar el grupo): solo el dueño.
    static func puedeAdministrarGrupo(rol: RolMiembro) -> Bool {
        rol == .dueno
    }

    /// Marcar si una tarjeta aporta al pozo por defecto: el dueño del grupo, o el
    /// dueño de la tarjeta (la persona a la que pertenece). Evita que un tercero
    /// cambie la configuración de una tarjeta que no es suya.
    static func puedeConfigurarTarjeta(rol: RolMiembro,
                                       duenoTarjetaID: String,
                                       miUsuarioID: String) -> Bool {
        if rol == .dueno { return true }
        return !miUsuarioID.isEmpty && duenoTarjetaID == miUsuarioID
    }
}
