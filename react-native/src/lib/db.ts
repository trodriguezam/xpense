import * as SQLite from "expo-sqlite";

export type Periodo = "semanal" | "mensual";

export interface Categoria {
  id: number;
  nombre: string;
  icono: string;          // nombre de ícono Ionicons
  colorHex: string;
  esPredeterminada: number;
  limiteMonto: number | null;
  periodo: Periodo;
  umbralAviso: number;    // 0.5 ... 0.95
}

export interface Transaccion {
  id: number;
  monto: number;          // CLP sin decimales
  comercio: string;
  nota: string;
  fecha: string;          // ISO
  origen: "manual" | "applepay";
  categoriaId: number | null;
}

export const db = SQLite.openDatabaseSync("xpense.db");

const BASE: Array<[string, string, string]> = [
  ["Supermercado", "cart", "#5E7561"],
  ["Restaurantes y café", "cafe", "#8A6E4B"],
  ["Transporte", "bus", "#6E8B8F"],
  ["Bencina", "speedometer", "#7C8577"],
  ["Cuentas y servicios", "flash", "#B5704F"],
  ["Salud", "medkit", "#A9BFA8"],
  ["Entretenimiento", "film", "#9C7B9E"],
  ["Compras", "bag-handle", "#C2A36B"],
  ["Hogar", "home", "#8FA08A"],
  ["Otros", "leaf", "#2F3A2E"],
];

export function migrar() {
  db.execSync(`
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS categorias (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      icono TEXT NOT NULL DEFAULT 'leaf',
      colorHex TEXT NOT NULL DEFAULT '#5E7561',
      esPredeterminada INTEGER NOT NULL DEFAULT 0,
      limiteMonto INTEGER,
      periodo TEXT NOT NULL DEFAULT 'mensual',
      umbralAviso REAL NOT NULL DEFAULT 0.8
    );
    CREATE TABLE IF NOT EXISTS transacciones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      monto INTEGER NOT NULL,
      comercio TEXT NOT NULL DEFAULT '',
      nota TEXT NOT NULL DEFAULT '',
      fecha TEXT NOT NULL,
      origen TEXT NOT NULL DEFAULT 'manual',
      categoriaId INTEGER REFERENCES categorias(id) ON DELETE SET NULL
    );
    CREATE TABLE IF NOT EXISTS avisos (
      clave TEXT PRIMARY KEY,
      nivel INTEGER NOT NULL
    );
  `);
  const fila = db.getFirstSync<{ n: number }>("SELECT COUNT(*) AS n FROM categorias");
  if ((fila?.n ?? 0) === 0) {
    for (const [nombre, icono, color] of BASE) {
      db.runSync(
        "INSERT INTO categorias (nombre, icono, colorHex, esPredeterminada) VALUES (?,?,?,1)",
        [nombre, icono, color]
      );
    }
  }
}

export const categorias = (): Categoria[] =>
  db.getAllSync<Categoria>("SELECT * FROM categorias ORDER BY nombre");

export const transaccionesRecientes = (limite = 200): Transaccion[] =>
  db.getAllSync<Transaccion>(
    "SELECT * FROM transacciones ORDER BY fecha DESC LIMIT ?", [limite]
  );

export const transaccionesEntre = (iniISO: string, finISO: string): Transaccion[] =>
  db.getAllSync<Transaccion>(
    "SELECT * FROM transacciones WHERE fecha >= ? AND fecha < ? ORDER BY fecha DESC",
    [iniISO, finISO]
  );
