import SwiftUI

/// Tutorial paso a paso para configurar la automatización de Apple Pay en Atajos.
/// Se muestra al abrir la app por primera vez y queda disponible en Ajustes.
struct TutorialView: View {
    @Environment(\.dismiss) private var cerrar
    @State private var pagina = 0

    private struct Paso {
        let icono: String
        let titulo: String
        let detalle: String
    }

    private let pasos: [Paso] = [
        .init(icono: "wave.3.right.circle.fill",
              titulo: String(localized: "Tus pagos se anotan solos"),
              detalle: String(localized: "Xpense usa la app Atajos de Apple para enterarse de cada pago con Apple Pay y registrarlo en segundo plano, sin abrir la app.\n\nConfigurarlo toma unos minutos y se hace una sola vez.")),
        .init(icono: "plus.circle.fill",
              titulo: String(localized: "1 · Crea la automatización"),
              detalle: String(localized: "Abre Atajos y ve a la pestaña Automatización.\n\nToca + (Nueva automatización) y elige el gatillo Wallet.\n\nSelecciona tus tarjetas de Apple Pay y marca Ejecutar inmediatamente.")),
        .init(icono: "square.and.pencil",
              titulo: String(localized: "2 · Crea el atajo"),
              detalle: String(localized: "Al tocar Siguiente, Atajos te pregunta qué ejecutar.\n\nElige Nuevo atajo en blanco.\n\nEn el editor, busca la acción Registrar gasto (aparece bajo Xpense) y agrégala.")),
        .init(icono: "dollarsign.circle.fill",
              titulo: String(localized: "3 · Conecta el Monto"),
              detalle: String(localized: "Toca el campo Monto (CLP) de la acción.\n\nEn la barra que aparece sobre el teclado, desliza hacia el lado hasta encontrar la variable Entrada del atajo y tócala.\n\nLuego toca esa misma variable (el recuadro azul) otra vez y elige Cantidad.")),
        .init(icono: "storefront.fill",
              titulo: String(localized: "4 · Conecta el Comercio"),
              detalle: String(localized: "Repite con el campo Comercio: toca el campo, elige Entrada del atajo en la barra, toca la variable otra vez y elige Comerciante.\n\nFinalmente toca Listo para guardar la automatización.")),
        .init(icono: "checkmark.circle.fill",
              titulo: String(localized: "¡Listo!"),
              detalle: String(localized: "Desde ahora, cada pago con Apple Pay queda registrado y categorizado solo.\n\nPuedes volver a ver esta guía cuando quieras en Ajustes.")),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $pagina) {
                    ForEach(pasos.indices, id: \.self) { i in
                        ScrollView {
                            VStack(spacing: 24) {
                                Image(systemName: pasos[i].icono)
                                    .font(.system(size: 56))
                                    .foregroundStyle(Paleta.musgo)
                                    .frame(width: 110, height: 110)
                                    .background(Circle().fill(Paleta.arena))
                                Text(pasos[i].titulo)
                                    .font(.system(.title2, design: .serif).weight(.medium))
                                    .foregroundStyle(Paleta.corteza)
                                    .multilineTextAlignment(.center)
                                Text(pasos[i].detalle)
                                    .font(.body)
                                    .foregroundStyle(Paleta.piedra)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 28)
                            }
                            .padding(.top, 36)
                            .padding(.bottom, 12)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 10) {
                    if pagina == pasos.count - 1 {
                        Link(destination: URL(string: "shortcuts://")!) {
                            Label("Abrir Atajos", systemImage: "arrow.up.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Entendido") { cerrar() }
                            .foregroundStyle(Paleta.piedra)
                    } else {
                        Button {
                            withAnimation { pagina += 1 }
                        } label: {
                            Text("Siguiente").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background(Paleta.bruma)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Saltar") { cerrar() }
                        .foregroundStyle(Paleta.piedra)
                }
            }
        }
    }
}

#Preview {
    TutorialView()
}
