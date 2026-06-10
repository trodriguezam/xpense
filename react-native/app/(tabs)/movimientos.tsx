import { SectionList, View, Text, Pressable, Alert, StyleSheet } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { IconoCat } from "@/components/ui";
import { C } from "@/theme";
import { useVersionDatos } from "@/lib/store";
import { transaccionesRecientes, categorias, Transaccion } from "@/lib/db";
import { eliminarTransaccion } from "@/lib/acciones";
import { clp } from "@/lib/clp";

export default function Movimientos() {
  useVersionDatos();
  const txs = transaccionesRecientes(500);
  const cats = categorias();

  const porDia = new Map<string, Transaccion[]>();
  for (const t of txs) {
    const dia = t.fecha.slice(0, 10);
    porDia.set(dia, [...(porDia.get(dia) ?? []), t]);
  }
  const secciones = [...porDia.entries()].map(([dia, data]) => ({
    title: new Intl.DateTimeFormat("es-CL", {
      weekday: "long", day: "numeric", month: "long",
    }).format(new Date(dia + "T12:00:00")),
    data,
  }));

  const confirmarBorrar = (t: Transaccion) =>
    Alert.alert("Eliminar movimiento", `${t.comercio || "Gasto"} · ${clp(t.monto)}`, [
      { text: "Cancelar", style: "cancel" },
      { text: "Eliminar", style: "destructive", onPress: () => eliminarTransaccion(t.id) },
    ]);

  if (txs.length === 0)
    return (
      <View style={s.vacioCont}>
        <Ionicons name="leaf-outline" size={36} color={C.salvia} />
        <Text style={s.vacioTexto}>
          Sin movimientos aún.{"\n"}Anota tu primer gasto o configura la automatización de
          Apple Pay en Ajustes.
        </Text>
        <Pressable style={s.boton} onPress={() => router.push("/agregar")}>
          <Text style={s.botonTexto}>Anotar un gasto</Text>
        </Pressable>
      </View>
    );

  return (
    <SectionList
      sections={secciones}
      keyExtractor={(t) => String(t.id)}
      contentContainerStyle={{ padding: 16, paddingBottom: 40 }}
      renderSectionHeader={({ section }) => <Text style={s.dia}>{section.title}</Text>}
      renderItem={({ item: t }) => {
        const cat = cats.find((c) => c.id === t.categoriaId);
        return (
          <Pressable onLongPress={() => confirmarBorrar(t)} style={s.fila}>
            <IconoCat icono={cat?.icono ?? "leaf"} color={cat?.colorHex ?? C.piedra} />
            <View style={{ flex: 1 }}>
              <Text style={s.comercio}>{t.comercio || "Sin comercio"}</Text>
              <Text style={s.detalle}>
                {cat?.nombre ?? "Sin categoría"}
                {t.origen === "applepay" ? " · Apple Pay" : ""}
              </Text>
            </View>
            <Text style={s.monto}>{clp(t.monto)}</Text>
          </Pressable>
        );
      }}
    />
  );
}

const s = StyleSheet.create({
  dia: { fontSize: 13, color: C.piedra, marginTop: 14, marginBottom: 6, textTransform: "capitalize" },
  fila: {
    flexDirection: "row", alignItems: "center", gap: 12,
    backgroundColor: C.blanco, borderRadius: 16, borderWidth: 1, borderColor: C.arena,
    padding: 12, marginBottom: 8,
  },
  comercio: { fontSize: 15, color: C.corteza, fontWeight: "500" },
  detalle: { fontSize: 12, color: C.piedra },
  monto: { fontSize: 15, fontWeight: "500", color: C.corteza },
  vacioCont: { flex: 1, alignItems: "center", justifyContent: "center", gap: 12, padding: 32 },
  vacioTexto: { textAlign: "center", color: C.piedra, fontSize: 14, lineHeight: 21 },
  boton: { backgroundColor: C.musgo, borderRadius: 22, paddingHorizontal: 18, paddingVertical: 10 },
  botonTexto: { color: "#fff", fontWeight: "600" },
});
