// Persistencia.swift — contenedor SwiftData en el App Group, con CloudKit.
import Foundation
import SwiftData

enum Persistencia {
    static let contenedor: ModelContainer = {
        let esquema = Schema([Categoria.self, Transaccion.self])
        let config = ModelConfiguration(
            schema: esquema,
            groupContainer: .identifier(Compartido.appGroup),
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: esquema, configurations: [config])
        } catch {
            fatalError("No se pudo crear el contenedor de datos: \(error)")
        }
    }()

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
