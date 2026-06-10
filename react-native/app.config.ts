import { ExpoConfig } from "expo/config";

// Cambia "cl.tuequipo" por tu dominio invertido real.
const config: ExpoConfig = {
  name: "xpense",
  slug: "xpense",
  version: "1.0.0",
  scheme: "xpense",                     // habilita xpense:// para la automatización de Atajos
  orientation: "portrait",
  userInterfaceStyle: "light",
  platforms: ["ios"],
  ios: {
    bundleIdentifier: "cl.trodriguezam.xpense.rn",
    supportsTablet: false,
    entitlements: {
      "com.apple.security.application-groups": ["group.cl.trodriguezam.xpense.rn"],
    },
    infoPlist: {
      CFBundleDevelopmentRegion: "es_CL",
      ITSAppUsesNonExemptEncryption: false,
    },
  },
  plugins: [
    "expo-router",
    "expo-sqlite",
    "@bacons/apple-targets",
    ["expo-notifications", { color: "#5E7561" }],
  ],
  experiments: { typedRoutes: true },
  extra: {
    eas: {
      projectId: "8253027d-f4d5-47e8-b1a6-b27ecbe353fe",
    },
  },
};

export default config;
