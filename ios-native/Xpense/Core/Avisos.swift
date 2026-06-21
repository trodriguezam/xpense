// Avisos.swift — notificaciones locales con tono amable. Un aviso por nivel por periodo.
import Foundation
import UserNotifications
import UIKit

enum Avisos {
    static func pedirPermiso() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// El diálogo del sistema solo aparece una vez. Si el permiso ya se decidió,
    /// lo que corresponde es llevar al usuario a los Ajustes de la app.
    @MainActor
    static func revisarPermiso() async {
        let centro = UNUserNotificationCenter.current()
        let ajustes = await centro.notificationSettings()
        if ajustes.authorizationStatus == .notDetermined {
            await pedirPermiso()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            _ = await UIApplication.shared.open(url)
        }
    }

    /// Notifica solo si el nivel subió respecto del último aviso de este periodo.
    static func evaluar(_ estado: EstadoCategoria) {
        guard estado.nivel == .cerca || estado.nivel == .superado else { return }
        let cat = estado.categoria
        let clave = "aviso.\(cat.nombre).\(MotorPresupuesto.clavePeriodo(cat.periodoEnum))"
        let ud = UserDefaults(suiteName: Compartido.appGroup)
        let previo = ud?.integer(forKey: clave) ?? 0
        guard estado.nivel.rawValue > previo else { return }
        ud?.set(estado.nivel.rawValue, forKey: clave)

        let contenido = UNMutableNotificationContent()
        let limite = cat.limiteMonto ?? 0
        let periodoTxt = cat.periodoEnum == .semanal
            ? String(localized: "esta semana") : String(localized: "este mes")
        if estado.nivel == .cerca {
            contenido.title = String(localized: "Te acercas al límite de \(cat.nombre)")
            contenido.body = String(localized: "Llevas \(clp(estado.gastado)) de \(clp(limite)) \(periodoTxt). Aún hay espacio — respira.")
        } else {
            contenido.title = String(localized: "Superaste el límite de \(cat.nombre)")
            contenido.body = String(localized: "Llevas \(clp(estado.gastado)) de \(clp(limite)) \(periodoTxt). Sin culpa: obsérvalo y sigue.")
        }
        contenido.sound = .default
        let req = UNNotificationRequest(identifier: clave + ".\(estado.nivel.rawValue)",
                                        content: contenido, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    /// Aviso de límite mensual de una tarjeta (mismo patrón: 1 por nivel por mes).
    static func evaluar(_ estado: EstadoTarjeta) {
        guard estado.nivel == .cerca || estado.nivel == .superado else { return }
        let t = estado.tarjeta
        let clave = "avisoTarjeta.\(t.nombre).\(MotorPresupuesto.clavePeriodo(.mensual))"
        let ud = UserDefaults(suiteName: Compartido.appGroup)
        let previo = ud?.integer(forKey: clave) ?? 0
        guard estado.nivel.rawValue > previo else { return }
        ud?.set(estado.nivel.rawValue, forKey: clave)

        let contenido = UNMutableNotificationContent()
        let limite = t.limiteMonto ?? 0
        if estado.nivel == .cerca {
            contenido.title = String(localized: "Te acercas al límite de \(t.nombre)")
            contenido.body = String(localized: "Llevas \(clp(estado.gastado)) de \(clp(limite)) este mes en \(t.nombre). Aún hay espacio — respira.")
        } else {
            contenido.title = String(localized: "Superaste el límite de \(t.nombre)")
            contenido.body = String(localized: "Llevas \(clp(estado.gastado)) de \(clp(limite)) este mes en \(t.nombre). Sin culpa: obsérvalo y sigue.")
        }
        contenido.sound = .default
        let req = UNNotificationRequest(identifier: clave + ".\(estado.nivel.rawValue)",
                                        content: contenido, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
