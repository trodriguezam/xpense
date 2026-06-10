// RegistrarGastoIntent.swift — el corazón de la captura "Apple Pay" en Chile.
// La automatización de Atajos (gatillo "Transacción") llama esta acción en segundo plano
// con el monto y el comercio que entrega Wallet al pagar con Apple Pay.
import AppIntents
import SwiftData

struct RegistrarGastoIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar gasto"
    static var description = IntentDescription("Registra un gasto en xpense. Pensado para la automatización de Apple Pay en Atajos.")
    static var openAppWhenRun: Bool = false   // corre en segundo plano: no interrumpe

    @Parameter(title: "Monto (CLP)") var monto: Double
    @Parameter(title: "Comercio") var comercio: String

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar \(\.$monto) en \(\.$comercio)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let contexto = ModelContext(Persistencia.contenedor)
        Persistencia.sembrarSiHaceFalta(contexto)

        let cats = (try? contexto.fetch(FetchDescriptor<Categoria>())) ?? []
        let categoria = AutoCategorizador.sugerir(comercio: comercio, entre: cats)
            ?? cats.first(where: { $0.nombre == "Otros" })

        let tx = Transaccion(monto: Int(monto.rounded()),
                             comercio: comercio.isEmpty ? "Apple Pay" : comercio,
                             origen: "applepay",
                             categoria: categoria)
        contexto.insert(tx)
        SnapshotWidget.trasCambio(contexto: contexto)

        let nombreCat = categoria?.nombre ?? "Otros"
        return .result(dialog: "Anotado: \(clp(tx.monto)) en \(nombreCat).")
    }
}

struct XpenseAtajos: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RegistrarGastoIntent(),
                    phrases: ["Registrar gasto en \(.applicationName)"],
                    shortTitle: "Registrar gasto",
                    systemImageName: "leaf.fill")
    }
}
