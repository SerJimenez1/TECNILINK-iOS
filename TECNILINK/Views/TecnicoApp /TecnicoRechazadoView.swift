import SwiftUI

struct TecnicoRechazadoView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.red.opacity(0.8), .tecniPrimary],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "xmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    Text("Verificación rechazada")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Tu solicitud de verificación no fue aprobada. Revisa los motivos y vuelve a intentarlo con documentos más claros.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            authVM.tecnicoStatus = "pending_documents"
                        }
                    } label: {
                        Text("Volver a intentarlo")
                            .font(.headline)
                            .foregroundColor(.tecniPrimary)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)

                    Button {
                        authVM.logout()
                    } label: {
                        Text("Cerrar sesión")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
