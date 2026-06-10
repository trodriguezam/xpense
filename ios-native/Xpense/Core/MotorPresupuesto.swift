// MotorPresupuesto.swift — gasto por categoría dentro de su periodo, y nivel de alerta.
import Foundation
import SwiftData

enum Nivel: Int {
    case sinLimite = 0, conCalma = 1, cerca = 2, superado = 3
}

struct EstadoCategoria: Identifiable {
    let categoria: Categoria
    let gastado: Int
    let fraccion: Double      // 0 si no hay límite
    let nivel: Nivel
    var id: PersistentIdentifier { categoria.persistentModelID }
}

enum MotorPresupuesto {

    /// Semana chilena: parte el lunes.
    static var calendario: Calendar = {
        var c = Calendar(identifier: .iso8601)
        c.locale = Locale(identifier: "es_CL")
        c.firstWeekday = 2
        return c
    }()

    static func rango(_ periodo: Periodo, ref: Date = .now) -> (inicio: Date, fin: Date) {
        switch periodo {
        case .mensual:
            let inicio = calendario.dateInterval(of: .month, for: ref)!.start
            let fin = calendario.date(byAdding: .month, value: 1, to: inicio)!
            return (inicio, fin)
        case .semanal:
            let inicio = calendario.dateInterval(of: .weekOfYear, for: ref)!.start
            let fin = calendario.date(byAdding: .day, value: 7, to: inicio)!
            return (inicio, fin)
        }
    }

    /// Identificador del periodo actual (para no repetir avisos): "m-2026-06" o "s-2026-W24".
    static func clavePeriodo(_ periodo: Periodo, ref: Date = .now) -> String {
        let comp = calendario.dateComponents([.year, .month, .weekOfYear, .yearForWeekOfYear], from: ref)
        switch periodo {
        case .mensual: return String(format: "m-%04d-%02d", comp.year ?? 0, comp.month ?? 0)
        case .semanal: return String(format: "s-%04d-W%02d", comp.yearForWeekOfYear ?? 0, comp.weekOfYear ?? 0)
        }
    }

    static func transacciones(en rango: (inicio: Date, fin: Date), contexto: ModelContext) -> [Transaccion] {
        let (ini, fin) = rango
        let pred = #Predicate<Transaccion> { $0.fecha >= ini && $0.fecha < fin }
        let desc = FetchDescriptor<Transaccion>(predicate: pred, sortBy: [SortDescriptor(\.fecha, order: .reverse)])
        return (try? contexto.fetch(desc)) ?? []
    }

    static func gastado(_ categoria: Categoria, contexto: ModelContext, ref: Date = .now) -> Int {
        let txs = transacciones(en: rango(categoria.periodoEnum, ref: ref), contexto: contexto)
        return txs.filter { $0.categoria?.persistentModelID == categoria.persistentModelID }
                  .reduce(0) { $0 + $1.monto }
    }

    static func estado(_ categoria: Categoria, contexto: ModelContext) -> EstadoCategoria {
        let g = gastado(categoria, contexto: contexto)
        guard let limite = categoria.limiteMonto, limite > 0 else {
            return EstadoCategoria(categoria: categoria, gastado: g, fraccion: 0, nivel: .sinLimite)
        }
        let f = Double(g) / Double(limite)
        let nivel: Nivel = f >= 1.0 ? .superado : (f >= categoria.umbralAviso ? .cerca : .conCalma)
        return EstadoCategoria(categoria: categoria, gastado: g, fraccion: f, nivel: nivel)
    }

    static func estados(contexto: ModelContext) -> [EstadoCategoria] {
        let cats = (try? contexto.fetch(FetchDescriptor<Categoria>(sortBy: [SortDescriptor(\.nombre)]))) ?? []
        return cats.map { estado($0, contexto: contexto) }
    }

    static func totalMes(contexto: ModelContext) -> Int {
        transacciones(en: rango(.mensual), contexto: contexto).reduce(0) { $0 + $1.monto }
    }

    static func mensajeGeneral(_ estados: [EstadoCategoria]) -> String {
        if estados.contains(where: { $0.nivel == .superado }) { return "Un límite se pasó — sin drama, mañana es otro día." }
        if estados.contains(where: { $0.nivel == .cerca })    { return "Atento por aquí: hay categorías cerca de su límite." }
        return "Vas con calma este mes."
    }
}
