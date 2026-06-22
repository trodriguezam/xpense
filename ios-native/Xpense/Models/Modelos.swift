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
    /// Clave en español de la categoría base ("Supermercado", …) o nil si es del
    /// usuario. Identifica la categoría sin depender del nombre mostrado (idioma).
    var claveBase: String?
    var limiteMonto: Int?                     // CLP; nil = sin límite
    var periodo: String = Periodo.mensual.rawValue
    var umbralAviso: Double = 0.8             // 0 ... 1
    var creadaEl: Date = Date.now
    @Relationship(deleteRule: .nullify, inverse: \Transaccion.categoria)
    var transacciones: [Transaccion]? = []
    @Relationship(deleteRule: .cascade, inverse: \ReglaAprendida.categoria)
    var reglas: [ReglaAprendida]? = []

    init(nombre: String, icono: String, colorHex: String,
         esPredeterminada: Bool = false, claveBase: String? = nil) {
        self.nombre = nombre
        self.icono = icono
        self.colorHex = colorHex
        self.esPredeterminada = esPredeterminada
        self.claveBase = claveBase
    }

    var periodoEnum: Periodo { Periodo(rawValue: periodo) ?? .mensual }
}

/// Tarjeta de pago (débito/crédito). Cada gasto puede asociarse a una, y la
/// tarjeta puede tener un límite mensual opcional con aviso. Sincroniza por iCloud.
@Model
final class Tarjeta {
    var nombre: String = ""
    var limiteMonto: Int?                     // CLP mensual; nil = sin límite
    var umbralAviso: Double = 0.8             // 0 ... 1
    var creadaEl: Date = Date.now
    /// Si está activo, los gastos de esta tarjeta aportan al pozo del grupo por
    /// defecto. Un gasto puede sobrescribirlo solo para sí (`Transaccion.aporteAlPozo`).
    var aportaAlPozoPorDefecto: Bool = false
    /// Dueño de la tarjeta dentro de un grupo (ej. la tarjeta de un hijo que es
    /// del padre). nil = sin grupo / personal.
    var dueno: Persona?
    @Relationship(deleteRule: .nullify, inverse: \Transaccion.tarjeta)
    var transacciones: [Transaccion]? = []

    init(nombre: String) {
        self.nombre = nombre
    }
}

/// Grupo de gastos compartidos (familia, arrendatarios…). Reúne personas y un
/// "pozo común" alimentado por los gastos que aportan. Sincroniza por iCloud.
@Model
final class Grupo {
    var nombre: String = ""
    var creadoEl: Date = Date.now
    /// Enlace al espejo Core Data (`GrupoCompartidoMO`) cuando el grupo se comparte
    /// vía CKShare. nil = grupo solo local, aún no compartido.
    var idCompartido: String?
    @Relationship(deleteRule: .cascade, inverse: \Persona.grupo)
    var personas: [Persona]? = []

    init(nombre: String) {
        self.nombre = nombre
    }
}

/// Persona dentro de un grupo. Puede tener tarjetas a su nombre. `esYo` marca a
/// la persona que corresponde al usuario de este dispositivo.
@Model
final class Persona {
    var nombre: String = ""
    var esYo: Bool = false
    var creadaEl: Date = Date.now
    var grupo: Grupo?
    @Relationship(deleteRule: .nullify, inverse: \Tarjeta.dueno)
    var tarjetas: [Tarjeta]? = []

    init(nombre: String, esYo: Bool = false) {
        self.nombre = nombre
        self.esYo = esYo
    }
}

@Model
final class Transaccion {
    var monto: Int = 0                        // CLP, sin decimales
    var comercio: String = ""
    var nota: String = ""
    var fecha: Date = Date.now
    var origen: String = "manual"             // "manual" | "applepay"
    /// Sobrescribe, solo para este gasto, si aporta al pozo del grupo.
    /// nil = usar el default de la tarjeta (`Tarjeta.aportaAlPozoPorDefecto`).
    var aporteAlPozo: Bool?
    var categoria: Categoria?
    var tarjeta: Tarjeta?

    init(monto: Int, comercio: String, fecha: Date = .now, nota: String = "",
         origen: String = "manual", categoria: Categoria? = nil, tarjeta: Tarjeta? = nil,
         aporteAlPozo: Bool? = nil) {
        self.monto = monto
        self.comercio = comercio
        self.fecha = fecha
        self.nota = nota
        self.origen = origen
        self.categoria = categoria
        self.tarjeta = tarjeta
        self.aporteAlPozo = aporteAlPozo
    }
}

/// Lo que la app aprende de las clasificaciones manuales: asocia los tokens
/// significativos de un comercio (ej. "bocadas") a una categoría, para que
/// cargos similares se clasifiquen solos. Sincroniza por iCloud.
@Model
final class ReglaAprendida {
    var patron: String = ""        // tokens significativos del comercio crudo
    var nombre: String?            // alias display aprendido (ej. "Bocadas")
    var aciertos: Int = 1          // veces confirmada (desempata conflictos)
    var actualizada: Date = Date.now
    var categoria: Categoria?

    init(patron: String, categoria: Categoria?, nombre: String? = nil) {
        self.patron = patron
        self.categoria = categoria
        self.nombre = nombre
    }
}
