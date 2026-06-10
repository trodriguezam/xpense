import { useEffect } from "react";
import { Alert } from "react-native";
import { Stack } from "expo-router";
import * as Linking from "expo-linking";
import { StatusBar } from "expo-status-bar";
import { migrar } from "@/lib/db";
import { pedirPermiso } from "@/lib/avisos";
import { agregarDesdeApplePay } from "@/lib/acciones";
import { actualizarWidget } from "@/lib/widget";
import { clp } from "@/lib/clp";
import { C } from "@/theme";

migrar();

function manejarURL(url: string | null) {
  if (!url) return;
  const { hostname, path, queryParams } = Linking.parse(url);
  const ruta = hostname || path; // xpense://agregar  ->  hostname "agregar"
  if (ruta !== "agregar") return;
  const monto = Math.round(Number(String(queryParams?.monto ?? "").replace(",", ".")));
  const comercio = String(queryParams?.comercio ?? "");
  if (!monto || monto <= 0) return;
  agregarDesdeApplePay(monto, comercio).then((cat) => {
    Alert.alert("Anotado 🌿", `${clp(monto)} en ${cat}.`);
  });
}

export default function Layout() {
  useEffect(() => {
    pedirPermiso();
    actualizarWidget();
    Linking.getInitialURL().then(manejarURL);
    const sub = Linking.addEventListener("url", (e) => manejarURL(e.url));
    return () => sub.remove();
  }, []);

  return (
    <>
      <StatusBar style="dark" />
      <Stack
        screenOptions={{
          headerShadowVisible: false,
          headerStyle: { backgroundColor: C.bruma },
          headerTintColor: C.corteza,
          contentStyle: { backgroundColor: C.bruma },
        }}
      >
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen name="agregar" options={{ presentation: "modal", title: "Nuevo gasto" }} />
        <Stack.Screen name="categoria/[id]" options={{ title: "" }} />
      </Stack>
    </>
  );
}
