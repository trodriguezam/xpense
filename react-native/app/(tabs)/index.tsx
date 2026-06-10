import { ScrollView, View, Text, Pressable, StyleSheet } from "react-native";
import { Link, router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { Tarjeta, Titulo, Tallo, IconoCat } from "@/components/ui";
import { C, F } from "@/theme";
import { useVersionDatos } from "@/lib/store";
import { estados, totalMes, mensajeGeneral, Estado } from "@/lib/presupuesto";
import { transaccionesRecientes, categorias } from "@/lib/db";
import { clp } from "@/lib/clp";

export default function Inicio() {
  useVersionDatos();
  const todos = estados();
  const conLimite = todos.filter((e) => e.nivel > 0).sort((a, b) => b.fraccion - a.fraccion);
  const recientes = transaccionesRecientes(5);
  const cats = categorias();
  const hora = new Date().getHours();
  const saludo = hora < 12 ? "Buenos días" : hora < 20 ? "Buenas tardes" : "Buenas noches";
  const mes = new Intl.DateTimeFormat("es-CL", { month: "long" }).format(new Date());

  return (
    <ScrollView contentContainerStyle={s.cont}>
      <Text style={s.saludo}>{saludo}</Text>
      <Text style={s.encabezado}>Tu {mes}, en calma</Text>

      <Tarjeta>
        <Text style={s.etiqueta}>GASTADO ESTE MES</Text>
        <Text style={s.total}>{clp(totalMes())}</Text>
        <Text style={s.mensaje}>{mensajeGeneral(todos)}</Text>
      </Tarjeta>

      <Tarjeta>
        <Titulo>Tus límites</Titulo>
        {conLimite.length === 0 ? (
          <Text style={s.vacio}>
            Aún no defines límites.{"\n"}Hazlo en Categorías, a tu ritmo.
          </Text>
        ) : (
          conLimite.map((e) => <FilaPresupuesto key={e.categoria.id} e={e} />)
        )}
      </Tarjeta>

      {recientes.length > 0 && (
        <Tarjeta>
          <Titulo>Últimos movimientos</Titulo>
          {recientes.map((t) => {
            const cat = cats.find((c) => c.id === t.categoriaId);
            return (
              <View key={t.id} style={s.filaTx}>
                <IconoCat icono={cat?.icono ?? "leaf"} color={cat?.colorHex ?? C.piedra} />
                <View style={{ flex: 1 }}>
                  <Text style={s.txComercio}>{t.comercio || "Sin comercio"}</Text>
                  <Text style={s.txFecha}>
                    {t.origen === "applepay" ? "  Apple Pay · " : ""}
                    {new Intl.DateTimeFormat("es-CL", { day: "numeric", month: "long" })
                      .format(new Date(t.fecha))}
                  </Text>
                </View>
                <Text style={s.txMonto}>{clp(t.monto)}</Text>
              </View>
            );
          })}
        </Tarjeta>
      )}

      <Pressable style={s.botonMas} onPress={() => router.push("/agregar")}>
        <Ionicons name="add" size={22} color="#fff" />
        <Text style={s.botonMasTexto}>Anotar un gasto</Text>
      </Pressable>
    </ScrollView>
  );
}

export function FilaPresupuesto({ e }: { e: Estado }) {
  return (
    <Link href={{ pathname: "/categoria/[id]", params: { id: String(e.categoria.id) } }} asChild>
      <Pressable style={{ gap: 6 }}>
        <View style={s.filaTx}>
          <IconoCat icono={e.categoria.icono} color={e.categoria.colorHex} />
          <View style={{ flex: 1 }}>
            <Text style={s.txComercio}>{e.categoria.nombre}</Text>
            <Text style={s.txFecha}>{e.categoria.periodo}</Text>
          </View>
          <Text style={s.txFecha}>
            {clp(e.gastado)} de {clp(e.categoria.limiteMonto ?? 0)}
          </Text>
        </View>
        <Tallo fraccion={e.fraccion} nivel={e.nivel} />
      </Pressable>
    </Link>
  );
}

const s = StyleSheet.create({
  cont: { padding: 16, gap: 16, paddingBottom: 40 },
  saludo: { fontFamily: F.display, fontSize: 17, color: C.piedra },
  encabezado: { fontFamily: F.display, fontSize: 30, color: C.corteza, marginBottom: 4 },
  etiqueta: { fontSize: 11, letterSpacing: 1.2, fontWeight: "600", color: C.piedra },
  total: { fontFamily: F.display, fontSize: 38, color: C.corteza },
  mensaje: { fontSize: 14, color: C.musgo },
  vacio: { fontSize: 14, color: C.piedra, textAlign: "center", paddingVertical: 8 },
  filaTx: { flexDirection: "row", alignItems: "center", gap: 12 },
  txComercio: { fontSize: 15, color: C.corteza, fontWeight: "500" },
  txFecha: { fontSize: 12, color: C.piedra },
  txMonto: { fontSize: 15, fontWeight: "500", color: C.corteza },
  botonMas: {
    flexDirection: "row", gap: 6, alignSelf: "center", alignItems: "center",
    backgroundColor: C.musgo, paddingHorizontal: 20, paddingVertical: 12, borderRadius: 24,
  },
  botonMasTexto: { color: "#fff", fontSize: 15, fontWeight: "600" },
});
