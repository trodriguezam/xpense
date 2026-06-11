// Shared.swift — código compartido entre la app y el widget (vía App Group).
import SwiftUI
import UIKit

enum Compartido {
    /// Debe calzar con los entitlements de ambos targets.
    static let appGroup = "group.cl.trodriguezam.xpense"
    static let claveSnapshot = "widget_snapshot"
}

// MARK: - Paleta "mañana en el sur"
extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red:   CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8)  & 0xFF) / 255,
                  blue:  CGFloat(v & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    init(hex: String) { self.init(uiColor: UIColor(hex: hex)) }

    /// Color que se resuelve solo según el modo (claro/oscuro) del sistema,
    /// para que toda la app —y el widget— sea coherente en ambos.
    init(claro: String, oscuro: String) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? oscuro : claro)
        })
    }
}

enum Paleta {
    // Cada color tiene su variante de día y de noche, conservando la identidad
    // "mañana en el sur" (bruma, arena, musgo, cobre).
    static let bruma      = Color(claro: "#F6F4EE", oscuro: "#161A15")   // fondo
    static let arena      = Color(claro: "#E7E0D2", oscuro: "#2B312B")   // superficies suaves / pistas
    static let superficie = Color(claro: "#FFFFFF", oscuro: "#1F241E")   // tarjetas y filas
    static let musgo      = Color(claro: "#5E7561", oscuro: "#8FAE91")   // primario
    static let salvia     = Color(claro: "#A9BFA8", oscuro: "#7E997E")   // secundario
    static let corteza    = Color(claro: "#2F3A2E", oscuro: "#ECEFE8")   // texto
    static let piedra     = Color(claro: "#7C8577", oscuro: "#9BA89A")   // texto secundario
    static let cobre      = Color(claro: "#B5704F", oscuro: "#CB8866")   // "cerca del límite"
    static let teja       = Color(claro: "#9C4F35", oscuro: "#C76A4B")   // "límite superado" (cálido, no rojo)
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
