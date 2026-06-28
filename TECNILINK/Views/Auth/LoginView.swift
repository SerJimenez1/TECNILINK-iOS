import SwiftUI
import GoogleSignInSwift

struct LoginView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var navigateToRegister = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        logoSection
                        formSection
                        loginButton
                        orDivider
                        googleButton
                        registerLink
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 70)
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
        }
    }

    // MARK: - Subviews

    private var logoSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 64))
                .foregroundColor(.white)
            Text("TECNILINK")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Técnicos verificados, servicio confiable")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            TecniTextField(placeholder: "Correo electrónico",
                           text: $email, icon: "envelope.fill",
                           keyboardType: .emailAddress)
            TecniSecureField(placeholder: "Contraseña",
                             text: $password, showPassword: $showPassword)
            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 4)
                    .transition(.opacity.animation(.easeIn))
            }
        }
    }

    private var loginButton: some View {
        Button {
            Task { await authVM.login(email: email, password: password) }
        } label: {
            ZStack {
                if authVM.isLoading {
                    ProgressView().tint(.tecniPrimary)
                } else {
                    Text("Iniciar Sesión")
                        .font(.headline).foregroundColor(.tecniPrimary)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.white)
            .cornerRadius(12)
        }
        .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
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

    private var registerLink: some View {
        Button { navigateToRegister = true } label: {
            Text("¿No tienes cuenta? ").foregroundColor(.white.opacity(0.8)) +
            Text("Regístrate").bold().foregroundColor(.white)
        }
        .font(.subheadline)
    }
}
