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

struct EstadoTarjeta: Identifiable {
    let tarjeta: Tarjeta
    let gastado: Int
    let fraccion: Double      // 0 si no hay límite
    let nivel: Nivel
    var id: PersistentIdentifier { tarjeta.persistentModelID }
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
        // g > 0 evita avisar "cerca" sin haber gastado nada cuando el umbral es 0 %.
        let nivel: Nivel = f >= 1.0 ? .superado : (f >= categoria.umbralAviso && g > 0 ? .cerca : .conCalma)
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
        if estados.contains(where: { $0.nivel == .superado }) {
            return String(localized: "Un límite se pasó — sin drama, mañana es otro día.")
        }
        if estados.contains(where: { $0.nivel == .cerca }) {
            return String(localized: "Atento por aquí: hay categorías cerca de su límite.")
        }
        return String(localized: "Vas con calma este mes.")
    }

    // MARK: - Tarjetas (límite siempre mensual)

    static func gastadoTarjeta(_ tarjeta: Tarjeta, contexto: ModelContext, ref: Date = .now) -> Int {
        let txs = transacciones(en: rango(.mensual, ref: ref), contexto: contexto)
        return txs.filter { $0.tarjeta?.persistentModelID == tarjeta.persistentModelID }
                  .reduce(0) { $0 + $1.monto }
    }

    static func estadoTarjeta(_ tarjeta: Tarjeta, contexto: ModelContext) -> EstadoTarjeta {
        let g = gastadoTarjeta(tarjeta, contexto: contexto)
        guard let limite = tarjeta.limiteMonto, limite > 0 else {
            return EstadoTarjeta(tarjeta: tarjeta, gastado: g, fraccion: 0, nivel: .sinLimite)
        }
        let f = Double(g) / Double(limite)
        let nivel: Nivel = f >= 1.0 ? .superado : (f >= tarjeta.umbralAviso && g > 0 ? .cerca : .conCalma)
        return EstadoTarjeta(tarjeta: tarjeta, gastado: g, fraccion: f, nivel: nivel)
    }

    static func estadosTarjetas(contexto: ModelContext) -> [EstadoTarjeta] {
        let ts = (try? contexto.fetch(FetchDescriptor<Tarjeta>(sortBy: [SortDescriptor(\.nombre)]))) ?? []
        return ts.map { estadoTarjeta($0, contexto: contexto) }
    }

    // MARK: - Grupos / pozo común (siempre mensual)

    /// ¿Este gasto aporta al pozo? El gasto manda (override); si no, decide la tarjeta.
    static func aportaAlPozo(_ tx: Transaccion) -> Bool {
        tx.aporteAlPozo ?? (tx.tarjeta?.aportaAlPozoPorDefecto ?? false)
    }

    /// Aporte de una persona al pozo del grupo este mes (gastos de sus tarjetas que aportan).
    static func aportePersona(_ persona: Persona, contexto: ModelContext, ref: Date = .now) -> Int {
        let txs = transacciones(en: rango(.mensual, ref: ref), contexto: contexto)
        return txs.filter { tx in
            tx.tarjeta?.dueno?.persistentModelID == persona.persistentModelID && aportaAlPozo(tx)
        }.reduce(0) { $0 + $1.monto }
    }

    /// Resumen del pozo del grupo: total del mes y aporte por persona (de mayor a menor).
    static func pozo(_ grupo: Grupo, contexto: ModelContext, ref: Date = .now)
        -> (total: Int, porPersona: [(persona: Persona, aporte: Int)]) {
        let personas = grupo.personas ?? []
        let aportes = personas.map { (persona: $0, aporte: aportePersona($0, contexto: contexto, ref: ref)) }
            .sorted { $0.aporte > $1.aporte }
        return (aportes.reduce(0) { $0 + $1.aporte }, aportes)
    }
}
