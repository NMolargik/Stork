//
//  ToastView.swift
//  Stork
//
//  Top-of-screen toast rendering for ToastManager (ported from Opalite).
//

import SwiftUI

struct ToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void

    var body: some View {
        toastContent
            .padding(.horizontal, 16)
            .frame(maxWidth: 300)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
    }

    @ViewBuilder
    private var toastContent: some View {
        #if os(visionOS)
        toastBody
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(toast.style.backgroundColor.gradient)
                    .shadow(color: toast.style.backgroundColor.opacity(0.3), radius: 8, y: 4)
            )
        #else
        toastBody
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.tint(toast.style.backgroundColor).interactive())
        #endif
    }

    private var toastBody: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.icon ?? toast.style.iconName)
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityHidden(true)

            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Button {
                Haptics.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
    }
}

// MARK: - Toast Container Modifier

struct ToastContainerModifier: ViewModifier {
    @Environment(ToastManager.self) private var toastManager

    /// iPad anchors toasts to the top-leading corner so they don't crowd
    /// the split-view title area.
    private var isIPad: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: isIPad ? .topLeading : .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .id(toast.id)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
    }
}

extension View {
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}

#Preview("Toast Styles") {
    struct PreviewContainer: View {
        @State private var toastManager = ToastManager()

        var body: some View {
            VStack(spacing: 20) {
                Button("Show Success") {
                    toastManager.showSuccess("Delivery saved")
                }
                Button("Show Info") {
                    toastManager.show(message: "Syncing with iCloud…", style: .info, icon: "icloud.fill")
                }
                Button("Show Error") {
                    toastManager.show(message: "Something went wrong", style: .error)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toastContainer()
            .environment(toastManager)
        }
    }
    return PreviewContainer()
}
