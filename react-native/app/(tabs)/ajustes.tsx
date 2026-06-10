import { ScrollView, View, Text, Pressable, Linking, StyleSheet } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { Tarjeta, Titulo } from "@/components/ui";
import { C } from "@/theme";
import { pedirPermiso } from "@/lib/avisos";

const PASOS = [
  "Abre Atajos → pestaña Automatización → +.",
  'Elige el gatillo "Transacción" y selecciona tus tarjetas de Apple Pay.',
  'Marca "Ejecutar inmediatamente" (sin preguntar).',
  'Agrega la acción "Abrir URL".',
  "Pega esta URL e inserta las variables de la transacción donde corresponde:",
];

export default function Ajustes() {
  return (
    <ScrollView contentContainerStyle={s.cont}>
      <Tarjeta>
        <View style={s.filaTitulo}>
          <Ionicons name="card" size={18} color={C.musgo} />
          <Titulo>Captura automática con Apple Pay</Titulo>
        </View>
        <Text style={s.parrafo}>
          iOS no deja que las apps lean tus pagos directamente, pero Atajos sí puede avisarle
          a xpense cada vez que pagas. Se configura una sola vez:
        </Text>
        {PASOS.map((p, i) => (
          <View key={i} style={s.paso}>
            <View style={s.numero}><Text style={s.numeroTexto}>{i + 1}</Text></View>
            <Text style={s.pasoTexto}>{p}</Text>
          </View>
        ))}
        <View style={s.cajaURL}>
          <Text style={s.url}>xpense://agregar?monto=[Cantidad]&comercio=[Comerciante]</Text>
        </View>
        <Text style={s.nota}>
          Reemplaza [Cantidad] y [Comerciante] por las variables que ofrece el gatillo
          Transacción. Al pagar, se abrirá xpense un instante y el gasto quedará anotado
          y categorizado.
        </Text>
        <Pressable style={s.boton} onPress={() => Linking.openURL("shortcuts://")}>
          <Text style={s.botonTexto}>Abrir Atajos</Text>
          <Ionicons name="open-outline" size={15} color="#fff" />
        </Pressable>
      </Tarjeta>

      <Tarjeta>
        <Titulo>Notificaciones</Titulo>
        <Text style={s.parrafo}>
          xpense te avisa con calma cuando una categoría se acerca a su límite.
          El umbral se ajusta en cada categoría.
        </Text>
        <Pressable onPress={pedirPermiso}>
          <Text style={s.enlace}>Revisar permiso de notificaciones</Text>
        </Pressable>
      </Tarjeta>

      <Tarjeta>
        <Titulo>Tus datos</Titulo>
        <Text style={s.parrafo}>
          Viven en tu iPhone y se incluyen en el respaldo de iCloud de tu equipo.
          Nadie más los ve — ni nosotros.
        </Text>
      </Tarjeta>

      <Text style={s.pie}>xpense · mirar tus gastos sin apuro ni culpa 🌿</Text>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  cont: { padding: 16, gap: 14, paddingBottom: 40 },
  filaTitulo: { flexDirection: "row", alignItems: "center", gap: 8 },
  parrafo: { fontSize: 14, color: C.piedra, lineHeight: 20 },
  paso: { flexDirection: "row", gap: 8, alignItems: "flex-start" },
  numero: {
    width: 18, height: 18, borderRadius: 9, backgroundColor: C.musgo,
    alignItems: "center", justifyContent: "center", marginTop: 2,
  },
  numeroTexto: { color: "#fff", fontSize: 11, fontWeight: "700" },
  pasoTexto: { flex: 1, fontSize: 14, color: C.corteza, lineHeight: 20 },
  cajaURL: { backgroundColor: C.arena, borderRadius: 12, padding: 12 },
  url: { fontFamily: "Menlo", fontSize: 12, color: C.corteza },
  nota: { fontSize: 12, color: C.piedra, lineHeight: 18 },
  boton: {
    flexDirection: "row", gap: 6, alignSelf: "flex-start", alignItems: "center",
    backgroundColor: C.musgo, borderRadius: 20, paddingHorizontal: 16, paddingVertical: 9,
  },
  botonTexto: { color: "#fff", fontWeight: "600", fontSize: 14 },
  enlace: { color: C.musgo, fontWeight: "600", fontSize: 14 },
  pie: { textAlign: "center", color: C.piedra, fontSize: 12, marginTop: 8 },
});
