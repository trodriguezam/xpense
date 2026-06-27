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

    /// En una app SwiftUI (lifecycle por **escena**), iOS entrega la metadata del
    /// CKShare a la **scene delegate**, NO a la app delegate. Por eso hay que vender
    /// una `SceneDelegate` aquí; si no, tocar el link "abre la app y no pasa nada".
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

/// Recibe la invitación a un grupo compartido (CKShare). Maneja los dos casos:
/// app **abierta** (`userDidAcceptCloudKitShareWith`) y app **lanzada desde cero**
/// por el link (`connectionOptions.cloudKitShareMetadata`). Requiere
/// `CKSharingSupported = true` en Info.plist. No crea ventana: de eso se encarga
/// SwiftUI; aquí solo aceptamos la invitación.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            CompartirGrupo.aceptarInvitacion(metadata)
        }
    }

    func windowScene(_ windowScene: UIWindowScene,
                     userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        CompartirGrupo.aceptarInvitacion(cloudKitShareMetadata)
    }
}
