// AutoCategorizador.swift — sugiere categoría según el nombre del comercio (Chile).
import Foundation
import SwiftData

enum AutoCategorizador {

    /// Prefijos que agregan los procesadores de pago delante del nombre real
    /// del comercio (ej: "Mercadopago*bocadaspa" → "bocadaspa").
    private static let prefijosProcesadores = [
        "mercadopago*", "mercado pago*", "mercadopago ", "mp*",
        "sumup*", "sum up*", "dlocal*", "payu*", "flow*",
        "transbank*", "getnet*", "klap*", "redelcom*", "tuu*",
    ]

    /// Normaliza para comparar: minúsculas, sin tildes/ñ y sin prefijo de procesador.
    static func normalizar(_ texto: String) -> String {
        var t = texto
            .folding(options: [.diacriticInsensitive, .caseInsensitive],
                     locale: Locale(identifier: "es"))
            .lowercased()
        for prefijo in prefijosProcesadores where t.hasPrefix(prefijo) {
            t = String(t.dropFirst(prefijo.count))
            break
        }
        return t.trimmingCharacters(in: .whitespaces)
    }

    // palabra clave (normalizada: minúsculas, sin tildes) -> nombre de categoría base
    static let reglas: [(String, String)] = [
        ("jumbo", "Supermercado"), ("lider", "Supermercado"),
        ("unimarc", "Supermercado"), ("tottus", "Supermercado"), ("santa isabel", "Supermercado"),
        ("acuenta", "Supermercado"), ("ok market", "Supermercado"), ("alvi", "Supermercado"),
        ("supermercado", "Supermercado"),
        ("starbucks", "Restaurantes y café"), ("juan valdez", "Restaurantes y café"),
        ("mcdonald", "Restaurantes y café"), ("burger", "Restaurantes y café"),
        ("doggis", "Restaurantes y café"), ("telepizza", "Restaurantes y café"),
        ("papa john", "Restaurantes y café"), ("domino", "Restaurantes y café"),
        ("castano", "Restaurantes y café"), ("rappi", "Restaurantes y café"),
        ("pedidosya", "Restaurantes y café"), ("uber eats", "Restaurantes y café"),
        ("restaurant", "Restaurantes y café"), ("resto", "Restaurantes y café"),
        ("cafe", "Restaurantes y café"), ("caffe", "Restaurantes y café"),
        ("coffee", "Restaurantes y café"), ("cafeteria", "Restaurantes y café"),
        ("panaderia", "Restaurantes y café"), ("pasteleria", "Restaurantes y café"),
        ("sushi", "Restaurantes y café"), ("pizzeria", "Restaurantes y café"),
        ("uber", "Transporte"), ("didi", "Transporte"), ("cabify", "Transporte"),
        ("metro", "Transporte"), ("bip", "Transporte"), ("red movilidad", "Transporte"),
        ("turbus", "Transporte"), ("pullman", "Transporte"),
        ("autopista", "Transporte"), ("tag ", "Transporte"),
        ("copec", "Bencina"), ("shell", "Bencina"), ("petrobras", "Bencina"),
        ("aramco", "Bencina"), ("enex", "Bencina"), ("terpel", "Bencina"),
        ("enel", "Cuentas y servicios"), ("cge", "Cuentas y servicios"),
        ("aguas andinas", "Cuentas y servicios"), ("esval", "Cuentas y servicios"),
        ("metrogas", "Cuentas y servicios"), ("lipigas", "Cuentas y servicios"),
        ("abastible", "Cuentas y servicios"), ("gasco", "Cuentas y servicios"),
        ("movistar", "Cuentas y servicios"), ("entel", "Cuentas y servicios"),
        ("claro", "Cuentas y servicios"), ("wom", "Cuentas y servicios"),
        ("vtr", "Cuentas y servicios"), ("gtd", "Cuentas y servicios"),
        ("cruz verde", "Salud"), ("salcobrand", "Salud"), ("ahumada", "Salud"),
        ("farmacia", "Salud"), ("clinica", "Salud"),
        ("isapre", "Salud"), ("redsalud", "Salud"), ("integramedica", "Salud"),
        ("netflix", "Entretenimiento"), ("spotify", "Entretenimiento"),
        ("disney", "Entretenimiento"), ("hbo", "Entretenimiento"),
        ("cinemark", "Entretenimiento"), ("cineplanet", "Entretenimiento"),
        ("cine hoyts", "Entretenimiento"), ("steam", "Entretenimiento"),
        ("playstation", "Entretenimiento"), ("nintendo", "Entretenimiento"),
        ("xbox", "Entretenimiento"), ("youtube", "Entretenimiento"),
        ("falabella", "Compras"), ("paris", "Compras"), ("ripley", "Compras"),
        ("hites", "Compras"), ("la polar", "Compras"), ("mercado libre", "Compras"),
        ("mercadolibre", "Compras"), ("aliexpress", "Compras"), ("shein", "Compras"),
        ("temu", "Compras"), ("h&m", "Compras"), ("zara", "Compras"),
        ("sodimac", "Hogar"), ("easy", "Hogar"), ("construmart", "Hogar"),
        ("imperial", "Hogar"), ("ikea", "Hogar"), ("casaideas", "Hogar"),
    ]

    /// Las reglas referencian los nombres en español (la clave del catálogo);
    /// en otro idioma las categorías se sembraron con el nombre traducido.
    static func nombreLocalizado(_ nombre: String) -> String {
        String(localized: String.LocalizationValue(nombre))
    }

    static func sugerir(comercio: String, entre categorias: [Categoria]) -> Categoria? {
        let texto = normalizar(comercio)
        guard !texto.isEmpty else { return nil }
        for (clave, nombre) in reglas where texto.contains(clave) {
            let objetivo = nombreLocalizado(nombre)
            if let c = categorias.first(where: { $0.nombre == objetivo }) { return c }
        }
        return nil
    }

    /// Categoría que el usuario usó la última vez en este mismo comercio.
    /// Así la app aprende de las correcciones manuales: basta arreglar una
    /// compra de "Mercadopago*bocadaspa" una vez para que las siguientes
    /// queden bien solas.
    static func categoriaPrevia(comercio: String, contexto: ModelContext) -> Categoria? {
        let objetivo = normalizar(comercio)
        guard !objetivo.isEmpty else { return nil }
        var desc = FetchDescriptor<Transaccion>(sortBy: [SortDescriptor(\.fecha, order: .reverse)])
        desc.fetchLimit = 500
        let txs = (try? contexto.fetch(desc)) ?? []
        return txs.first { normalizar($0.comercio) == objetivo && $0.categoria != nil }?.categoria
    }
}
