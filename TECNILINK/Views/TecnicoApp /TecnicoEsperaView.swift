import SwiftUI

struct TecnicoEsperaView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    Text("¡Solicitud enviada!")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text("Estamos revisando tus documentos. Te notificaremos cuando tu cuenta sea aprobada.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    StatusStep(number: "1", title: "Documentos enviados", isDone: true)
                    StatusStep(number: "2", title: "Revisión por el equipo TECNILINK", isDone: false)
                    StatusStep(number: "3", title: "Cuenta activada", isDone: false)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    authVM.logout()
                } label: {
                    Text("Cerrar sesión")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct StatusStep: View {
    let number: String
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.tecniMint : Color.white.opacity(0.3))
                    .frame(width: 32, height: 32)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Text(number)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(isDone ? .white : .white.opacity(0.6))

            Spacer()
        }
    }
}
