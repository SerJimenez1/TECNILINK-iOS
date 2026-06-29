import SwiftUI
import PhotosUI

struct TecnicoDocumentosView: View {
    let tecnicoId: String
    @EnvironmentObject private var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dniFront: UIImage?
    @State private var dniBack: UIImage?
    @State private var certificate: UIImage?
    @State private var selfie: UIImage?
    @State private var workPhotos: [UIImage] = []

    @State private var activePhoto: PhotoType?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var navigateToEspera = false

    enum PhotoType {
        case dniFront, dniBack, certificate, selfie, workPhoto
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    documentosSection
                    workPhotosSection
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                    }
                    submitButton
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Subir Documentos")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: imageBinding(for: activePhoto))
        }
        .navigationDestination(isPresented: $navigateToEspera) {
            TecnicoEsperaView()
                .environmentObject(authVM)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.tecniPrimary)
                .padding(.top, 24)
            Text("Sube tus documentos")
                .font(.title2.bold())
            Text("Necesitamos verificar tu identidad y experiencia para activar tu cuenta.")
                .font(.subheadline)
                .foregroundColor(.tecniGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Documentos

    private var documentosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documentos obligatorios")
                .font(.headline)
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                DocumentUploadRow(
                    icon: "creditcard.fill",
                    title: "DNI Frontal",
                    subtitle: "Foto clara de la parte delantera",
                    image: dniFront,
                    isRequired: true
                ) {
                    activePhoto = .dniFront
                    showImagePicker = true
                }

                DocumentUploadRow(
                    icon: "creditcard",
                    title: "DNI Posterior",
                    subtitle: "Foto clara de la parte trasera",
                    image: dniBack,
                    isRequired: true
                ) {
                    activePhoto = .dniBack
                    showImagePicker = true
                }

                DocumentUploadRow(
                    icon: "doc.fill",
                    title: "Certificado técnico",
                    subtitle: "Título, constancia o certificado de estudios",
                    image: certificate,
                    isRequired: true
                ) {
                    activePhoto = .certificate
                    showImagePicker = true
                }

                DocumentUploadRow(
                    icon: "person.fill.viewfinder",
                    title: "Selfie sosteniendo tu DNI",
                    subtitle: "Tu cara y el DNI deben ser visibles",
                    image: selfie,
                    isRequired: true
                ) {
                    activePhoto = .selfie
                    showImagePicker = true
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Work Photos

    private var workPhotosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fotos de trabajos anteriores")
                    .font(.headline)
                Spacer()
                Text("\(workPhotos.count)/5")
                    .font(.caption)
                    .foregroundColor(.tecniGray)
            }
            .padding(.horizontal, 20)

            Text("Mínimo 3 fotos de trabajos reales que hayas realizado")
                .font(.caption)
                .foregroundColor(.tecniGray)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(workPhotos.indices, id: \.self) { i in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: workPhotos[i])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .clipped()

                            Button {
                                workPhotos.remove(at: i)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .padding(4)
                        }
                    }

                    if workPhotos.count < 5 {
                        Button {
                            activePhoto = .workPhoto
                            showImagePicker = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.tecniPrimary)
                                Text("Agregar")
                                    .font(.caption)
                                    .foregroundColor(.tecniPrimary)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.tecniPrimary.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task { await submitDocuments() }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Enviar para verificación")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(isFormValid ? Color.tecniPrimary : Color.tecniGray)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isLoading)
        .padding(.horizontal, 20)
    }

    private var isFormValid: Bool {
        dniFront != nil && dniBack != nil &&
        certificate != nil && selfie != nil &&
        workPhotos.count >= 3
    }

    // MARK: - Submit

    private func submitDocuments() async {
        isLoading = true
        errorMessage = nil

        do {
            var documents: [String: String] = [:]

            if let img = dniFront {
                documents["dniFrontURL"] = try await StorageService.shared.uploadTecnicoDocument(img, tecnicoId: tecnicoId, documentType: "dniFront")
            }
            if let img = dniBack {
                documents["dniBackURL"] = try await StorageService.shared.uploadTecnicoDocument(img, tecnicoId: tecnicoId, documentType: "dniBack")
            }
            if let img = certificate {
                documents["certificateURL"] = try await StorageService.shared.uploadTecnicoDocument(img, tecnicoId: tecnicoId, documentType: "certificate")
            }
            if let img = selfie {
                documents["selfieURL"] = try await StorageService.shared.uploadTecnicoDocument(img, tecnicoId: tecnicoId, documentType: "selfie")
            }

            var workURLs: [String] = []
            for (i, photo) in workPhotos.enumerated() {
                let url = try await StorageService.shared.uploadWorkPhoto(photo, tecnicoId: tecnicoId, index: i)
                workURLs.append(url)
            }
            documents["workPhotos"] = workURLs.joined(separator: ",")

            try await FirestoreService.shared.updateTecnicoDocuments(
                tecnicoId: tecnicoId,
                documents: documents
            )

            navigateToEspera = true

        } catch {
            errorMessage = "Error al subir documentos. Verifica tu conexión."
        }

        isLoading = false
    }

    // MARK: - Image Binding

    private func imageBinding(for type: PhotoType?) -> Binding<UIImage?> {
        switch type {
        case .dniFront: return $dniFront
        case .dniBack: return $dniBack
        case .certificate: return $certificate
        case .selfie: return $selfie
        case .workPhoto:
            return Binding(
                get: { nil },
                set: { if let img = $0 { workPhotos.append(img) } }
            )
        case .none: return .constant(nil)
        }
    }
}

// MARK: - Document Upload Row

private struct DocumentUploadRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let image: UIImage?
    let isRequired: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .cornerRadius(8)
                        .clipped()
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.tecniPrimary)
                        .frame(width: 52, height: 52)
                        .background(Color.tecniPrimary.opacity(0.1))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(title).font(.subheadline.bold())
                        if isRequired {
                            Text("*").foregroundColor(.red).font(.caption)
                        }
                    }
                    Text(subtitle).font(.caption).foregroundColor(.tecniGray)
                }

                Spacer()

                Image(systemName: image != nil ? "checkmark.circle.fill" : "camera.fill")
                    .foregroundColor(image != nil ? .tecniMint : .tecniGray)
            }
            .padding()
            .tecniCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Image Picker

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
