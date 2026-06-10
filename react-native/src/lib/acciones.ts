// Toda mutación pasa por aquí: BD -> avisos -> widget -> refresco de UI.
import { db, Periodo, categorias } from "./db";
import { estados } from "./presupuesto";
import { evaluarAviso } from "./avisos";
import { actualizarWidget } from "./widget";
import { sugerirCategoria } from "./categorizador";
import { emitir } from "./store";

async function trasCambio() {
  for (const e of estados()) await evaluarAviso(e);
  await actualizarWidget();
  emitir();
}

export async function agregarTransaccion(t: {
  monto: number; comercio: string; nota?: string;
  fecha?: Date; origen?: "manual" | "applepay"; categoriaId: number | null;
}) {
  db.runSync(
    "INSERT INTO transacciones (monto, comercio, nota, fecha, origen, categoriaId) VALUES (?,?,?,?,?,?)",
    [t.monto, t.comercio, t.nota ?? "", (t.fecha ?? new Date()).toISOString(),
     t.origen ?? "manual", t.categoriaId]
  );
  await trasCambio();
}

/** Punto de entrada del deep link xpense://agregar?monto=..&comercio=.. (Atajos). */
export async function agregarDesdeApplePay(monto: number, comercio: string) {
  const cats = categorias();
  const cat = sugerirCategoria(comercio, cats) ?? cats.find((c) => c.nombre === "Otros") ?? null;
  await agregarTransaccion({
    monto, comercio: comercio || "Apple Pay", origen: "applepay",
    categoriaId: cat?.id ?? null,
  });
  return cat?.nombre ?? "Otros";
}

export async function eliminarTransaccion(id: number) {
  db.runSync("DELETE FROM transacciones WHERE id = ?", [id]);
  await trasCambio();
}

export async function crearCategoria(nombre: string, icono: string, colorHex: string) {
  db.runSync("INSERT INTO categorias (nombre, icono, colorHex) VALUES (?,?,?)",
    [nombre, icono, colorHex]);
  await trasCambio();
}

export async function eliminarCategoria(id: number) {
  db.runSync("DELETE FROM categorias WHERE id = ? AND esPredeterminada = 0", [id]);
  await trasCambio();
}

export async function actualizarLimite(
  id: number, limiteMonto: number | null, periodo: Periodo, umbralAviso: number
) {
  db.runSync(
    "UPDATE categorias SET limiteMonto = ?, periodo = ?, umbralAviso = ? WHERE id = ?",
    [limiteMonto, periodo, umbralAviso, id]
  );
  await trasCambio();
}
