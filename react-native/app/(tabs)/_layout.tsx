import { Tabs } from "expo-router";
import { Ionicons } from "@expo/vector-icons";
import { C } from "@/theme";

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShadowVisible: false,
        headerStyle: { backgroundColor: C.bruma },
        headerTintColor: C.corteza,
        tabBarActiveTintColor: C.musgo,
        tabBarInactiveTintColor: C.piedra,
        tabBarStyle: { backgroundColor: C.bruma, borderTopColor: C.arena },
        sceneStyle: { backgroundColor: C.bruma },
      }}
    >
      <Tabs.Screen name="index" options={{
        title: "Inicio",
        tabBarIcon: ({ color, size }) => <Ionicons name="leaf" size={size} color={color} />,
      }} />
      <Tabs.Screen name="movimientos" options={{
        title: "Movimientos",
        tabBarIcon: ({ color, size }) => <Ionicons name="list" size={size} color={color} />,
      }} />
      <Tabs.Screen name="categorias" options={{
        title: "Categorías",
        tabBarIcon: ({ color, size }) => <Ionicons name="grid" size={size} color={color} />,
      }} />
      <Tabs.Screen name="ajustes" options={{
        title: "Ajustes",
        tabBarIcon: ({ color, size }) => <Ionicons name="settings" size={size} color={color} />,
      }} />
    </Tabs>
  );
}
