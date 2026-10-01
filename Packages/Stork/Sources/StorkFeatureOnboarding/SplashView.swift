//
//  SplashView.swift
//  StorkFeatureOnboarding
//
//  Animated launch branding with a "Get Started" CTA.
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem

public struct SplashView: View {
    private let onContinue: () -> Void

    @State private var titleVisible = false
    @State private var subtitleVisible = false
    @State private var buttonVisible = false
    @State private var isPulsing = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        VStack {
            Spacer()

            Text("Stork", bundle: .module)
                .font(.system(size: hSizeClass == .regular ? 90 : 60)).bold()
                .opacity(titleVisible ? 1 : 0)
                .scaleEffect(titleVisible ? 1 : 0.7)
                .animation(.easeOut(duration: 0.6), value: titleVisible)
                .padding(.bottom, 5)
                .accessibilityAddTraits(.isHeader)

            Text("for labor & delivery professionals", bundle: .module)
                .font(hSizeClass == .regular ? .title : .title3).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .opacity(subtitleVisible ? 1 : 0)
                .offset(y: subtitleVisible ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.8), value: subtitleVisible)

            Image("icon-purple-preview")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: hSizeClass == .regular ? 200 : 220)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                .opacity(subtitleVisible ? 1 : 0)
                .scaleEffect(subtitleVisible ? 1 : 0)
                .animation(.bouncy(duration: 0.6).delay(0.8), value: subtitleVisible)
                .padding()
                .accessibilityLabel(Text("Stork app logo", bundle: .module))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { isPulsing = true }
                }

            Spacer()

            Button {
                Haptics.lightImpact()
                onContinue()
            } label: {
                HStack(spacing: 8) {
                    Text("Get Started", bundle: .module).bold()
                    Image(systemName: "arrow.right.circle.fill")
                }
                .padding()
                .frame(maxWidth: 250)
                .background(Color.storkPurple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .opacity(buttonVisible ? 1 : 0)
            .scaleEffect(buttonVisible ? 1 : 0.98)
            .animation(.easeOut(duration: 0.5).delay(1.2), value: buttonVisible)
            .accessibilityLabel(Text("Get Started", bundle: .module))
            .accessibilityHint(Text("Tap to begin using Stork", bundle: .module))

            Spacer()
        }
        .onAppear {
            withAnimation { titleVisible = true }
            withAnimation(.easeOut.delay(0.18)) { subtitleVisible = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) { buttonVisible = true }
        }
        .padding(.top, hSizeClass == .regular ? 40 : 80)
        .frame(maxWidth: hSizeClass == .regular ? 520 : .infinity)
        .padding(.horizontal, 24)
    }
}
#endif
