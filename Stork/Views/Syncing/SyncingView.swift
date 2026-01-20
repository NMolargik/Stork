//
//  SyncingView.swift
//  Stork
//
//  Created by Nick Molargik on 1/20/26.
//

import SwiftUI
import SwiftData

struct SyncingView: View {
    @Environment(UserManager.self) private var userManager
    @Environment(DeliveryManager.self) private var deliveryManager

    var onSyncComplete: (Bool) -> Void

    @State private var statusMessage: String = "Checking for your data..."
    @State private var hasTimedOut: Bool = false
    @State private var dotCount: Int = 0
    @State private var timeoutTask: Task<Void, Never>?

    
    /// Maximum time to wait for sync before continuing (in seconds)
    private let syncTimeout: TimeInterval = 8

    /// Animated dots for the loading indicator
    private var animatedDots: String {
        String(repeating: ".", count: dotCount)
    }


    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // Animated edge gradients
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                EdgeGradientsView(time: time)
            }

            // Main content
            VStack(spacing: 24) {
                Spacer()
                
                // iCloud icon with animation
                Image(systemName: "icloud.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: .repeating)
                    .accessibilityHidden(true)
                
                VStack(spacing: 12) {
                    Text("Stork is Syncing with iCloud")
                        .font(.title2)
                        .bold()
                    
                    Text(statusMessage + animatedDots)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .frame(width: 300)
                        .frame(height: 20)
                }
                
                Spacer()
                
                // Progress indicator
                ProgressView()
                    .controlSize(.large)
                    .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            startSyncCheck()
            startDotAnimation()
        }
        .onDisappear {
            timeoutTask?.cancel()
        }
        .task {
            startSyncCheck()
        }
    }
    
    /// Animates the loading dots
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if hasTimedOut {
                timer.invalidate()
                return
            }
            withAnimation {
                dotCount = (dotCount + 1) % 4
            }
        }
    }


    private func startSyncCheck() {
        // Start the timeout timer
        timeoutTask = Task {
            try? await Task.sleep(for: .seconds(syncTimeout))

            guard !Task.isCancelled else { return }

            // Timeout reached - check what we have
            await MainActor.run {
                checkDataAndComplete()
            }
        }

        // Start checking for data
        Task {
            await performSyncCheck()
        }
    }

    private func performSyncCheck() async {
        // Update status
        await MainActor.run {
            statusMessage = "Looking for deliveries"
        }

        // Refresh user manager to get latest data
        await userManager.refresh()

        // Small delay to allow SwiftData/CloudKit sync
        try? await Task.sleep(for: .seconds(2))

        // Check if we have data
        let hasUser = userManager.currentUser != nil
        let hasDeliveries = !deliveryManager.deliveries.isEmpty

        // Cancel timeout if we found data
        if hasUser || hasDeliveries {
            timeoutTask?.cancel()

            await MainActor.run {
                statusMessage = hasDeliveries ? "Found your deliveries!" : "Ready to go!"
            }

            // Brief delay to show success message
            try? await Task.sleep(for: .seconds(0.5))

            await MainActor.run {
                onSyncComplete(hasDeliveries)
            }
        }
    }

    private func checkDataAndComplete() {
        let hasData = !deliveryManager.deliveries.isEmpty || userManager.currentUser != nil
        onSyncComplete(hasData)
    }
}

/// Animated gradient overlay for the syncing view edges
private struct EdgeGradientsView: View {
    let time: TimeInterval

    /// Speed multiplier for the pulsing animation (lower = slower)
    private let speed: Double = 2.0

    /// Compute a pulsing opacity value
    private func pulse(_ offset: Double, baseOpacity: Double = 0.35) -> Double {
        let wave = sin(time * speed + offset)
        // Map sin (-1 to 1) to opacity range (0.15 to baseOpacity)
        return baseOpacity * 0.4 + baseOpacity * 0.6 * (wave * 0.5 + 0.5)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            // Top edge gradient
            EllipticalGradient(
                colors: [
                    Color.storkOrange.opacity(pulse(0, baseOpacity: 0.5)),
                    Color.storkPurple.opacity(pulse(1, baseOpacity: 0.4)),
                    Color.clear
                ],
                center: .top,
                startRadiusFraction: 0,
                endRadiusFraction: 0.6
            )
            .frame(height: size.height * 0.5)
            .position(x: size.width / 2, y: 0)
            .blur(radius: 40)

            // Bottom edge gradient
            EllipticalGradient(
                colors: [
                    Color.storkPink.opacity(pulse(2, baseOpacity: 0.45)),
                    Color.storkBlue.opacity(pulse(3, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .bottom,
                startRadiusFraction: 0,
                endRadiusFraction: 0.6
            )
            .frame(height: size.height * 0.5)
            .position(x: size.width / 2, y: size.height)
            .blur(radius: 40)

            // Left edge gradient
            EllipticalGradient(
                colors: [
                    Color.storkOrange.opacity(pulse(4, baseOpacity: 0.4)),
                    Color.storkBlue.opacity(pulse(5, baseOpacity: 0.3)),
                    Color.clear
                ],
                center: .leading,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            .frame(width: size.width * 0.5)
            .position(x: 0, y: size.height / 2)
            .blur(radius: 30)

            // Right edge gradient
            EllipticalGradient(
                colors: [
                    Color.storkPink.opacity(pulse(6, baseOpacity: 0.45)),
                    Color.storkPurple.opacity(pulse(7, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .trailing,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            .frame(width: size.width * 0.5)
            .position(x: size.width, y: size.height / 2)
            .blur(radius: 30)

            // Corner accents - top left
            RadialGradient(
                colors: [
                    Color.storkOrange.opacity(pulse(0.5, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: size.width * 0.4
            )
            .blur(radius: 20)

            // Corner accents - top right
            RadialGradient(
                colors: [
                    Color.storkPurple.opacity(pulse(1.5, baseOpacity: 0.3)),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: size.width * 0.35
            )
            .blur(radius: 20)

            // Corner accents - bottom left
            RadialGradient(
                colors: [
                    Color.storkBlue.opacity(pulse(2.5, baseOpacity: 0.3)),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: size.width * 0.35
            )
            .blur(radius: 20)

            // Corner accents - bottom right
            RadialGradient(
                colors: [
                    Color.storkPink.opacity(pulse(3.5, baseOpacity: 0.35)),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: size.width * 0.4
            )
            .blur(radius: 20)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    let container: ModelContainer = {
        let schema = Schema([User.self, Delivery.self, Baby.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    return SyncingView { foundData in
        print("Sync complete, found data: \(foundData)")
    }
    .environment(UserManager(context: container.mainContext))
    .environment(DeliveryManager(context: container.mainContext))
    .modelContainer(container)
}
