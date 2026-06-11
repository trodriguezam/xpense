// Persistencia.swift — contenedor SwiftData en el App Group, con CloudKit.
import Foundation
import SwiftData

enum Persistencia {
    static let contenedor: ModelContainer = crearContenedor()

    /// Intenta el modo ideal (App Group + CloudKit) y degrada con calma si algo falla,
    /// para que la app siga abriendo aunque iCloud/CloudKit no esté disponible.
    private static func crearContenedor() -> ModelContainer {
        let esquema = Schema([Categoria.self, Transaccion.self])

        // 1) Ideal: datos en el App Group (los lee el widget) + sync con iCloud.
        let conNube = ModelConfiguration(schema: esquema,
                                         groupContainer: .identifier(Compartido.appGroup),
                                         cloudKitDatabase: .automatic)
        if let c = try? ModelContainer(for: esquema, configurations: [conNube]) { return c }

        // 2) Sin CloudKit, pero aún en el App Group: el widget sigue viendo los datos.
        let soloGrupo = ModelConfiguration(schema: esquema,
                                           groupContainer: .identifier(Compartido.appGroup),
                                           cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: esquema, configurations: [soloGrupo]) { return c }

        // 3) Último recurso: almacenamiento local de la app (sin sync ni widget).
        let local = ModelConfiguration(schema: esquema)
        if let c = try? ModelContainer(for: esquema, configurations: [local]) { return c }

        fatalError("No se pudo crear el contenedor de datos en ningún modo.")
    }

    /// Categorías base pensadas para Chile. Se crean solo la primera vez.
    static func sembrarSiHaceFalta(_ contexto: ModelContext) {
        let cuantas = (try? contexto.fetchCount(FetchDescriptor<Categoria>())) ?? 0
        guard cuantas == 0 else { return }
        let base: [(String, String, String)] = [
            ("Supermercado",        "cart.fill",          "#5E7561"),
            ("Restaurantes y café", "cup.and.saucer.fill","#8A6E4B"),
            ("Transporte",          "bus.fill",           "#6E8B8F"),
            ("Bencina",             "fuelpump.fill",      "#7C8577"),
            ("Cuentas y servicios", "bolt.fill",          "#B5704F"),
            ("Salud",               "cross.case.fill",    "#A9BFA8"),
            ("Entretenimiento",     "popcorn.fill",       "#9C7B9E"),
            ("Compras",             "bag.fill",           "#C2A36B"),
            ("Hogar",               "house.fill",         "#8FA08A"),
            ("Otros",               "leaf.fill",          "#2F3A2E"),
        ]
        for (n, i, c) in base {
            contexto.insert(Categoria(nombre: n, icono: i, colorHex: c, esPredeterminada: true))
        }
        try? contexto.save()
    }
}
