import SwiftUI

struct TecnicoRegistroView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var specialty = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var description = ""
    @State private var navigateToDocumentos = false
    @State private var tecnicoId = ""

    // DNI
    @State private var dni = ""
    @State private var dniVerificado = false
    @State private var dniNombreRENIEC = ""
    @State private var dniError: String?
    @State private var isVerifyingDNI = false

    let specialties = ["Electricidad", "Gasfitería", "Carpintería",
                       "Cerrajería", "Electrodomésticos", "Pintura/Albañilería"]

    var body: some View {
        ZStack {
            LinearGradient(colors: [.tecniPrimary, .tecniAccent],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    dniSection
                    if dniVerificado {
                        formSection
                        continueButton
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDocumentos) {
            TecnicoDocumentosView(tecnicoId: tecnicoId)
                .environmentObject(authVM)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 54))
                .foregroundColor(.white)
            Text("Perfil Técnico")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Completa tu información profesional")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - DNI Section

    private var dniSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verificación de identidad")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.tecniGray)
                    TextField("Número de DNI", text: $dni)
                        .keyboardType(.numberPad)
                        .onChange(of: dni) { _, newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue { dni = filtered }
                            if filtered.count > 8 { dni = String(filtered.prefix(8)) }
                            if dniVerificado {
                                dniVerificado = false
                                dniNombreRENIEC = ""
                                dniError = nil
                            }
                        }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)

                Button {
                    Task { await verificarDNI() }
                } label: {
                    ZStack {
                        if isVerifyingDNI {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verificar")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 90, height: 52)
                    .background(dni.count == 8 ? Color.tecniMint : Color.white.opacity(0.3))
                    .cornerRadius(12)
                }
                .disabled(dni.count != 8 || isVerifyingDNI)
            }

            if let error = dniError {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                    Text(error).font(.caption).foregroundColor(.red)
                }
            }

            if dniVerificado {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.tecniMint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DNI verificado con RENIEC").font(.caption.bold()).foregroundColor(.tecniMint)
                        Text(dniNombreRENIEC).font(.caption).foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.tecniMint.opacity(0.15))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: 14) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Especialidad")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))

                Menu {
                    ForEach(specialties, id: \.self) { s in
                        Button(s) { specialty = s }
                    }
                } label: {
                    HStack {
                        Image(systemName: "wrench.fill").foregroundColor(.tecniGray)
                        Text(specialty.isEmpty ? "Selecciona tu especialidad" : specialty)
                            .foregroundColor(specialty.isEmpty ? .tecniGray : .primary)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.tecniGray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }

            TecniTextField(placeholder: "Teléfono de contacto", text: $phone,
                           icon: "phone.fill", keyboardType: .phonePad)

            TecniTextField(placeholder: "Zona de trabajo (ej: JLByR, Miraflores)",
                           text: $location, icon: "mappin.fill")

            VStack(alignment: .leading, spacing: 6) {
                Text("Descripción profesional")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))

                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Cuéntanos tu experiencia, certificaciones y especialización...")
                            .foregroundColor(.tecniGray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    TextEditor(text: $description)
                        .frame(height: 120)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                }
                .background(Color.white)
                .cornerRadius(12)
            }

            if let error = authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Button

    private var continueButton: some View {
        Button {
            Task { await saveTecnicoInfo() }
        } label: {
            ZStack {
                if authVM.isLoading {
                    ProgressView().tint(.tecniPrimary)
                } else {
                    Text("Continuar → Subir Documentos")
                        .font(.headline)
                        .foregroundColor(.tecniPrimary)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(isFormValid ? Color.white : Color.white.opacity(0.5))
            .cornerRadius(12)
        }
        .disabled(!isFormValid || authVM.isLoading)
    }

    private var isFormValid: Bool {
        dniVerificado && !specialty.isEmpty &&
        !phone.isEmpty && !location.isEmpty && !description.isEmpty
    }

    // MARK: - Verificar DNI

    private func verificarDNI() async {
        isVerifyingDNI = true
        dniError = nil
        dniVerificado = false

        do {
            let resultado = try await FactilizaService.shared.consultarDNI(dni)

            guard let nombreCompleto = resultado.nombreCompleto,
                  !nombreCompleto.isEmpty else {
                dniError = "No se encontró información para ese DNI."
                isVerifyingDNI = false
                return
            }

            dniNombreRENIEC = nombreCompleto
            dniVerificado = true

        } catch {
            dniError = error.localizedDescription
        }

        isVerifyingDNI = false
    }

    // MARK: - Save

    private func saveTecnicoInfo() async {
        guard let userId = authVM.currentUser?.id,
              let name = authVM.currentUser?.name,
              let email = authVM.currentUser?.email else { return }

        authVM.isLoading = true
        authVM.errorMessage = nil

        let id = UUID().uuidString
        tecnicoId = id

        do {
            try await FirestoreService.shared.saveTecnico(
                id: id,
                name: name,
                email: email,
                specialty: specialty,
                phone: phone,
                location: location,
                description: description,
                userId: userId,
                dni: dni,
                dniNombreRENIEC: dniNombreRENIEC
            )
            navigateToDocumentos = true
        } catch {
            authVM.errorMessage = "Error al guardar tu información. Intenta de nuevo."
        }

        authVM.isLoading = false
    }
}
