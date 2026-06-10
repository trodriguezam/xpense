import React from "react";
import { View, Text, StyleSheet, ViewStyle } from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { C, F } from "@/theme";
import { Nivel } from "@/lib/presupuesto";

export function Tarjeta({ children, style }: { children: React.ReactNode; style?: ViewStyle }) {
  return <View style={[s.tarjeta, style]}>{children}</View>;
}

export function Titulo({ children }: { children: React.ReactNode }) {
  return <Text style={s.titulo}>{children}</Text>;
}

export function colorNivel(nivel: Nivel, base: string) {
  if (nivel === 3) return C.teja;
  if (nivel === 2) return C.cobre;
  return nivel === 1 ? C.musgo : base;
}

export function Tallo({ fraccion, nivel }: { fraccion: number; nivel: Nivel }) {
  return (
    <View style={s.talloFondo}>
      <View
        style={[
          s.talloRelleno,
          { width: `${Math.max(4, Math.min(fraccion, 1) * 100)}%`,
            backgroundColor: colorNivel(nivel, C.musgo) },
        ]}
      />
    </View>
  );
}

export function IconoCat({ icono, color }: { icono: string; color: string }) {
  return (
    <View style={[s.iconoCat, { backgroundColor: color }]}>
      <Ionicons name={icono as any} size={16} color="#fff" />
    </View>
  );
}

const s = StyleSheet.create({
  tarjeta: {
    backgroundColor: C.blanco,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: C.arena,
    padding: 16,
    gap: 12,
  },
  titulo: { fontFamily: F.display, fontSize: 19, color: C.corteza },
  talloFondo: {
    height: 10, borderRadius: 5, backgroundColor: C.arena, overflow: "hidden",
  },
  talloRelleno: { height: 10, borderRadius: 5 },
  iconoCat: {
    width: 34, height: 34, borderRadius: 17,
    alignItems: "center", justifyContent: "center",
  },
});
