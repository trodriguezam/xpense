import { Icon, Label, NativeTabs } from "expo-router/unstable-native-tabs";
import { Ionicons } from "@expo/vector-icons";
import { C } from "@/theme";

export default function TabsLayout() {
  return (
    <NativeTabs>
      <NativeTabs.Trigger name="index">
        <Label>Inicio</Label>
        <Icon sf={{ default: "leaf", selected: "leaf.fill" }} drawable="custom_android_drawable" selectedColor={C.musgo} />
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="movimientos">
        <Label>Movimientos</Label>
        <Icon sf="list.bullet" drawable="custom_android_drawable" selectedColor={C.musgo} />
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="categorias">
        <Label>Categorias</Label>
        <Icon sf="square.3.layers.3d" drawable="custom_android_drawable" selectedColor={C.musgo} />
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="ajustes">
        <Label>Ajustes</Label>
        <Icon sf="gear" drawable="custom_android_drawable" selectedColor={C.musgo} />
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
