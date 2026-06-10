import { useMemo, useState } from "react";
import { ScrollView, View, Text, TextInput, Pressable, StyleSheet } from "react-native";
import { router } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { IconoCat } from "@/components/ui";
import { C, F } from "@/theme";
import { categorias } from "@/lib/db";
import { sugerirCategoria } from "@/lib/categorizador";
import { agregarTransaccion } from "@/lib/acciones";

export default function Agregar() {
  const cats = useMemo(() => categorias(), []);
  const [montoTexto, setMontoTexto] = useState("");
  const [comercio, setComercio] = useState("");
  const [nota, setNota] = useState("");
  const [catId, setCatId] = useState<number | null>(null);
  const [sugeridaAuto, setSugeridaAuto] = useState(false);

  const monto = parseInt(montoTexto.replace(/\D/g, ""), 10) || 0;

  const onComercio = (texto: string) => {
    setComercio(texto);
    const s = sugerirCategoria(texto, cats);
    if (s) { setCatId(s.id); setSugeridaAuto(true); }
    else if (sugeridaAuto) { setCatId(null); setSugeridaAuto(false); }
  };

  const guardar = async () => {
    if (monto <= 0) return;
    await agregarTransaccion({ monto, comercio, nota, categoriaId: catId });
    router.back();
  };

  return (
    <ScrollView style={{ backgroundColor: C.bruma }} contentContainerStyle={s.cont}>
      <Text style={s.etiqueta}>Monto (CLP)</Text>
      <View style={s.filaMonto}>
        <Text style={s.peso}>$</Text>
        <TextInput
          value={montoTexto} onChangeText={setMontoTexto}
          keyboardType="number-pad" placeholder="0" placeholderTextColor={C.piedra}
          style={s.inputMonto} autoFocus
        />
      </View>

      <Text style={s.etiqueta}>Comercio</Text>
      <TextInput
        value={comercio} onChangeText={onComercio}
        placeholder="Ej: Jumbo, Copec, Uber…" placeholderTextColor={C.piedra}
        style={s.input}
      />

      <Text style={s.etiqueta}>Categoría</Text>
      {sugeridaAuto && (
        <View style={s.sugerida}>
          <Ionicons name="sparkles" size={13} color={C.musgo} />
          <Text style={s.sugeridaTexto}>Sugerida según el comercio</Text>
        </View>
      )}
      <View style={s.grillaCats}>
        {cats.map((c) => (
          <Pressable key={c.id}
            onPress={() => { setCatId(c.id === catId ? null : c.id); setSugeridaAuto(false); }}
            style={[s.chip, c.id === catId && { backgroundColor: c.colorHex, borderColor: c.colorHex }]}>
            <IconoCat icono={c.icono} color={c.id === catId ? "rgba(255,255,255,0.25)" : c.colorHex} />
            <Text style={[s.chipTexto, c.id === catId && { color: "#fff" }]}>{c.nombre}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={s.etiqueta}>Nota (opcional)</Text>
      <TextInput value={nota} onChangeText={setNota} placeholder="" style={s.input} />

      <Pressable onPress={guardar} disabled={monto <= 0}
        style={[s.guardar, { opacity: monto > 0 ? 1 : 0.4 }]}>
        <Text style={s.guardarTexto}>Guardar</Text>
      </Pressable>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  cont: { padding: 20, gap: 8, paddingBottom: 60 },
  etiqueta: { fontSize: 12, fontWeight: "600", color: C.piedra, marginTop: 10, letterSpacing: 0.4 },
  filaMonto: {
    flexDirection: "row", alignItems: "center", gap: 6,
    backgroundColor: C.blanco, borderWidth: 1, borderColor: C.arena,
    borderRadius: 14, paddingHorizontal: 14,
  },
  peso: { fontFamily: F.display, fontSize: 24, color: C.piedra },
  inputMonto: { flex: 1, fontFamily: F.display, fontSize: 26, color: C.corteza, paddingVertical: 12 },
  input: {
    backgroundColor: C.blanco, borderWidth: 1, borderColor: C.arena,
    borderRadius: 14, padding: 13, fontSize: 15, color: C.corteza,
  },
  sugerida: { flexDirection: "row", alignItems: "center", gap: 4 },
  sugeridaTexto: { fontSize: 12, color: C.musgo },
  grillaCats: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  chip: {
    flexDirection: "row", alignItems: "center", gap: 6,
    borderWidth: 1, borderColor: C.arena, backgroundColor: C.blanco,
    borderRadius: 22, paddingRight: 12, paddingLeft: 4, paddingVertical: 4,
  },
  chipTexto: { fontSize: 13, color: C.corteza },
  guardar: {
    backgroundColor: C.musgo, borderRadius: 24, paddingVertical: 14,
    alignItems: "center", marginTop: 18,
  },
  guardarTexto: { color: "#fff", fontSize: 16, fontWeight: "600" },
});
