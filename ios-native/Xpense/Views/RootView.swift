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
                .tabItem { Label("Grupos", systemImage: "person.2.fill") }
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
            // Arranca el store de grupos compartidos en segundo plano: así su
            // mirroring de CloudKit termina el setup ANTES de que toquen "Invitar"
            // (si no, `container.share` se llama con el mirroring a medio iniciar y
            // el framework hace fatalError). Ver `StoreCompartido.esperarMirroring`.
            _ = StoreCompartido.shared
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

/// Paleta de íconos y colores que el usuario puede elegir para una categoría.
/// Única fuente: la usan tanto crear como editar categoría.
enum CatalogoCategoria {
    static let iconos = ["leaf.fill","cart.fill","cup.and.saucer.fill","bus.fill","fuelpump.fill",
                         "bolt.fill","cross.case.fill","popcorn.fill","bag.fill","house.fill",
                         "pawprint.fill","book.fill","gift.fill","airplane","figure.run","tshirt.fill",
                         "gamecontroller.fill","wineglass.fill","wrench.and.screwdriver.fill","heart.fill",
                         "graduationcap.fill","scissors","dog.fill","camera.fill"]
    static let colores = ["#5E7561","#8A6E4B","#6E8B8F","#B5704F","#A9BFA8",
                          "#9C7B9E","#C2A36B","#8FA08A","#7C8577","#2F3A2E"]
}

/// Selector de ícono y color en carrusel horizontal. Reutilizable entre crear y
/// editar categoría. La selección de color tiñe los íconos en vivo.
struct SelectorIconoColor: View {
    @Binding var icono: String
    @Binding var colorHex: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ícono").font(.caption.weight(.semibold)).foregroundStyle(Paleta.piedra)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CatalogoCategoria.iconos, id: \.self) { i in
                            Image(systemName: i)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(i == icono ? .white : Paleta.corteza)
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(i == icono ? Color(hex: colorHex) : Paleta.arena))
                                .overlay(Circle().strokeBorder(Paleta.musgo,
                                    lineWidth: i == icono ? 2 : 0))
                                .onTapGesture { icono = i }
                        }
                    }
                    .padding(.horizontal, 2).padding(.vertical, 2)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Color").font(.caption.weight(.semibold)).foregroundStyle(Paleta.piedra)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CatalogoCategoria.colores, id: \.self) { c in
                            Circle().fill(Color(hex: c))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().strokeBorder(Paleta.corteza.opacity(0.25), lineWidth: 1))
                                .overlay(Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(c == colorHex ? 1 : 0))
                                .onTapGesture { colorHex = c }
                        }
                    }
                    .padding(.horizontal, 2).padding(.vertical, 2)
                }
            }
        }
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
