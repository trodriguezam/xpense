// SnapshotWidget.swift — la app escribe el resumen que el widget dibuja.
import Foundation
import SwiftData
import WidgetKit

enum SnapshotWidget {
    static func escribir(contexto: ModelContext) {
        let estados = MotorPresupuesto.estados(contexto: contexto)
        // Primero las categorías con límite (orden: más llenas arriba); luego top gasto.
        let conLimite = estados.filter { $0.nivel != .sinLimite }.sorted { $0.fraccion > $1.fraccion }
        let sinLimite = estados.filter { $0.nivel == .sinLimite && $0.gastado > 0 }
                               .sorted { $0.gastado > $1.gastado }
        let items = (conLimite + sinLimite).prefix(6).map {
            ItemSnapshot(nombre: $0.categoria.nombre,
                         icono: $0.categoria.icono,
                         colorHex: $0.categoria.colorHex,
                         gastado: $0.gastado,
                         limite: $0.categoria.limiteMonto,
                         fraccion: $0.fraccion)
        }
        let snap = Snapshot(actualizadoEl: .now,
                            totalMes: MotorPresupuesto.totalMes(contexto: contexto),
                            mensaje: MotorPresupuesto.mensajeGeneral(estados),
                            items: Array(items))
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(snap), let json = String(data: data, encoding: .utf8) {
            UserDefaults(suiteName: Compartido.appGroup)?.set(json, forKey: Compartido.claveSnapshot)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Llamar después de cualquier cambio en datos.
    static func trasCambio(contexto: ModelContext) {
        try? contexto.save()
        for e in MotorPresupuesto.estados(contexto: contexto) { Avisos.evaluar(e) }
        for e in MotorPresupuesto.estadosTarjetas(contexto: contexto) { Avisos.evaluar(e) }
        escribir(contexto: contexto)
    }
}
