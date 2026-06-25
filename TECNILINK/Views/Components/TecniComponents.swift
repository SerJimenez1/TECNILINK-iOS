import SwiftUI

// MARK: - Text Fields

struct TecniTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

struct TecniSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            Group {
                if showPassword {
                    TextField(placeholder, text: $text).foregroundColor(.white)
                } else {
                    SecureField(placeholder, text: $text).foregroundColor(.white)
                }
            }
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Badges & Stars

struct VerifiedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill").font(.caption2)
            Text("VERIFICADO").font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color.tecniMint)
        .cornerRadius(8)
    }
}

struct StarRatingView: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: icon(for: star)).font(.caption).foregroundColor(.yellow)
            }
            Text(String(format: "%.1f", rating)).font(.caption).foregroundColor(.tecniGray)
        }
    }

    private func icon(for star: Int) -> String {
        if Double(star) <= rating { return "star.fill" }
        if Double(star) - 0.5 <= rating { return "star.leadinghalf.filled" }
        return "star"
    }
}

// MARK: - Card modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func tecniCard() -> some View { modifier(CardStyle()) }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ServiceStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color(hex: status.colorHex))
            .cornerRadius(8)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 50)).foregroundColor(.tecniGray.opacity(0.4))
            Text(title).font(.headline).foregroundColor(.tecniGray)
            Text(subtitle).font(.subheadline).foregroundColor(.tecniGray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

// MARK: - Primary Button

struct TecniButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.headline).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Color.tecniAccent)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}
