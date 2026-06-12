import SwiftUI
import SwiftData

struct AjustesView: View {
    @Environment(\.modelContext) private var contexto
    @State private var mostrarTutorial = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Captura automática con Apple Pay", systemImage: "wave.3.right.circle.fill")
                            .font(.headline)
                        Text("iOS no permite a las apps leer tus pagos directamente, pero Atajos sí puede avisarle a Xpense cada vez que pagas. Se configura una sola vez.")
                            .font(.subheadline).foregroundStyle(Paleta.piedra)
                    }
                    .padding(.vertical, 4)
                    Button {
                        mostrarTutorial = true
                    } label: {
                        Label("Ver tutorial paso a paso", systemImage: "book.fill")
                    }
                    Link(destination: URL(string: "shortcuts://")!) {
                        Label("Abrir Atajos", systemImage: "arrow.up.right")
                    }
                }

                Section("Notificaciones") {
                    Text("Xpense te avisa con calma cuando una categoría se acerca a su límite. El umbral se ajusta en cada categoría.")
                        .font(.subheadline).foregroundStyle(Paleta.piedra)
                    Button("Revisar permiso de notificaciones") {
                        Task { await Avisos.revisarPermiso() }
                    }
                }

                Section("Tus datos") {
                    Label("Se guardan en tu iPhone y se sincronizan con tu iCloud privado. Nadie más los ve — ni nosotros.", systemImage: "lock.icloud")
                        .font(.subheadline).foregroundStyle(Paleta.piedra)
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Xpense").font(.system(.title3, design: .serif))
                        Text("Mirar tus gastos sin apuro ni culpa.\nHecho para Chile. 🌿")
                            .font(.caption).foregroundStyle(Paleta.piedra)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Paleta.bruma)
            .navigationTitle("Ajustes")
            .sheet(isPresented: $mostrarTutorial) { TutorialView() }
        }
    }
}
