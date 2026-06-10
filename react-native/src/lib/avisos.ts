// Notificaciones locales, con tono amable y sin repetir avisos en el mismo periodo.
import * as Notifications from "expo-notifications";
import { db } from "./db";
import { Estado, clavePeriodo } from "./presupuesto";
import { clp } from "./clp";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

export async function pedirPermiso() {
  const { status } = await Notifications.getPermissionsAsync();
  if (status !== "granted") await Notifications.requestPermissionsAsync();
}

export async function evaluarAviso(e: Estado) {
  if (e.nivel < 2) return;
  const cat = e.categoria;
  const clave = `aviso.${cat.id}.${clavePeriodo(cat.periodo)}`;
  const previo =
    db.getFirstSync<{ nivel: number }>("SELECT nivel FROM avisos WHERE clave = ?", [clave])
      ?.nivel ?? 0;
  if (e.nivel <= previo) return;
  db.runSync(
    "INSERT INTO avisos (clave, nivel) VALUES (?,?) ON CONFLICT(clave) DO UPDATE SET nivel = excluded.nivel",
    [clave, e.nivel]
  );

  const periodoTxt = cat.periodo === "semanal" ? "esta semana" : "este mes";
  const limite = cat.limiteMonto ?? 0;
  await Notifications.scheduleNotificationAsync({
    content:
      e.nivel === 2
        ? {
            title: `Te acercas al límite de ${cat.nombre}`,
            body: `Llevas ${clp(e.gastado)} de ${clp(limite)} ${periodoTxt}. Aún hay espacio — respira.`,
          }
        : {
            title: `Superaste el límite de ${cat.nombre}`,
            body: `Llevas ${clp(e.gastado)} de ${clp(limite)} ${periodoTxt}. Sin culpa: obsérvalo y sigue.`,
          },
    trigger: null,
  });
}
