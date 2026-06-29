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
    @State private var selectedRole: UserRole = .cliente

    enum UserRole {
        case cliente, tecnico
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    roleSelectorSection
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
        .navigationDestination(isPresented: Binding(
            get: { authVM.navigateToTecnicoRegistro },
            set: { authVM.navigateToTecnicoRegistro = $0 }
        )) {
            TecnicoRegistroView()
                .environmentObject(authVM)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: selectedRole == .cliente ? "person.badge.plus" : "wrench.and.screwdriver.fill")
                .font(.system(size: 54))
                .foregroundColor(.white)
                .animation(.easeInOut, value: selectedRole)
            Text("Crear Cuenta")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(selectedRole == .cliente ? "Regístrate para solicitar técnicos" : "Regístrate como técnico verificado")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: selectedRole)
        }
    }

    private var roleSelectorSection: some View {
        VStack(spacing: 8) {
            Text("¿Cómo quieres usar TECNILINK?")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 0) {
                RoleButton(
                    title: "Soy Cliente",
                    icon: "house.fill",
                    isSelected: selectedRole == .cliente
                ) {
                    withAnimation { selectedRole = .cliente }
                }

                RoleButton(
                    title: "Soy Técnico",
                    icon: "wrench.fill",
                    isSelected: selectedRole == .tecnico
                ) {
                    withAnimation { selectedRole = .tecnico }
                }
            }
            .background(Color.white.opacity(0.15))
            .cornerRadius(10)
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
            Task {
                await authVM.register(
                    name: name,
                    email: email,
                    password: password,
                    role: selectedRole == .tecnico ? "tecnico" : "user"
                )
            }
        } label: {
            ZStack {
                if authVM.isLoading {
                    ProgressView().tint(.tecniPrimary)
                } else {
                    Text(selectedRole == .cliente ? "Crear Cuenta" : "Continuar como Técnico")
                        .font(.headline).foregroundColor(.tecniPrimary)
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

// MARK: - Role Button

private struct RoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(title).font(.caption.bold())
            }
            .foregroundColor(isSelected ? .tecniPrimary : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? Color.white : Color.clear)
            .cornerRadius(8)
        }
    }
}
