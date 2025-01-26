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
    @State private var timerActive = false

    // Marble simulation states
    @StateObject private var marbleViewModel = MarbleViewModel()

    private let maxMarbleCount = 100
    private let marbleRadius: CGFloat = 15
    private let collisionIterations = 14
    private let gravity: CGFloat = 1.0
    private let damping: CGFloat = 0.98
    private let friction: CGFloat = 0.85

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Rectangle()
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .cornerRadius(20)
                    .shadow(color: colorScheme == .dark ? .white : .black, radius: 2)

                Text(headerText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    )
                    .padding(.top, 20)

                ZStack {
                    ForEach(marbleViewModel.marbles) { marble in
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
                }
                #if !SKIP
                .drawingGroup()
                #endif
                .offset(y: 10)
                
            }
            .onAppear {
                if isTestMode {
                    addTestMarbles(in: geometry.size)
                    timerActive = true
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
                if timerActive || isTestMode {
                    updateMarbles(in: geometry.size)
                }
            }
        }
    }

    private func refreshMarbles(in size: CGSize) {
        guard let deliveries = deliveries else { return }
        timerActive = true

        let newBabies = deliveriesForCurrentMonth(deliveries).flatMap { $0.babies }.filter {
            !marbleViewModel.displayedBabyIDs.contains($0.id)
        }

        for baby in newBabies {
            if marbleViewModel.marbles.count + marbleViewModel.pendingMarbles.count < maxMarbleCount {
                let newMarble = createMarble(in: size, color: baby.sex.color)
                marbleViewModel.pendingMarbles.append(newMarble)
                marbleViewModel.displayedBabyIDs.insert(baby.id)
            }
        }

        addPendingMarblesSequentially()
    }

    // 🔹 Test Mode: Instantly adds 35 marbles
    private func addTestMarbles(in size: CGSize) {
        Task {
            let testColors: [Color] = [Color("storkBlue"), Color("storkPink"), Color("storkPurple")]
            timerActive = true // ✅ Ensure marbles update properly

            for _ in 0..<(isMusterTest ? 40 : 25) {
                let testMarble = createMarble(
                    in: size,
                    color: testColors.randomElement() ?? .gray
                )
                
                let velocityX: CGFloat = .random(in: -2.0...2.0)
                let velocityY: CGFloat = .random(in: -2.0...2.0)

                let movingMarble = Marble(
                    id: testMarble.id,
                    position: testMarble.position,
                    velocity: CGPoint(x: velocityX, y: velocityY),
                    marbleRadius: testMarble.marbleRadius,
                    color: testMarble.color
                )

                await MainActor.run {
                    marbleViewModel.marbles.append(movingMarble)
                }
                
                try? await Task.sleep(nanoseconds: 100_000_000) // Stagger slightly (0.03s delay)
            }
        }
    }
    
    // MARK: - Marble Addition Logic
    
    /// Adds pending marbles one at a time with a slight delay between each addition.
    private func addPendingMarblesSequentially() {
        // Prevent multiple addition tasks
        guard !marbleViewModel.isAddingMarbles else { return }
        guard !marbleViewModel.pendingMarbles.isEmpty else { return }
        
        marbleViewModel.isAddingMarbles = true
        
        Task {
            while !marbleViewModel.pendingMarbles.isEmpty {
                // Take the first pending marble
                let marble = marbleViewModel.pendingMarbles.removeFirst()
                
                // Add to marbles on the main thread
                await MainActor.run {
                    marbleViewModel.marbles.append(marble)
                }
                
                // Small delay to add marbles quickly but sequentially
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
            
            // Mark as done
            await MainActor.run {
                marbleViewModel.isAddingMarbles = false
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
            
            isOverlapping = marbleViewModel.marbles.contains { existingMarble in
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
        for i in marbleViewModel.marbles.indices {
            marbleViewModel.marbles[i].velocity.y += gravity
            marbleViewModel.marbles[i].velocity.x *= friction
            marbleViewModel.marbles[i].velocity.y *= friction
            marbleViewModel.marbles[i].velocity.x = min(max(marbleViewModel.marbles[i].velocity.x, -3.0), 3.0)
            marbleViewModel.marbles[i].velocity.y = min(max(marbleViewModel.marbles[i].velocity.y, -3.0), 3.0)
        }

        // Move marbles
        for i in marbleViewModel.marbles.indices {
            marbleViewModel.marbles[i].position.x += marbleViewModel.marbles[i].velocity.x
            marbleViewModel.marbles[i].position.y += marbleViewModel.marbles[i].velocity.y
        }

        // Collision resolution
        for _ in 0..<collisionIterations {
            for i in 0..<marbleViewModel.marbles.count {
                for j in (i + 1)..<marbleViewModel.marbles.count {
                    var m1 = marbleViewModel.marbles[i]
                    var m2 = marbleViewModel.marbles[j]
                    resolveCollision(between: &m1, and: &m2)
                    marbleViewModel.marbles[i] = m1
                    marbleViewModel.marbles[j] = m2
                }
            }
        }

        // Constrain to container
        for i in marbleViewModel.marbles.indices {
            let r = marbleViewModel.marbles[i].marbleRadius
            if marbleViewModel.marbles[i].position.x < r {
                marbleViewModel.marbles[i].position.x = r
                marbleViewModel.marbles[i].velocity.x *= -damping
            } else if marbleViewModel.marbles[i].position.x > size.width - r {
                marbleViewModel.marbles[i].position.x = size.width - r
                marbleViewModel.marbles[i].velocity.x *= -damping
            }

            if marbleViewModel.marbles[i].position.y < r {
                marbleViewModel.marbles[i].position.y = r
                marbleViewModel.marbles[i].velocity.y *= -damping
            } else if marbleViewModel.marbles[i].position.y > size.height - r {
                marbleViewModel.marbles[i].position.y = size.height - r
                marbleViewModel.marbles[i].velocity.y *= -damping
            }
        }

        // Apply additional stabilization
        applyPressureCompensation(for: size)
        applyDynamicFriction(for: size)
        preventBottomOverlap(for: size)

        // Stop jittering marbles
        let velocityThreshold: CGFloat = 0.1
        for i in marbleViewModel.marbles.indices {
            if abs(marbleViewModel.marbles[i].velocity.x) < velocityThreshold &&
                abs(marbleViewModel.marbles[i].velocity.y) < velocityThreshold {
                marbleViewModel.marbles[i].velocity = .zero
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
        for i in marbleViewModel.marbles.indices {
            if marbleViewModel.marbles[i].position.y > size.height - marbleViewModel.marbles[i].marbleRadius * 2 {
                marbleViewModel.marbles[i].position.y = size.height - marbleViewModel.marbles[i].marbleRadius * 2
                marbleViewModel.marbles[i].velocity.y = 0
            }
        }
    }
    
    private func applyPressureCompensation(for size: CGSize) {
        let bottomThreshold = size.height * 0.9  // Near the bottom
        for i in marbleViewModel.marbles.indices {
            if marbleViewModel.marbles[i].position.y > bottomThreshold {
                // Apply resistance to downward velocity
                marbleViewModel.marbles[i].velocity.y *= 0.5
            }
        }
    }
    
    private func applyDynamicFriction(for size: CGSize) {
        for i in marbleViewModel.marbles.indices {
            if marbleViewModel.marbles[i].position.y > size.height * 0.8 {
                marbleViewModel.marbles[i].velocity.x *= 0.9  // Increase friction horizontally
                marbleViewModel.marbles[i].velocity.y *= 0.9  // Increase friction vertically
            }
        }
    }
}
