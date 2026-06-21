import SwiftUI

/// Tutorial paso a paso para configurar la automatización de Apple Pay en Atajos.
/// Pensado para gente que nunca ha usado Atajos: cada paso muestra una **maqueta
/// visual** de la pantalla que verá, con la fila a tocar resaltada.
/// Se muestra al abrir la app por primera vez y queda disponible en Ajustes.
struct TutorialView: View {
    @Environment(\.dismiss) private var cerrar
    @State private var pagina = 0

    /// Fila simulada dentro de una maqueta de teléfono.
    private struct FilaSim: Identifiable, Equatable {
        let id = UUID()
        let icono: String
        let tinte: Color
        let texto: String
        var detalle: String? = nil
        var destacada: Bool = false
        var atenuada: Bool = false
    }

    private struct Paso {
        let icono: String
        let titulo: String
        let detalle: String
        var pista: String? = nil          // etiqueta sobre la maqueta ("En Automatización…")
        var pantalla: String? = nil       // título de la barra de la maqueta
        var filas: [FilaSim] = []
    }

    private let azul = Color(red: 0.0, green: 0.48, blue: 1.0)   // azul iOS de Atajos

    private var pasos: [Paso] {
        [
            .init(icono: "wave.3.right.circle.fill",
                  titulo: String(localized: "Tus pagos se anotan solos"),
                  detalle: String(localized: "Xpense usa la app Atajos de Apple para enterarse de cada pago con Apple Pay y registrarlo en segundo plano, sin abrir la app.\n\nConfigurarlo toma unos minutos y se hace una sola vez. Te guiamos pantalla por pantalla.")),

            .init(icono: "plus.circle.fill",
                  titulo: String(localized: "1 · Crea la automatización"),
                  detalle: String(localized: "Abre Atajos y entra a la pestaña Automatización. Toca + para crear una nueva y elige el gatillo Wallet. Luego marca tus tarjetas y “Ejecutar inmediatamente”."),
                  pista: String(localized: "App Atajos › pestaña Automatización"),
                  pantalla: String(localized: "Automatización"),
                  filas: [
                    .init(icono: "plus", tinte: azul, texto: String(localized: "Nueva automatización"), detalle: String(localized: "Tócalo para empezar"), destacada: true),
                    .init(icono: "creditcard.fill", tinte: .black, texto: String(localized: "Wallet"), detalle: String(localized: "Elige este gatillo"), destacada: true),
                    .init(icono: "bell.fill", tinte: .red, texto: String(localized: "Mensaje"), atenuada: true),
                  ]),

            .init(icono: "square.and.pencil",
                  titulo: String(localized: "2 · Crea el atajo"),
                  detalle: String(localized: "Al tocar Siguiente, Atajos pregunta qué ejecutar. Elige Nuevo atajo en blanco. En el editor, busca la acción Registrar gasto (aparece bajo Xpense) y agrégala."),
                  pista: String(localized: "Elige qué ejecutar"),
                  pantalla: String(localized: "Nuevo atajo"),
                  filas: [
                    .init(icono: "square.dashed", tinte: .gray, texto: String(localized: "Nuevo atajo en blanco"), destacada: true),
                    .init(icono: "leaf.fill", tinte: Paleta.musgo, texto: String(localized: "Registrar gasto"), detalle: String(localized: "Búscala bajo “Xpense”"), destacada: true),
                  ]),

            .init(icono: "dollarsign.circle.fill",
                  titulo: String(localized: "3 · Conecta el Monto"),
                  detalle: String(localized: "Toca el campo Monto (CLP). En la barra sobre el teclado desliza hasta Entrada del atajo y tócala; luego toca esa variable azul otra vez y elige Cantidad."),
                  pista: String(localized: "Acción “Registrar gasto”"),
                  pantalla: String(localized: "Registrar gasto"),
                  filas: [
                    .init(icono: "dollarsign.circle.fill", tinte: Paleta.musgo, texto: String(localized: "Monto (CLP)"), detalle: String(localized: "Entrada del atajo › Cantidad"), destacada: true),
                    .init(icono: "storefront.fill", tinte: Paleta.salvia, texto: String(localized: "Comercio"), atenuada: true),
                    .init(icono: "creditcard.fill", tinte: Paleta.salvia, texto: String(localized: "Tarjeta"), atenuada: true),
                  ]),

            .init(icono: "storefront.fill",
                  titulo: String(localized: "4 · Conecta el Comercio"),
                  detalle: String(localized: "Repite con el campo Comercio: tócalo, elige Entrada del atajo en la barra, toca la variable otra vez y elige Comerciante."),
                  pista: String(localized: "Misma acción"),
                  pantalla: String(localized: "Registrar gasto"),
                  filas: [
                    .init(icono: "dollarsign.circle.fill", tinte: Paleta.salvia, texto: String(localized: "Monto (CLP)"), detalle: String(localized: "✓ Cantidad"), atenuada: true),
                    .init(icono: "storefront.fill", tinte: Paleta.musgo, texto: String(localized: "Comercio"), detalle: String(localized: "Entrada del atajo › Comerciante"), destacada: true),
                    .init(icono: "creditcard.fill", tinte: Paleta.salvia, texto: String(localized: "Tarjeta"), atenuada: true),
                  ]),

            .init(icono: "creditcard.fill",
                  titulo: String(localized: "5 · Conecta la Tarjeta"),
                  detalle: String(localized: "Repite en el campo Tarjeta: tócalo, elige Entrada del atajo y luego el subcampo Tarjeta. Finalmente toca Listo para guardar la automatización."),
                  pista: String(localized: "Último campo"),
                  pantalla: String(localized: "Registrar gasto"),
                  filas: [
                    .init(icono: "dollarsign.circle.fill", tinte: Paleta.salvia, texto: String(localized: "Monto (CLP)"), detalle: String(localized: "✓ Cantidad"), atenuada: true),
                    .init(icono: "storefront.fill", tinte: Paleta.salvia, texto: String(localized: "Comercio"), detalle: String(localized: "✓ Comerciante"), atenuada: true),
                    .init(icono: "creditcard.fill", tinte: Paleta.musgo, texto: String(localized: "Tarjeta"), detalle: String(localized: "Entrada del atajo › Tarjeta"), destacada: true),
                  ]),

            .init(icono: "creditcard.circle.fill",
                  titulo: String(localized: "Tus tarjetas"),
                  detalle: String(localized: "Cada gasto en Xpense lleva una tarjeta. Las de Apple Pay se crean solas con su nombre. Para gastos a mano, eliges una de la lista — y puedes agregar las tuyas con el botón + en la pestaña Tarjetas."),
                  pista: String(localized: "Xpense › pestaña Tarjetas"),
                  pantalla: String(localized: "Tarjetas"),
                  filas: [
                    .init(icono: "creditcard.fill", tinte: Paleta.musgo, texto: String(localized: "Visa ·· 4321"), detalle: String(localized: "Se creó sola al pagar")),
                    .init(icono: "creditcard.fill", tinte: Paleta.musgo, texto: String(localized: "Tarjeta de mamá"), detalle: String(localized: "Agregada a mano")),
                    .init(icono: "plus", tinte: azul, texto: String(localized: "Agregar tarjeta"), detalle: String(localized: "Con el botón + arriba"), destacada: true),
                  ]),

            .init(icono: "checkmark.circle.fill",
                  titulo: String(localized: "¡Listo!"),
                  detalle: String(localized: "Desde ahora, cada pago con Apple Pay queda registrado y categorizado solo.\n\nPuedes volver a ver esta guía cuando quieras en Ajustes.")),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $pagina) {
                    ForEach(pasos.indices, id: \.self) { i in
                        ScrollView {
                            VStack(spacing: 20) {
                                if pasos[i].filas.isEmpty {
                                    Image(systemName: pasos[i].icono)
                                        .font(.system(size: 56))
                                        .foregroundStyle(Paleta.musgo)
                                        .frame(width: 110, height: 110)
                                        .background(Circle().fill(Paleta.arena))
                                        .padding(.top, 12)
                                } else {
                                    if let pista = pasos[i].pista {
                                        Label(pista, systemImage: "arrow.down")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(Paleta.piedra)
                                    }
                                    TelefonoSim(pantalla: pasos[i].pantalla ?? "", filas: pasos[i].filas)
                                }
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
                            .padding(.top, 24)
                            .padding(.bottom, 16)
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

    /// Maqueta estilizada de una pantalla de teléfono con filas tipo lista.
    /// Resalta las filas `destacada` y atenúa las `atenuada` para guiar la vista.
    private struct TelefonoSim: View {
        let pantalla: String
        let filas: [FilaSim]

        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(red: 0, green: 0.48, blue: 1))
                    Spacer()
                    Text(pantalla)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Paleta.corteza)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)

                Divider()

                VStack(spacing: 0) {
                    ForEach(filas) { f in
                        HStack(spacing: 10) {
                            Image(systemName: f.icono)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(f.tinte))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(f.texto)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(Paleta.corteza)
                                if let d = f.detalle {
                                    Text(d).font(.caption2).foregroundStyle(Paleta.musgo)
                                }
                            }
                            Spacer()
                            if f.destacada {
                                Image(systemName: "hand.point.up.left.fill")
                                    .font(.caption)
                                    .foregroundStyle(Paleta.cobre)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .opacity(f.atenuada ? 0.45 : 1)
                        .background(f.destacada ? Paleta.arena.opacity(0.7) : Color.clear)
                        if f.id != filas.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
            .background(Paleta.superficie)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Paleta.corteza.opacity(0.18), lineWidth: 5)
            )
            .frame(maxWidth: 270)
            .shadow(color: Paleta.corteza.opacity(0.12), radius: 10, y: 6)
        }
    }
}

#Preview {
    TutorialView()
}
