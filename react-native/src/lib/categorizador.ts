// Sugerencia de categoría según comercio — mismas reglas chilenas que la versión nativa.
import { Categoria } from "./db";

const REGLAS: Array<[string, string]> = [
  ["jumbo","Supermercado"],["lider","Supermercado"],["líder","Supermercado"],
  ["unimarc","Supermercado"],["tottus","Supermercado"],["santa isabel","Supermercado"],
  ["acuenta","Supermercado"],["ok market","Supermercado"],["alvi","Supermercado"],
  ["supermercado","Supermercado"],
  ["starbucks","Restaurantes y café"],["juan valdez","Restaurantes y café"],
  ["mcdonald","Restaurantes y café"],["burger","Restaurantes y café"],
  ["doggis","Restaurantes y café"],["telepizza","Restaurantes y café"],
  ["papa john","Restaurantes y café"],["domino","Restaurantes y café"],
  ["castaño","Restaurantes y café"],["rappi","Restaurantes y café"],
  ["pedidosya","Restaurantes y café"],["uber eats","Restaurantes y café"],
  ["restaurant","Restaurantes y café"],["cafe","Restaurantes y café"],
  ["café","Restaurantes y café"],["sushi","Restaurantes y café"],
  ["uber","Transporte"],["didi","Transporte"],["cabify","Transporte"],
  ["metro","Transporte"],["bip","Transporte"],["red movilidad","Transporte"],
  ["turbus","Transporte"],["pullman","Transporte"],["autopista","Transporte"],
  ["copec","Bencina"],["shell","Bencina"],["petrobras","Bencina"],
  ["aramco","Bencina"],["enex","Bencina"],["terpel","Bencina"],
  ["enel","Cuentas y servicios"],["cge","Cuentas y servicios"],
  ["aguas andinas","Cuentas y servicios"],["esval","Cuentas y servicios"],
  ["metrogas","Cuentas y servicios"],["lipigas","Cuentas y servicios"],
  ["abastible","Cuentas y servicios"],["gasco","Cuentas y servicios"],
  ["movistar","Cuentas y servicios"],["entel","Cuentas y servicios"],
  ["claro","Cuentas y servicios"],["wom","Cuentas y servicios"],
  ["vtr","Cuentas y servicios"],["gtd","Cuentas y servicios"],
  ["cruz verde","Salud"],["salcobrand","Salud"],["ahumada","Salud"],
  ["farmacia","Salud"],["clinica","Salud"],["clínica","Salud"],
  ["isapre","Salud"],["redsalud","Salud"],["integramedica","Salud"],
  ["netflix","Entretenimiento"],["spotify","Entretenimiento"],
  ["disney","Entretenimiento"],["hbo","Entretenimiento"],
  ["cinemark","Entretenimiento"],["cineplanet","Entretenimiento"],
  ["cine hoyts","Entretenimiento"],["steam","Entretenimiento"],
  ["playstation","Entretenimiento"],["nintendo","Entretenimiento"],
  ["xbox","Entretenimiento"],["youtube","Entretenimiento"],
  ["falabella","Compras"],["paris","Compras"],["ripley","Compras"],
  ["hites","Compras"],["la polar","Compras"],["mercado libre","Compras"],
  ["mercadolibre","Compras"],["aliexpress","Compras"],["shein","Compras"],
  ["temu","Compras"],["h&m","Compras"],["zara","Compras"],
  ["sodimac","Hogar"],["easy","Hogar"],["construmart","Hogar"],
  ["imperial","Hogar"],["ikea","Hogar"],["casaideas","Hogar"],
];

export function sugerirCategoria(comercio: string, cats: Categoria[]): Categoria | null {
  const texto = comercio.toLowerCase();
  if (!texto) return null;
  for (const [clave, nombre] of REGLAS) {
    if (texto.includes(clave)) {
      const c = cats.find((x) => x.nombre === nombre);
      if (c) return c;
    }
  }
  return null;
}
