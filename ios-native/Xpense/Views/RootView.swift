import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var contexto
    @AppStorage("tutorialVisto") private var tutorialVisto = false
    @State private var mostrarTutorial = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Inicio", systemImage: "leaf.fill") }
            TransaccionesView()
                .tabItem { Label("Gastos", systemImage: "list.bullet") }
            CategoriasView()
                .tabItem { Label("Categorías", systemImage: "circle.grid.2x2.fill") }
            TarjetasView()
                .tabItem { Label("Tarjetas", systemImage: "creditcard.fill") }
            GruposView()
                .tabItem { Label("Grupo", systemImage: "person.2.fill") }
        }
        .sheet(isPresented: $mostrarTutorial, onDismiss: {
            tutorialVisto = true
            // El permiso se pide recién al cerrar el tutorial, para no taparlo.
            Task { await Avisos.pedirPermiso() }
        }) {
            TutorialView()
        }
        .task {
            Persistencia.sembrarSiHaceFalta(contexto)
            // Poblar el widget de inmediato: no debe quedar a la espera de que el
            // usuario responda el diálogo de permiso de notificaciones.
            SnapshotWidget.escribir(contexto: contexto)
            if !tutorialVisto {
                mostrarTutorial = true
            } else {
                await Avisos.pedirPermiso()
            }
        }
    }
}

// MARK: - Componentes compartidos

struct TalloProgreso: View {
    let fraccion: Double
    let nivel: Nivel
    var color: Color {
        switch nivel {
        case .superado: return Paleta.teja
        case .cerca:    return Paleta.cobre
        default:        return Paleta.musgo
        }
    }
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Paleta.arena)
                Capsule()
                    .fill(color)
                    .frame(width: max(10, geo.size.width * min(fraccion, 1)))
                    .animation(.easeOut(duration: 0.6), value: fraccion)
            }
        }
        .frame(height: 10)
    }
}

struct IconoCategoria: View {
    let icono: String
    let colorHex: String
    var body: some View {
        Image(systemName: icono)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Circle().fill(Color(hex: colorHex)))
    }
}

extension View {
    func tarjeta() -> some View {
        self.padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Paleta.superficie))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Paleta.arena, lineWidth: 1))
    }

    /// Swipe destructivo consistente en toda la app: tinte `teja` (rojo cálido de
    /// la paleta, no de pánico) e ícono de basurero. Reemplaza al rojo del sistema
    /// que dejaba `.onDelete`, para que todos los borrados se vean igual.
    func swipeEliminar(_ titulo: LocalizedStringKey = "Eliminar",
                       systemImage: String = "trash",
                       accion: @escaping () -> Void) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: accion) {
                Label(titulo, systemImage: systemImage)
            }
            .tint(Paleta.teja)
        }
    }
}
