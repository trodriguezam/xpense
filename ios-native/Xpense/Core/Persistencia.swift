// Persistencia.swift — contenedor SwiftData en el App Group, con CloudKit.
import Foundation
import SwiftData

enum Persistencia {
    static let contenedor: ModelContainer = crearContenedor()

    /// Intenta el modo ideal (App Group + CloudKit) y degrada con calma si algo falla,
    /// para que la app siga abriendo aunque iCloud/CloudKit no esté disponible.
    private static func crearContenedor() -> ModelContainer {
        let esquema = Schema([Categoria.self, Transaccion.self, ReglaAprendida.self, Tarjeta.self])

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

    /// Categorías base pensadas para Chile. La clave es el nombre en español
    /// (idioma fuente del catálogo); en pantalla se usa la traducción del
    /// idioma del dispositivo.
    static let base: [(clave: String, icono: String, color: String)] = [
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

    /// Se crean solo la primera vez, en el idioma del dispositivo.
    static func sembrarSiHaceFalta(_ contexto: ModelContext) {
        limpiarDuplicados(contexto)
        let cuantas = (try? contexto.fetchCount(FetchDescriptor<Categoria>())) ?? 0
        guard cuantas == 0 else { return }
        for c in base {
            contexto.insert(Categoria(nombre: AutoCategorizador.nombreLocalizado(c.clave),
                                      icono: c.icono, colorHex: c.color,
                                      esPredeterminada: true, claveBase: c.clave))
        }
        try? contexto.save()
    }

    /// Clave canónica de un nombre de categoría: si es una categoría base en
    /// CUALQUIER idioma del bundle (p. ej. "Groceries" o "Supermercado"),
    /// devuelve su clave en español; si no, el nombre normalizado.
    private static func claveCanonica(_ nombre: String) -> String {
        let n = nombre.trimmingCharacters(in: .whitespaces)
        for c in base {
            if n == c.clave { return c.clave }
            for loc in Bundle.main.localizations {
                guard let ruta = Bundle.main.path(forResource: loc, ofType: "lproj"),
                      let b = Bundle(path: ruta) else { continue }
                if n == b.localizedString(forKey: c.clave, value: c.clave, table: nil) {
                    return c.clave
                }
            }
        }
        return n.lowercased()
    }

    /// Une categorías duplicadas y unifica el idioma de las predeterminadas.
    /// CloudKit puede duplicar el sembrado cuando el sync baja las categorías
    /// de una instalación anterior — incluso sembradas en OTRO idioma
    /// ("Supermercado" y "Groceries" son la misma). Conserva la más antigua,
    /// reasigna sus transacciones, hereda el límite si la original no tenía y
    /// renombra las base al idioma actual del dispositivo.
    static func limpiarDuplicados(_ contexto: ModelContext) {
        let cats = (try? contexto.fetch(
            FetchDescriptor<Categoria>(sortBy: [SortDescriptor(\.creadaEl)]))) ?? []
        var porClave: [String: Categoria] = [:]
        var huboCambios = false
        for cat in cats {
            let clave = claveCanonica(cat.nombre)
            if let original = porClave[clave] {
                for tx in cat.transacciones ?? [] { tx.categoria = original }
                if original.limiteMonto == nil, let limite = cat.limiteMonto {
                    original.limiteMonto = limite
                    original.periodo = cat.periodo
                    original.umbralAviso = cat.umbralAviso
                }
                contexto.delete(cat)
                huboCambios = true
            } else {
                porClave[clave] = cat
                // Categoría base: backfill de claveBase y nombre en el idioma actual.
                if base.contains(where: { $0.clave == clave }) {
                    if cat.claveBase != clave { cat.claveBase = clave; huboCambios = true }
                    let localizado = AutoCategorizador.nombreLocalizado(clave)
                    if cat.nombre != localizado {
                        cat.nombre = localizado
                        huboCambios = true
                    }
                }
            }
        }
        if huboCambios { try? contexto.save() }
    }
}

extension Tarjeta {
    /// Busca una tarjeta por nombre (sin distinguir mayúsculas/espacios) o la crea.
    /// Permite auto-registrar la tarjeta cuando llega un pago con una nueva.
    static func obtenerOCrear(nombre: String, contexto: ModelContext) -> Tarjeta? {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return nil }
        let clave = limpio.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                   locale: Locale(identifier: "es")).lowercased()
        let todas = (try? contexto.fetch(FetchDescriptor<Tarjeta>())) ?? []
        if let t = todas.first(where: {
            $0.nombre.folding(options: [.diacriticInsensitive, .caseInsensitive],
                              locale: Locale(identifier: "es")).lowercased() == clave
        }) { return t }
        let nueva = Tarjeta(nombre: limpio)
        contexto.insert(nueva)
        return nueva
    }
}
