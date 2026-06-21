import SwiftUI
import SwiftData
import UserNotifications
import CloudKit

@main
struct XpenseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Paleta.musgo)
        }
        .modelContainer(Persistencia.contenedor)
    }
}

/// Necesario para que las notificaciones de límite se vean **también con la app
/// abierta**. Sin un `UNUserNotificationCenterDelegate` que devuelva `.banner`,
/// iOS silencia las notificaciones locales mientras la app está en primer plano
/// — que es justo cuando agregas un gasto manual y cruzas el límite.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    // MARK: - Grupos compartidos (CKShare)

    /// Punto de entrada oficial cuando el usuario toca el link de invitación a un
    /// grupo compartido. iOS lanza la app con la metadata del CKShare; aquí se
    /// acepta y se enchufa al store compartido (Fase 2b). Requiere
    /// `CKSharingSupported = true` en Info.plist.
    func application(_ application: UIApplication,
                     userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        CompartirGrupo.aceptarInvitacion(metadata)
    }
}
