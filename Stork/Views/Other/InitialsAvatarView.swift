import SwiftUI

/// A reusable circular avatar that displays two initials derived from
/// a user's first and last name. Intended for use when no profile image is available.
struct InitialsAvatarView: View {
    let firstName: String
    let lastName: String
    var size: CGFloat = 48
    var backgroundColor: Color = .storkPurple
    var textColor: Color = .white
    var fontWeight: Font.Weight = .semibold

    private var initials: String {
        let firstInitial = firstName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)
        let lastInitial = lastName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)
        return (firstInitial + lastInitial).uppercased()
    }

    var body: some View {
        ZStack {
            Circle().fill(backgroundColor)
            Text(initials)
                .font(.system(size: max(10, size * 0.42), weight: fontWeight))
                .foregroundStyle(textColor)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(avatarAccessibilityLabel)
    }

    private var avatarAccessibilityLabel: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedFirst.isEmpty && trimmedLast.isEmpty {
            return "User avatar"
        } else {
            return "User avatar, \(trimmedFirst) \(trimmedLast)"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        InitialsAvatarView(firstName: "Alex", lastName: "Chen", size: 48)
        InitialsAvatarView(firstName: "a", lastName: "c", size: 64, backgroundColor: .storkPurple, textColor: .white)
        InitialsAvatarView(firstName: "Alex", lastName: "", size: 48) // first names only
    }
    .padding()
}
