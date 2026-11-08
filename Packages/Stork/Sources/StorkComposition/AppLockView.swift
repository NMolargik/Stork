//
//  AppLockView.swift
//  StorkComposition
//
//  The cover shown while the optional privacy lock is engaged. Prompts for Face ID (or
//  passcode) as soon as the app is active, with a button to try again.
//

#if os(iOS)
import SwiftUI
import StorkDesignSystem
import StorkServices

struct AppLockView: View {
    var lock: AppLockController
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Rectangle().fill(.background).ignoresSafeArea()
            VStack(spacing: 20) {
                Image("storkicon")
                    .resizable().scaledToFit().frame(width: 56, height: 56)
                    .foregroundStyle(.storkPurple)
                    .accessibilityHidden(true)
                Text("Stork is locked", bundle: .module).font(.title2.bold())
                if lock.isLocked {
                    Button { unlock() } label: {
                        Label(String(localized: "Unlock", bundle: .module), systemImage: "faceid")
                            .font(.headline).padding(.horizontal, 12)
                    }
                    .buttonStyle(.borderedProminent).tint(.storkBlue).controlSize(.large)
                    .disabled(lock.isAuthenticating)
                    if lock.lastFailure == .failed {
                        Text("That did not work. Try again.", bundle: .module).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .task(id: scenePhase) {
            if scenePhase == .active { unlock() }
        }
        .accessibilityElement(children: .contain)
    }

    private func unlock() {
        Task { await lock.unlock(reason: String(localized: "Unlock Stork to see your births.", bundle: .module)) }
    }
}
#endif
