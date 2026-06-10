import SwiftUI
import SwiftData

@main
struct XpenseApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Paleta.musgo)
        }
        .modelContainer(Persistencia.contenedor)
    }
}
