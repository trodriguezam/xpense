import XCTest
@testable import Xpense

/// Tests de la política "ver todo, editar lo propio" del grupo compartido.
/// Lógica pura: corren en el simulador sin necesitar cuentas iCloud reales.
final class PermisosCompartirTests: XCTestCase {

    func testTodosVenElPozo() {
        XCTAssertTrue(PermisosCompartir.puedeVerPozo(rol: .dueno))
        XCTAssertTrue(PermisosCompartir.puedeVerPozo(rol: .miembro))
    }

    func testSoloElAutorEditaSuGasto() {
        XCTAssertTrue(PermisosCompartir.puedeEditarGasto(autorID: "userA", miUsuarioID: "userA"))
        XCTAssertFalse(PermisosCompartir.puedeEditarGasto(autorID: "userA", miUsuarioID: "userB"))
    }

    func testElDuenoNoEditaGastosAjenos() {
        // El rol no cambia esto: editar es por autoría, no por administración.
        XCTAssertFalse(PermisosCompartir.puedeEditarGasto(autorID: "hijo", miUsuarioID: "padre"))
    }

    func testIdsVaciosNoAutorizan() {
        XCTAssertFalse(PermisosCompartir.puedeEditarGasto(autorID: "", miUsuarioID: ""))
        XCTAssertFalse(PermisosCompartir.puedeEditarGasto(autorID: "x", miUsuarioID: ""))
    }

    func testSoloElDuenoAdministra() {
        XCTAssertTrue(PermisosCompartir.puedeAdministrarGrupo(rol: .dueno))
        XCTAssertFalse(PermisosCompartir.puedeAdministrarGrupo(rol: .miembro))
    }

    func testConfigurarTarjeta() {
        // Dueño del grupo: siempre.
        XCTAssertTrue(PermisosCompartir.puedeConfigurarTarjeta(
            rol: .dueno, duenoTarjetaID: "otro", miUsuarioID: "yo"))
        // Miembro: solo su propia tarjeta.
        XCTAssertTrue(PermisosCompartir.puedeConfigurarTarjeta(
            rol: .miembro, duenoTarjetaID: "yo", miUsuarioID: "yo"))
        XCTAssertFalse(PermisosCompartir.puedeConfigurarTarjeta(
            rol: .miembro, duenoTarjetaID: "otro", miUsuarioID: "yo"))
    }
}
