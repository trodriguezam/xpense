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

    /// Resuelve la categoría de una regla base por su clave canónica (en español),
    /// independiente del idioma del nombre mostrado. Fallback al nombre traducido.
    static func categoria(clave: String, entre categorias: [Categoria]) -> Categoria? {
        if let c = categorias.first(where: { $0.claveBase == clave }) { return c }
        let objetivo = nombreLocalizado(clave)
        return categorias.first(where: { $0.nombre == objetivo })
    }

    /// Reglas base por palabra clave del comercio. Las claves de una palabra
    /// se comparan por token (evita falsos positivos dentro de otra palabra);
    /// las frases se comparan por contención.
    static func sugerir(comercio: String, entre categorias: [Categoria]) -> Categoria? {
        let texto = normalizar(comercio)
        guard !texto.isEmpty else { return nil }
        let toks = tokens(comercio)
        for (clave, nombre) in reglas {
            let match = clave.contains(" ")
                ? texto.contains(clave)
                : toks.contains { coinciden($0, clave) }
            if match, let c = categoria(clave: nombre, entre: categorias) { return c }
        }
        return nil
    }

    // MARK: - Aprendizaje de clasificaciones manuales

    /// Sufijos societarios y palabras genéricas que no identifican al comercio.
    private static let vacias: Set<String> = [
        "spa", "sa", "ltda", "ltd", "eirl", "cia", "limitada", "sociedad",
        "comercial", "comercializadora", "inversiones", "servicios", "empresa",
        "store", "tienda", "shop", "the", "and", "del", "los", "las", "don",
        "doña", "dona", "chile",
    ]

    /// Tokens significativos de un comercio: minúsculas, sin tildes, sin prefijo
    /// de procesador, sin números/símbolos, sin palabras genéricas. Es la huella
    /// que permite reconocer cargos "similares" (otra sucursal, otro formato).
    /// Para comercios crípticos cortos (ej. "Sb 761") cae a tokens de 2 letras.
    static func tokens(_ comercio: String) -> [String] {
        let base = normalizar(comercio)
        let soloLetras = String(base.unicodeScalars.map {
            CharacterSet.letters.contains($0) ? Character($0) : " "
        })
        let palabras = soloLetras.split(separator: " ").map(String.init)
            .filter { !vacias.contains($0) }
        let largas = palabras.filter { $0.count >= 3 }
        return largas.isEmpty ? palabras.filter { $0.count >= 2 } : largas
    }

    /// Aprende (o corrige) la categoría y/o el alias para los tokens del comercio
    /// CRUDO. `nombreDisplay` es el nombre legible que el usuario le puso (alias);
    /// se guarda solo si difiere del comercio crudo.
    static func aprender(comercio: String, nombreDisplay: String? = nil,
                         categoria: Categoria?, contexto: ModelContext) {
        let toks = tokens(comercio)
        guard !toks.isEmpty else { return }
        let patron = toks.joined(separator: " ")
        let alias: String? = {
            guard let n = nombreDisplay?.trimmingCharacters(in: .whitespaces), !n.isEmpty,
                  normalizar(n) != normalizar(comercio) else { return nil }
            return n
        }()
        let reglas = (try? contexto.fetch(FetchDescriptor<ReglaAprendida>())) ?? []
        if let r = reglas.first(where: { $0.patron == patron }) {
            if let categoria {
                if r.categoria?.persistentModelID == categoria.persistentModelID {
                    r.aciertos += 1
                } else {
                    r.categoria = categoria      // el usuario corrigió: gana lo nuevo
                    r.aciertos = 1
                }
            }
            if let alias { r.nombre = alias }
            r.actualizada = .now
        } else {
            guard categoria != nil || alias != nil else { return }
            contexto.insert(ReglaAprendida(patron: patron, categoria: categoria, nombre: alias))
        }
        try? contexto.save()
    }

    /// Largo del prefijo común entre dos tokens.
    private static func prefijoComun(_ a: String, _ b: String) -> Int {
        zip(a, b).prefix(while: { $0 == $1 }).count
    }

    /// Dos tokens son el mismo comercio si son iguales, o comparten un prefijo
    /// común largo (≥5 y ≥75% del más corto). Así "bocadas"≈"bocadaspa" pero
    /// "boca"≉"bocadaspa" (prefijo 4) y "kine" no se cuela dentro de otra palabra.
    private static func coinciden(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        guard a.count >= 4, b.count >= 4 else { return false }
        let p = prefijoComun(a, b)
        return p >= max(5, Int(ceil(0.75 * Double(min(a.count, b.count)))))
    }

    /// Mejor regla aprendida para el comercio: debe compartir ≥1 token distintivo
    /// (vía `coinciden`, que ya exige prefijo común largo o igualdad). El token
    /// compartido protege contra falsos positivos; gana la de más tokens en común
    /// (luego aciertos, luego recencia). Las palabras genéricas se filtran antes.
    private static func mejorRegla(comercio: String, contexto: ModelContext) -> ReglaAprendida? {
        let toks = tokens(comercio)
        guard !toks.isEmpty else { return nil }
        let reglas = (try? contexto.fetch(FetchDescriptor<ReglaAprendida>())) ?? []
        var mejor: (r: ReglaAprendida, comunes: Int)?
        for r in reglas {
            let rtoks = r.patron.split(separator: " ").map(String.init)
            guard !rtoks.isEmpty else { continue }
            let comunes = toks.filter { c in rtoks.contains { coinciden(c, $0) } }.count
            guard comunes > 0 else { continue }
            if let m = mejor {
                if comunes > m.comunes
                    || (comunes == m.comunes && r.aciertos > m.r.aciertos)
                    || (comunes == m.comunes && r.aciertos == m.r.aciertos && r.actualizada > m.r.actualizada) {
                    mejor = (r, comunes)
                }
            } else {
                mejor = (r, comunes)
            }
        }
        return mejor?.r
    }

    /// Sugerencia completa: categoría (aprendida o regla base) + alias de nombre.
    static func sugerencia(comercio: String, entre categorias: [Categoria],
                           contexto: ModelContext) -> (categoria: Categoria?, nombre: String?) {
        if let r = mejorRegla(comercio: comercio, contexto: contexto) {
            return (r.categoria ?? sugerir(comercio: comercio, entre: categorias), r.nombre)
        }
        return (sugerir(comercio: comercio, entre: categorias), nil)
    }

    /// Solo la categoría sugerida (para el formulario manual).
    static func clasificar(comercio: String, entre categorias: [Categoria],
                           contexto: ModelContext) -> Categoria? {
        sugerencia(comercio: comercio, entre: categorias, contexto: contexto).categoria
    }
}
