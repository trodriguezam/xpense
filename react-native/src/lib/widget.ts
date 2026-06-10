// Escribe el snapshot que dibuja el widget (Swift) vía App Group.
// En Expo Go no existe el módulo nativo: se ignora silenciosamente.
import { APP_GROUP } from "../theme";
import { estados, totalMes, mensajeGeneral } from "./presupuesto";

export async function actualizarWidget() {
  try {
    const { ExtensionStorage } = await import("@bacons/apple-targets");
    const es = estados();
    const conLimite = es.filter((e) => e.nivel > 0).sort((a, b) => b.fraccion - a.fraccion);
    const sinLimite = es
      .filter((e) => e.nivel === 0 && e.gastado > 0)
      .sort((a, b) => b.gastado - a.gastado);
    const items = [...conLimite, ...sinLimite].slice(0, 6).map((e) => ({
      nombre: e.categoria.nombre,
      colorHex: e.categoria.colorHex,
      gastado: e.gastado,
      limite: e.categoria.limiteMonto,
      fraccion: e.fraccion,
    }));
    const storage = new ExtensionStorage(APP_GROUP);
    storage.set(
      "widget_snapshot",
      JSON.stringify({
        actualizadoEl: new Date().toISOString(),
        totalMes: totalMes(),
        mensaje: mensajeGeneral(es),
        items,
      })
    );
    ExtensionStorage.reloadWidget();
  } catch {
    // Expo Go o Android: sin widget, no pasa nada.
  }
}
