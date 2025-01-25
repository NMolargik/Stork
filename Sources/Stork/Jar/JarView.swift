//
//  JarView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

import SwiftUI
import StorkModel

struct JarView: View {
    @Environment(\.colorScheme) var colorScheme

    /// The deliveries coming in from elsewhere in the app (optional for test mode)
    @Binding var deliveries: [Delivery]?
    let headerText: String
    let isTestMode: Bool
    let isMusterTest: Bool

    // Marble simulation states
    @State private var marbles: [Marble] = []
    @State private var pendingMarbles: [Marble] = []
    @State private var displayedBabyIDs: Set<String> = []
    @State private var isAddingMarbles: Bool = false

    private let maxMarbleCount = 100
    private let marbleRadius: CGFloat = 15
    private let collisionIterations = 14
    private let gravity: CGFloat = 1.0
    private let damping: CGFloat = 0.98
    private let friction: CGFloat = 0.85

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .cornerRadius(20)
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)

                VStack {
                    Text(headerText)
                        .padding(8)
                        .foregroundStyle(.gray)
                        .font(.headline)
                        .fontWeight(.bold)
                        .background {
                            Rectangle()
                                .foregroundStyle(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 2)
                        }
                        .padding(.top, 20)

                    Spacer()
                }

                ForEach(marbles) { marble in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(
                                    colors: [
                                        marble.color.opacity(0.6),
                                        marble.color
                                    ]
                                ),
                                center: .init(x: 0.35, y: 0.35),
                                startRadius: 5,
                                endRadius: marble.diameter / 2
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)
                        .frame(width: marble.diameter, height: marble.diameter)
                        .position(marble.position)
                }
                .offset(y: 10)
            }
            .onAppear {
                if isTestMode {
                    addTestMarbles(in: geometry.size) // 🔹 Test mode: Add 35 marbles
                } else {
                    refreshMarbles(in: geometry.size)
                }
            }
            .onChange(of: deliveries) { _ in
                if !isTestMode {
                    refreshMarbles(in: geometry.size)
                }
            }
            .onReceive(timer) { _ in
                updateMarbles(in: geometry.size)
            }
        }
    }

    private func refreshMarbles(in size: CGSize) {
        guard let deliveries = deliveries else { return } // Ignore if nil (non-test mode)

        let monthDeliveries = deliveriesForCurrentMonth(deliveries)

        let newBabies = monthDeliveries.flatMap { $0.babies }.filter {
            !displayedBabyIDs.contains($0.id)
        }

        for baby in newBabies {
            if marbles.count + pendingMarbles.count < maxMarbleCount {
                let newMarble = createMarble(in: size, color: baby.sex.color)
                pendingMarbles.append(newMarble)
                displayedBabyIDs.insert(baby.id)
            }
        }

        addPendingMarblesSequentially()
    }

    // 🔹 Test Mode: Instantly adds 35 marbles
    private func addTestMarbles(in size: CGSize) {
        Task {
            let testColors: [Color] = [Color("storkBlue"), Color("storkPink"), Color("storkPurple")]
            for _ in 0..<(isMusterTest ? 120 : 25) {
                let testMarble = createMarble(
                    in: size,
                    color: testColors.randomElement() ?? .gray
                )
                await MainActor.run {
                    marbles.append(testMarble)
                }
                try? await Task.sleep(nanoseconds: 30_000_000) // Stagger slightly (0.03s delay)
            }
        }
    }
    
    // MARK: - Marble Addition Logic
    
    /// Adds pending marbles one at a time with a slight delay between each addition.
    private func addPendingMarblesSequentially() {
        // Prevent multiple addition tasks
        guard !isAddingMarbles else { return }
        guard !pendingMarbles.isEmpty else { return }
        
        isAddingMarbles = true
        
        Task {
            while !pendingMarbles.isEmpty {
                // Take the first pending marble
                let marble = pendingMarbles.removeFirst()
                
                // Add to marbles on the main thread
                await MainActor.run {
                    marbles.append(marble)
                }
                
                // Small delay to add marbles quickly but sequentially
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
            
            // Mark as done
            await MainActor.run {
                isAddingMarbles = false
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Filters the given deliveries to only those that fall within the **current month**.
    /// For example, if today is Jan 6, 2025, this returns deliveries from Jan 1, 2025 to Jan 31, 2025.
    private func deliveriesForCurrentMonth(_ all: [Delivery]) -> [Delivery] {
        let calendar = Calendar.current
        let now = Date()
        
        // Start of this month
        guard let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) else {
            return []
        }
        
        // Start of next month
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)
        else {
            return []
        }
        
        // We want deliveries from [startOfMonth ..< startOfNextMonth)
        return all.filter { delivery in
            delivery.date >= startOfMonth && delivery.date < startOfNextMonth
        }
    }
    
    private func deliveriesForCurrentWeek() -> [Delivery] {
        let calendar = Calendar.current
        let now = Date()

        // Get start and end of the current week
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return []
        }
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return []
        }

        guard let deliveries = deliveries else {
            return []
        }
        // Filter deliveries within the week range
        return deliveries.filter { delivery in
            delivery.date >= weekStart && delivery.date <= weekEnd
        }
    }
    
    /// Creates a marble with random x-position and velocity, ensuring no initial overlap.
    /// Positions it in the top half of the container so it can fall down.
    /// - Parameters:
    ///   - size: The size of the container.
    ///   - color: The color of the marble based on baby's sex.
    /// - Returns: A new `Marble` instance.
    private func createMarble(in size: CGSize, color: Color) -> Marble {
        let minX = marbleRadius
        let maxX = max(marbleRadius, size.width - marbleRadius)
        let minY = marbleRadius
        let maxY = max(marbleRadius, size.height / 2)
        
        var position: CGPoint
        var attempts = 0
        let maxAttempts = 100
        var isOverlapping: Bool
        
        repeat {
            position = CGPoint(
                x: .random(in: minX...maxX),
                y: .random(in: minY...maxY)
            )
            
            isOverlapping = marbles.contains { existingMarble in
                let dx = existingMarble.position.x - position.x
                let dy = existingMarble.position.y - position.y
                let distance = sqrt(dx*dx + dy*dy)
                return distance < (existingMarble.marbleRadius + marbleRadius + 2)
            }
            
            attempts += 1
            if attempts >= maxAttempts {
                // If unable to find a non-overlapping position, proceed anyway
                break
            }
        } while isOverlapping
        
        return Marble(
            id: UUID(),
            position: position,
            velocity: CGPoint(x: .random(in: -1.0...1.0), y: .random(in: -1.0...1.0)),
            marbleRadius: marbleRadius,
            color: color
        )
    }
    
    /// Applies all the physics steps each frame
    private func updateMarbles(in size: CGSize) {
        // Gravity & friction
        for i in marbles.indices {
            marbles[i].velocity.y += gravity
            marbles[i].velocity.x *= friction
            marbles[i].velocity.y *= friction
            marbles[i].velocity.x = min(max(marbles[i].velocity.x, -3.0), 3.0)
            marbles[i].velocity.y = min(max(marbles[i].velocity.y, -3.0), 3.0)
        }

        // Move marbles
        for i in marbles.indices {
            marbles[i].position.x += marbles[i].velocity.x
            marbles[i].position.y += marbles[i].velocity.y
        }

        // Collision resolution
        for _ in 0..<collisionIterations {
            for i in 0..<marbles.count {
                for j in (i + 1)..<marbles.count {
                    var m1 = marbles[i]
                    var m2 = marbles[j]
                    resolveCollision(between: &m1, and: &m2)
                    marbles[i] = m1
                    marbles[j] = m2
                }
            }
        }

        // Constrain to container
        for i in marbles.indices {
            let r = marbles[i].marbleRadius
            if marbles[i].position.x < r {
                marbles[i].position.x = r
                marbles[i].velocity.x *= -damping
            } else if marbles[i].position.x > size.width - r {
                marbles[i].position.x = size.width - r
                marbles[i].velocity.x *= -damping
            }

            if marbles[i].position.y < r {
                marbles[i].position.y = r
                marbles[i].velocity.y *= -damping
            } else if marbles[i].position.y > size.height - r {
                marbles[i].position.y = size.height - r
                marbles[i].velocity.y *= -damping
            }
        }

        // Apply additional stabilization
        applyPressureCompensation(for: size)
        applyDynamicFriction(for: size)
        preventBottomOverlap(for: size)

        // Stop jittering marbles
        let velocityThreshold: CGFloat = 0.1
        for i in marbles.indices {
            if abs(marbles[i].velocity.x) < velocityThreshold &&
               abs(marbles[i].velocity.y) < velocityThreshold {
                marbles[i].velocity = .zero
            }
        }
    }
    
    /// Collision resolution for two circles (marbles) of equal mass
    private func resolveCollision(between m1: inout Marble, and m2: inout Marble) {
        let dx = m2.position.x - m1.position.x
        let dy = m2.position.y - m1.position.y
        let distance = sqrt(dx * dx + dy * dy)
        let minDist = m1.marbleRadius + m2.marbleRadius

        if distance < minDist {
            let overlap = 0.5 * (minDist - distance)
            let nx = dx / (distance == 0.0 ? 0.1 : distance)
            let ny = dy / (distance == 0.0 ? 0.1 : distance)

            m1.position.x -= overlap * nx
            m1.position.y -= overlap * ny
            m2.position.x += overlap * nx
            m2.position.y += overlap * ny

            // Prevent sinking under pressure
            if m1.position.y > m2.position.y {
                m1.position.y -= overlap * 0.5
            }

            // Velocity adjustments
            let relativeVelocityX = m1.velocity.x - m2.velocity.x
            let relativeVelocityY = m1.velocity.y - m2.velocity.y
            let velAlongNormal = relativeVelocityX * nx + relativeVelocityY * ny
            if velAlongNormal > 0 { return }

            let restitution: CGFloat = 0.4
            let impulse = -(1 + restitution) * velAlongNormal / 2

            let impulseX = impulse * nx
            let impulseY = impulse * ny
            m1.velocity.x += impulseX
            m1.velocity.y += impulseY
            m2.velocity.x -= impulseX
            m2.velocity.y -= impulseY
        }
    }
    
    private func preventBottomOverlap(for size: CGSize) {
        for i in marbles.indices {
            if marbles[i].position.y > size.height - marbles[i].marbleRadius * 2 {
                marbles[i].position.y = size.height - marbles[i].marbleRadius * 2
                marbles[i].velocity.y = 0
            }
        }
    }
    
    private func applyPressureCompensation(for size: CGSize) {
        let bottomThreshold = size.height * 0.9  // Near the bottom
        for i in marbles.indices {
            if marbles[i].position.y > bottomThreshold {
                // Apply resistance to downward velocity
                marbles[i].velocity.y *= 0.5
            }
        }
    }
    
    private func applyDynamicFriction(for size: CGSize) {
        for i in marbles.indices {
            if marbles[i].position.y > size.height * 0.8 {
                marbles[i].velocity.x *= 0.9  // Increase friction horizontally
                marbles[i].velocity.y *= 0.9  // Increase friction vertically
            }
        }
    }
}
