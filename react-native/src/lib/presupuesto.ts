// Gasto por categoría dentro de su periodo (semana chilena: parte el lunes).
import { Categoria, Periodo, Transaccion, transaccionesEntre, categorias } from "./db";

export type Nivel = 0 | 1 | 2 | 3; // sinLimite | conCalma | cerca | superado

export interface Estado {
  categoria: Categoria;
  gastado: number;
  fraccion: number;
  nivel: Nivel;
}

export function rango(periodo: Periodo, ref = new Date()): [Date, Date] {
  if (periodo === "mensual") {
    const ini = new Date(ref.getFullYear(), ref.getMonth(), 1);
    const fin = new Date(ref.getFullYear(), ref.getMonth() + 1, 1);
    return [ini, fin];
  }
  const d = new Date(ref);
  const dia = (d.getDay() + 6) % 7; // lunes = 0
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - dia);
  const fin = new Date(d);
  fin.setDate(fin.getDate() + 7);
  return [d, fin];
}

export function clavePeriodo(periodo: Periodo, ref = new Date()): string {
  if (periodo === "mensual")
    return `m-${ref.getFullYear()}-${String(ref.getMonth() + 1).padStart(2, "0")}`;
  const [ini] = rango("semanal", ref);
  return `s-${ini.toISOString().slice(0, 10)}`; // semana identificada por su lunes
}

const iso = (d: Date) => d.toISOString();

export function gastadoDe(cat: Categoria, ref = new Date()): number {
  const [ini, fin] = rango(cat.periodo, ref);
  return transaccionesEntre(iso(ini), iso(fin))
    .filter((t) => t.categoriaId === cat.id)
    .reduce((s, t) => s + t.monto, 0);
}

export function estadoDe(cat: Categoria): Estado {
  const gastado = gastadoDe(cat);
  if (!cat.limiteMonto || cat.limiteMonto <= 0)
    return { categoria: cat, gastado, fraccion: 0, nivel: 0 };
  const fraccion = gastado / cat.limiteMonto;
  const nivel: Nivel = fraccion >= 1 ? 3 : fraccion >= cat.umbralAviso ? 2 : 1;
  return { categoria: cat, gastado, fraccion, nivel };
}

export const estados = (): Estado[] => categorias().map(estadoDe);

export function totalMes(): number {
  const [ini, fin] = rango("mensual");
  return transaccionesEntre(iso(ini), iso(fin)).reduce((s, t) => s + t.monto, 0);
}

export function mensajeGeneral(es: Estado[]): string {
  if (es.some((e) => e.nivel === 3)) return "Un límite se pasó — sin drama, mañana es otro día.";
  if (es.some((e) => e.nivel === 2)) return "Atento por aquí: hay categorías cerca de su límite.";
  return "Vas con calma este mes.";
}

export function transaccionesDePeriodo(cat: Categoria): Transaccion[] {
  const [ini, fin] = rango(cat.periodo);
  return transaccionesEntre(iso(ini), iso(fin)).filter((t) => t.categoriaId === cat.id);
}
