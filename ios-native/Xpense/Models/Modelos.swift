// Modelos.swift — SwiftData con sync iCloud (CloudKit).
// Regla CloudKit: todo atributo con valor por defecto u opcional; relaciones opcionales; sin .unique.
import Foundation
import SwiftData

enum Periodo: String, CaseIterable, Identifiable {
    case semanal, mensual
    var id: String { rawValue }
    var etiqueta: String {
        self == .semanal ? String(localized: "Semanal") : String(localized: "Mensual")
    }
}

@Model
final class Categoria {
    var nombre: String = ""
    var icono: String = "leaf.fill"          // SF Symbol
    var colorHex: String = "#5E7561"
    var esPredeterminada: Bool = false
    var limiteMonto: Int?                     // CLP; nil = sin límite
    var periodo: String = Periodo.mensual.rawValue
    var umbralAviso: Double = 0.8             // 0.5 ... 0.95
    var creadaEl: Date = Date.now
    @Relationship(deleteRule: .nullify, inverse: \Transaccion.categoria)
    var transacciones: [Transaccion]? = []

    init(nombre: String, icono: String, colorHex: String, esPredeterminada: Bool = false) {
        self.nombre = nombre
        self.icono = icono
        self.colorHex = colorHex
        self.esPredeterminada = esPredeterminada
    }

    var periodoEnum: Periodo { Periodo(rawValue: periodo) ?? .mensual }
}

@Model
final class Transaccion {
    var monto: Int = 0                        // CLP, sin decimales
    var comercio: String = ""
    var nota: String = ""
    var fecha: Date = Date.now
    var origen: String = "manual"             // "manual" | "applepay"
    var categoria: Categoria?

    init(monto: Int, comercio: String, fecha: Date = .now, nota: String = "",
         origen: String = "manual", categoria: Categoria? = nil) {
        self.monto = monto
        self.comercio = comercio
        self.fecha = fecha
        self.nota = nota
        self.origen = origen
        self.categoria = categoria
    }
}
