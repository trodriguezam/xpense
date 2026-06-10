import { useState } from "react";
import { ScrollView, View, Text, Pressable, TextInput, Modal, Alert, StyleSheet } from "react-native";
import { Link } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { Tarjeta, IconoCat } from "@/components/ui";
import { C, F } from "@/theme";
import { useVersionDatos } from "@/lib/store";
import { categorias } from "@/lib/db";
import { estadoDe } from "@/lib/presupuesto";
import { crearCategoria, eliminarCategoria } from "@/lib/acciones";
import { clp } from "@/lib/clp";

const ICONOS = ["leaf","cart","cafe","bus","speedometer","flash","medkit","film",
                "bag-handle","home","paw","book","gift","airplane","barbell","shirt"];
const COLORES = ["#5E7561","#8A6E4B","#6E8B8F","#B5704F","#A9BFA8",
                 "#9C7B9E","#C2A36B","#8FA08A","#7C8577","#2F3A2E"];

export default function Categorias() {
  useVersionDatos();
  const cats = categorias();
  const [modal, setModal] = useState(false);
  const [nombre, setNombre] = useState("");
  const [icono, setIcono] = useState("leaf");
  const [color, setColor] = useState(COLORES[0]);

  const crear = async () => {
    if (!nombre.trim()) return;
    await crearCategoria(nombre.trim(), icono, color);
    setNombre(""); setIcono("leaf"); setColor(COLORES[0]); setModal(false);
  };

  const confirmarBorrar = (id: number, n: string, predeterminada: number) => {
    if (predeterminada) return;
    Alert.alert("Eliminar categoría", `"${n}" — sus movimientos quedarán sin categoría.`, [
      { text: "Cancelar", style: "cancel" },
      { text: "Eliminar", style: "destructive", onPress: () => eliminarCategoria(id) },
    ]);
  };

  return (
    <ScrollView contentContainerStyle={s.cont}>
      {cats.map((cat) => {
        const e = estadoDe(cat);
        return (
          <Link key={cat.id} href={{ pathname: "/categoria/[id]", params: { id: String(cat.id) } }} asChild>
            <Pressable onLongPress={() => confirmarBorrar(cat.id, cat.nombre, cat.esPredeterminada)}>
              <Tarjeta style={s.fila}>
                <IconoCat icono={cat.icono} color={cat.colorHex} />
                <View style={{ flex: 1 }}>
                  <Text style={s.nombre}>{cat.nombre}</Text>
                  <Text style={s.detalle}>
                    {cat.limiteMonto
                      ? `${clp(e.gastado)} de ${clp(cat.limiteMonto)} · ${cat.periodo}`
                      : `${clp(e.gastado)} este mes · sin límite`}
                  </Text>
                </View>
                <Ionicons name="chevron-forward" size={16} color={C.piedra} />
              </Tarjeta>
            </Pressable>
          </Link>
        );
      })}

      <Pressable style={s.botonNueva} onPress={() => setModal(true)}>
        <Ionicons name="add" size={20} color={C.musgo} />
        <Text style={s.botonNuevaTexto}>Nueva categoría</Text>
      </Pressable>

      <Modal visible={modal} animationType="slide" presentationStyle="formSheet"
             onRequestClose={() => setModal(false)}>
        <ScrollView style={{ backgroundColor: C.bruma }} contentContainerStyle={s.modalCont}>
          <Text style={s.modalTitulo}>Nueva categoría</Text>
          <TextInput
            placeholder="Ej: Mascotas" placeholderTextColor={C.piedra}
            value={nombre} onChangeText={setNombre} style={s.input}
          />
          <Text style={s.subt}>Ícono</Text>
          <View style={s.grilla}>
            {ICONOS.map((i) => (
              <Pressable key={i} onPress={() => setIcono(i)}
                style={[s.celdaIcono, { backgroundColor: i === icono ? color : C.arena }]}>
                <Ionicons name={i as any} size={18} color={i === icono ? "#fff" : C.corteza} />
              </Pressable>
            ))}
          </View>
          <Text style={s.subt}>Color</Text>
          <View style={s.grilla}>
            {COLORES.map((c) => (
              <Pressable key={c} onPress={() => setColor(c)}
                style={[s.celdaColor, { backgroundColor: c, borderWidth: c === color ? 3 : 0 }]} />
            ))}
          </View>
          <View style={s.modalBotones}>
            <Pressable onPress={() => setModal(false)}>
              <Text style={{ color: C.piedra, fontSize: 16 }}>Cerrar</Text>
            </Pressable>
            <Pressable onPress={crear} disabled={!nombre.trim()}
              style={[s.botonCrear, { opacity: nombre.trim() ? 1 : 0.4 }]}>
              <Text style={{ color: "#fff", fontWeight: "600" }}>Crear</Text>
            </Pressable>
          </View>
        </ScrollView>
      </Modal>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  cont: { padding: 16, gap: 10, paddingBottom: 40 },
  fila: { flexDirection: "row", alignItems: "center", gap: 12, padding: 12 },
  nombre: { fontSize: 15, fontWeight: "500", color: C.corteza },
  detalle: { fontSize: 12, color: C.piedra },
  botonNueva: {
    flexDirection: "row", gap: 6, alignItems: "center", justifyContent: "center",
    borderWidth: 1.5, borderColor: C.musgo, borderStyle: "dashed",
    borderRadius: 20, paddingVertical: 12, marginTop: 6,
  },
  botonNuevaTexto: { color: C.musgo, fontWeight: "600", fontSize: 15 },
  modalCont: { padding: 20, gap: 14 },
  modalTitulo: { fontFamily: F.display, fontSize: 24, color: C.corteza },
  input: {
    backgroundColor: C.blanco, borderWidth: 1, borderColor: C.arena,
    borderRadius: 14, padding: 14, fontSize: 16, color: C.corteza,
  },
  subt: { fontSize: 13, color: C.piedra, fontWeight: "600" },
  grilla: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  celdaIcono: {
    width: 44, height: 44, borderRadius: 22,
    alignItems: "center", justifyContent: "center",
  },
  celdaColor: { width: 34, height: 34, borderRadius: 17, borderColor: "#fff" },
  modalBotones: {
    flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginTop: 10,
  },
  botonCrear: {
    backgroundColor: C.musgo, borderRadius: 22, paddingHorizontal: 22, paddingVertical: 10,
  },
});
