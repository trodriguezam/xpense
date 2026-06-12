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
        limpiarDuplicados(contexto)
        let cuantas = (try? contexto.fetchCount(FetchDescriptor<Categoria>())) ?? 0
        guard cuantas == 0 else { return }
        // Los nombres se siembran en el idioma del dispositivo (deben calzar con
        // lo que devuelve AutoCategorizador.nombreLocalizado para las reglas).
        let base: [(String, String, String)] = [
            (String(localized: "Supermercado"),        "cart.fill",          "#5E7561"),
            (String(localized: "Restaurantes y café"), "cup.and.saucer.fill","#8A6E4B"),
            (String(localized: "Transporte"),          "bus.fill",           "#6E8B8F"),
            (String(localized: "Bencina"),             "fuelpump.fill",      "#7C8577"),
            (String(localized: "Cuentas y servicios"), "bolt.fill",          "#B5704F"),
            (String(localized: "Salud"),               "cross.case.fill",    "#A9BFA8"),
            (String(localized: "Entretenimiento"),     "popcorn.fill",       "#9C7B9E"),
            (String(localized: "Compras"),             "bag.fill",           "#C2A36B"),
            (String(localized: "Hogar"),               "house.fill",         "#8FA08A"),
            (String(localized: "Otros"),               "leaf.fill",          "#2F3A2E"),
        ]
        for (n, i, c) in base {
            contexto.insert(Categoria(nombre: n, icono: i, colorHex: c, esPredeterminada: true))
        }
        try? contexto.save()
    }

    /// Une categorías con el mismo nombre: CloudKit puede duplicar el sembrado
    /// cuando el sync baja las categorías de una instalación anterior después de
    /// haber sembrado localmente. Conserva la más antigua, reasigna sus
    /// transacciones y hereda el límite si la original no tenía.
    static func limpiarDuplicados(_ contexto: ModelContext) {
        let cats = (try? contexto.fetch(
            FetchDescriptor<Categoria>(sortBy: [SortDescriptor(\.creadaEl)]))) ?? []
        var porNombre: [String: Categoria] = [:]
        var huboCambios = false
        for cat in cats {
            let clave = cat.nombre.trimmingCharacters(in: .whitespaces).lowercased()
            guard let original = porNombre[clave] else {
                porNombre[clave] = cat
                continue
            }
            for tx in cat.transacciones ?? [] { tx.categoria = original }
            if original.limiteMonto == nil, let limite = cat.limiteMonto {
                original.limiteMonto = limite
                original.periodo = cat.periodo
                original.umbralAviso = cat.umbralAviso
            }
            contexto.delete(cat)
            huboCambios = true
        }
        if huboCambios { try? contexto.save() }
    }
}
