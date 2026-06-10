import { useEffect, useState } from "react";
import { ScrollView, View, Text, TextInput, Pressable, Switch, StyleSheet } from "react-native";
import { useLocalSearchParams, useNavigation } from "expo-router";
import Slider from "@react-native-community/slider";
import { Tarjeta, Titulo, Tallo, IconoCat } from "@/components/ui";
import { C, F } from "@/theme";
import { useVersionDatos } from "@/lib/store";
import { categorias, Periodo } from "@/lib/db";
import { estadoDe, transaccionesDePeriodo } from "@/lib/presupuesto";
import { actualizarLimite } from "@/lib/acciones";
import { clp } from "@/lib/clp";

export default function DetalleCategoria() {
  useVersionDatos();
  const { id } = useLocalSearchParams<{ id: string }>();
  const nav = useNavigation();
  const cat = categorias().find((c) => c.id === Number(id));

  const [tieneLimite, setTieneLimite] = useState(false);
  const [limiteTexto, setLimiteTexto] = useState("");
  const [periodo, setPeriodo] = useState<Periodo>("mensual");
  const [umbral, setUmbral] = useState(0.8);

  useEffect(() => {
    if (!cat) return;
    nav.setOptions({ title: cat.nombre });
    setTieneLimite(!!cat.limiteMonto);
    setLimiteTexto(cat.limiteMonto ? String(cat.limiteMonto) : "");
    setPeriodo(cat.periodo);
    setUmbral(cat.umbralAviso);
  }, [cat?.id]);

  if (!cat) return null;

  const limite = parseInt(limiteTexto.replace(/\D/g, ""), 10) || 0;
  const e = estadoDe(cat);
  const txs = transaccionesDePeriodo(cat);

  const guardar = () =>
    actualizarLimite(cat.id, tieneLimite && limite > 0 ? limite : null, periodo, umbral);

  return (
    <ScrollView contentContainerStyle={s.cont}>
      <Tarjeta>
        <View style={s.filaGasto}>
          <IconoCat icono={cat.icono} color={cat.colorHex} />
          <Text style={s.gastado}>{clp(e.gastado)}</Text>
          {tieneLimite && limite > 0 && <Text style={s.deLimite}>de {clp(limite)}</Text>}
        </View>
        <Text style={s.subtexto}>
          Gastado {periodo === "semanal" ? "esta semana" : "este mes"}
        </Text>
        {tieneLimite && limite > 0 && <Tallo fraccion={e.fraccion} nivel={e.nivel} />}
      </Tarjeta>

      <Tarjeta>
        <View style={s.filaSwitch}>
          <Titulo>Límite</Titulo>
          <Switch
            value={tieneLimite}
            onValueChange={(v) => { setTieneLimite(v); }}
            trackColor={{ true: C.musgo, false: C.arena }}
          />
        </View>
        {tieneLimite && (
          <>
            <TextInput
              value={limiteTexto} onChangeText={setLimiteTexto}
              keyboardType="number-pad" placeholder="Monto en CLP"
              placeholderTextColor={C.piedra} style={s.input}
            />
            <View style={s.segmento}>
              {(["semanal", "mensual"] as Periodo[]).map((p) => (
                <Pressable key={p} onPress={() => setPeriodo(p)}
                  style={[s.segmentoOp, periodo === p && s.segmentoActivo]}>
                  <Text style={[s.segmentoTexto, periodo === p && { color: "#fff" }]}>
                    {p === "semanal" ? "Semanal" : "Mensual"}
                  </Text>
                </Pressable>
              ))}
            </View>
            <Text style={s.subtexto}>Avisar al llegar al {Math.round(umbral * 100)} %</Text>
            <Slider
              minimumValue={0.5} maximumValue={0.95} step={0.05}
              value={umbral} onValueChange={setUmbral}
              minimumTrackTintColor={C.musgo} maximumTrackTintColor={C.arena}
            />
          </>
        )}
        <Pressable style={s.guardar} onPress={guardar}>
          <Text style={s.guardarTexto}>Guardar cambios</Text>
        </Pressable>
      </Tarjeta>

      <Tarjeta>
        <Titulo>Movimientos del periodo</Titulo>
        {txs.length === 0 ? (
          <Text style={s.subtexto}>Nada por aquí todavía.</Text>
        ) : (
          txs.map((t) => (
            <View key={t.id} style={s.filaTx}>
              <View style={{ flex: 1 }}>
                <Text style={s.txComercio}>{t.comercio || "Sin comercio"}</Text>
                <Text style={s.subtexto}>
                  {new Intl.DateTimeFormat("es-CL", { day: "numeric", month: "long" })
                    .format(new Date(t.fecha))}
                  {t.origen === "applepay" ? " · Apple Pay" : ""}
                </Text>
              </View>
              <Text style={s.txMonto}>{clp(t.monto)}</Text>
            </View>
          ))
        )}
      </Tarjeta>
    </ScrollView>
  );
}

const s = StyleSheet.create({
  cont: { padding: 16, gap: 14, paddingBottom: 40 },
  filaGasto: { flexDirection: "row", alignItems: "center", gap: 10 },
  gastado: { fontFamily: F.display, fontSize: 28, color: C.corteza },
  deLimite: { fontSize: 13, color: C.piedra },
  subtexto: { fontSize: 13, color: C.piedra },
  filaSwitch: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  input: {
    backgroundColor: C.bruma, borderWidth: 1, borderColor: C.arena,
    borderRadius: 12, padding: 12, fontSize: 16, color: C.corteza,
  },
  segmento: {
    flexDirection: "row", backgroundColor: C.arena, borderRadius: 12, padding: 3,
  },
  segmentoOp: { flex: 1, paddingVertical: 8, borderRadius: 10, alignItems: "center" },
  segmentoActivo: { backgroundColor: C.musgo },
  segmentoTexto: { fontSize: 14, fontWeight: "600", color: C.corteza },
  guardar: {
    backgroundColor: C.musgo, borderRadius: 20, paddingVertical: 11,
    alignItems: "center", marginTop: 4,
  },
  guardarTexto: { color: "#fff", fontWeight: "600", fontSize: 14 },
  filaTx: { flexDirection: "row", alignItems: "center", gap: 10 },
  txComercio: { fontSize: 14, fontWeight: "500", color: C.corteza },
  txMonto: { fontSize: 14, fontWeight: "500", color: C.corteza },
});
