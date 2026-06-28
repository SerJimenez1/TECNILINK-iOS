import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirm = false
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    formSection
                    registerButton
                    orDivider
                    googleButton
                    backButton
                }
                .padding(.horizontal, 28)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.badge.plus").font(.system(size: 54)).foregroundColor(.white)
            Text("Crear Cuenta").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text("Regístrate para solicitar técnicos").font(.subheadline).foregroundColor(.white.opacity(0.8))
        }
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            TecniTextField(placeholder: "Nombre completo", text: $name, icon: "person.fill")
            TecniTextField(placeholder: "Correo electrónico", text: $email,
                           icon: "envelope.fill", keyboardType: .emailAddress)
            TecniSecureField(placeholder: "Contraseña (mín. 8 caracteres)",
                             text: $password, showPassword: $showPassword)
            TecniSecureField(placeholder: "Confirmar contraseña",
                             text: $confirmPassword, showPassword: $showConfirm)

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption).foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 4)
                    .transition(.opacity.animation(.easeIn))
            }
        }
    }

    private var registerButton: some View {
        Button {
            guard password == confirmPassword else { return }
            Task { await authVM.register(name: name, email: email, password: password) }
        } label: {
            ZStack {
                if authVM.isLoading {
                    ProgressView().tint(.tecniPrimary)
                } else {
                    Text("Crear Cuenta").font(.headline).foregroundColor(.tecniPrimary)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(confirmPassword == password && !password.isEmpty ? Color.white : Color.white.opacity(0.5))
            .cornerRadius(12)
        }
        .disabled(authVM.isLoading || name.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword)
    }

    private var orDivider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
            Text("o").font(.caption).foregroundColor(.white.opacity(0.6))
            Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.3))
        }
    }

    private var googleButton: some View {
        Button {
            Task { await authVM.loginWithGoogle() }
        } label: {
            HStack(spacing: 12) {
                Image("google_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("Continuar con Google")
                    .font(.headline)
                    .foregroundColor(.tecniPrimary)
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.white)
            .cornerRadius(12)
        }
        .disabled(authVM.isLoading)
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Ya tengo cuenta")
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.85))
        }
    }
}
