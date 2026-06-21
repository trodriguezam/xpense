// RegistrarGastoIntent.swift — el corazón de la captura "Apple Pay" en Chile.
// La automatización de Atajos (gatillo "Wallet") llama esta acción en segundo plano
// con el monto y el comercio que entrega Wallet al pagar con Apple Pay.
import AppIntents
import SwiftData

struct RegistrarGastoIntent: AppIntent {
    static var title: LocalizedStringResource = "Registrar gasto"
    static var description = IntentDescription("Registra un gasto en Xpense. Pensado para la automatización de pagos en Atajos.")
    static var openAppWhenRun: Bool = false   // corre en segundo plano: no interrumpe

    @Parameter(title: "Monto (CLP)") var monto: Double
    @Parameter(title: "Comercio") var comercio: String
    @Parameter(title: "Tarjeta") var tarjeta: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar \(\.$monto) en \(\.$comercio) con \(\.$tarjeta)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let contexto = ModelContext(Persistencia.contenedor)
        Persistencia.sembrarSiHaceFalta(contexto)

        let cats = (try? contexto.fetch(FetchDescriptor<Categoria>())) ?? []
        let otros = AutoCategorizador.nombreLocalizado("Otros")
        // Usa lo aprendido (categoría + alias de nombre) y, si no, las reglas base.
        let sugerencia = AutoCategorizador.sugerencia(comercio: comercio, entre: cats, contexto: contexto)
        let categoria = sugerencia.categoria ?? cats.first(where: { $0.nombre == otros })
        let nombreComercio = sugerencia.nombre ?? (comercio.isEmpty ? "Apple Pay" : comercio)
        let tj = (tarjeta?.isEmpty == false) ? Tarjeta.obtenerOCrear(nombre: tarjeta!, contexto: contexto) : nil

        let tx = Transaccion(monto: Int(monto.rounded()),
                             comercio: nombreComercio,
                             origen: "applepay",
                             categoria: categoria,
                             tarjeta: tj)
        contexto.insert(tx)
        SnapshotWidget.trasCambio(contexto: contexto)

        let nombreCat = categoria?.nombre ?? otros
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
