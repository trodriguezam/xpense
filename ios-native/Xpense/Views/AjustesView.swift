import SwiftUI
import SwiftData

struct AjustesView: View {
    @Environment(\.modelContext) private var contexto

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Captura automática con Apple Pay", systemImage: "wave.3.right.circle.fill")
                            .font(.headline)
                        Text("iOS no permite a las apps leer tus pagos directamente, pero Atajos sí puede avisarle a xpense cada vez que pagas. Se configura una sola vez:")
                            .font(.subheadline).foregroundStyle(Paleta.piedra)
                        VStack(alignment: .leading, spacing: 6) {
                            paso(1, "Abre **Atajos** → pestaña **Automatización** → **+**.")
                            paso(2, "Elige el gatillo **Transacción** y selecciona tus tarjetas de Apple Pay.")
                            paso(3, "Marca **Ejecutar inmediatamente** (sin preguntar).")
                            paso(4, "Agrega la acción **Registrar gasto** (de xpense).")
                            paso(5, "En *Monto* inserta la variable **Cantidad** de la transacción; en *Comercio*, la variable **Comerciante**.")
                        }
                        Link(destination: URL(string: "shortcuts://")!) {
                            Label("Abrir Atajos", systemImage: "arrow.up.right")
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notificaciones") {
                    Text("xpense te avisa con calma cuando una categoría se acerca a su límite. El umbral se ajusta en cada categoría.")
                        .font(.subheadline).foregroundStyle(Paleta.piedra)
                    Button("Revisar permiso de notificaciones") {
                        Task { await Avisos.pedirPermiso() }
                    }
                }

                Section("Tus datos") {
                    Label("Se guardan en tu iPhone y se sincronizan con tu iCloud privado. Nadie más los ve — ni nosotros.", systemImage: "lock.icloud")
                        .font(.subheadline).foregroundStyle(Paleta.piedra)
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("xpense").font(.system(.title3, design: .serif))
                        Text("Mirar tus gastos sin apuro ni culpa.\nHecho para Chile. 🌿")
                            .font(.caption).foregroundStyle(Paleta.piedra)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .navigationTitle("Ajustes")
        }
    }

    private func paso(_ n: Int, _ texto: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(n)").font(.caption.bold()).foregroundStyle(.white)
                .frame(width: 18, height: 18).background(Circle().fill(Paleta.musgo))
            Text(.init(texto)).font(.subheadline)
        }
    }
}
