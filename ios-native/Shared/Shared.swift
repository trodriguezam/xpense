// Shared.swift — código compartido entre la app y el widget (vía App Group).
import SwiftUI

enum Compartido {
    /// Debe calzar con los entitlements de ambos targets.
    static let appGroup = "group.cl.trodriguezam.xpense"
    static let claveSnapshot = "widget_snapshot"
}

// MARK: - Paleta "mañana en el sur"
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red:   Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8)  & 0xFF) / 255,
                  blue:  Double(v & 0xFF) / 255)
    }
}

enum Paleta {
    static let bruma    = Color(hex: "#F6F4EE")   // fondo
    static let arena    = Color(hex: "#E7E0D2")   // superficies suaves
    static let musgo    = Color(hex: "#5E7561")   // primario
    static let salvia   = Color(hex: "#A9BFA8")   // secundario
    static let corteza  = Color(hex: "#2F3A2E")   // texto
    static let piedra   = Color(hex: "#7C8577")   // texto secundario
    static let cobre    = Color(hex: "#B5704F")   // "cerca del límite"
    static let teja     = Color(hex: "#9C4F35")   // "límite superado" (cálido, no rojo)
}

// MARK: - Snapshot que la app escribe y el widget lee
struct ItemSnapshot: Codable, Identifiable {
    var id: String { nombre }
    let nombre: String
    let icono: String        // SF Symbol
    let colorHex: String
    let gastado: Int         // CLP
    let limite: Int?         // nil = sin límite
    let fraccion: Double     // gastado / límite (0 si no hay límite)
}

struct Snapshot: Codable {
    let actualizadoEl: Date
    let totalMes: Int
    let mensaje: String
    let items: [ItemSnapshot]

    static func leer() -> Snapshot? {
        guard let json = UserDefaults(suiteName: Compartido.appGroup)?
                .string(forKey: Compartido.claveSnapshot),
              let data = json.data(using: .utf8) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(Snapshot.self, from: data)
    }
}

// MARK: - Formato CLP
func clp(_ monto: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = Locale(identifier: "es_CL")
    f.maximumFractionDigits = 0
    return f.string(from: NSNumber(value: monto)) ?? "$\(monto)"
}
