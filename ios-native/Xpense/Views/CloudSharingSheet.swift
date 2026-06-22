// CloudSharingSheet.swift — Fase 2c. Presentación nativa para invitar al grupo.
//
// `UICloudSharingController` NO se debe embeber en un `.sheet` de SwiftUI vía
// `UIViewControllerRepresentable`: gestiona su propia presentación y al embeberlo
// se cae (carga y cierra la app). Lo presentamos **imperativamente** desde el
// view controller superior, reteniendo el delegate (si no, se libera y crashea).
//
// CKShare solo funciona con iCloud real (no simulador): requiere 2 Apple IDs en 2
// dispositivos. Ver `docs/grupos-compartidos.md`.
import UIKit
import CloudKit
import os

enum PresentadorCompartir {
    private static let log = Logger(subsystem: "cl.trodriguezam.xpense", category: "CloudSharing")
    /// Retiene el delegate mientras la hoja está viva (UICloudSharingController solo
    /// guarda una referencia débil; sin esto, se libera y la app se cae).
    private static var delegadoVivo: Delegado?

    @MainActor
    static func presentar(share: CKShare, container: CKContainer, titulo: String) {
        guard let top = topViewController() else {
            log.error("No se encontró el view controller superior para presentar la hoja.")
            return
        }
        let delegado = Delegado(titulo: titulo)
        delegadoVivo = delegado

        let controlador = UICloudSharingController(share: share, container: container)
        controlador.delegate = delegado
        controlador.availablePermissions = [.allowReadWrite, .allowPrivate]

        // En iPad la hoja es un popover y necesita ancla o se cae.
        if let pop = controlador.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY - 40,
                                    width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        top.present(controlador, animated: true)
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let ventana = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        var top = ventana?.rootViewController
        while let presentado = top?.presentedViewController { top = presentado }
        return top
    }

    final class Delegado: NSObject, UICloudSharingControllerDelegate {
        let titulo: String
        init(titulo: String) { self.titulo = titulo }

        func itemTitle(for csc: UICloudSharingController) -> String? { titulo }

        func cloudSharingController(_ csc: UICloudSharingController,
                                    failedToSaveShareWithError error: Error) {
            PresentadorCompartir.log.error("Falló al guardar el share: \(error.localizedDescription, privacy: .public)")
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            PresentadorCompartir.log.info("Share guardado / participantes actualizados.")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            PresentadorCompartir.log.info("Se dejó de compartir el grupo.")
        }
    }
}
