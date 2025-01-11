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

    /// The deliveries coming in from elsewhere in the app
    @Binding var deliveries: [Delivery]
    let headerText: String

    // Marble simulation states
    @State private var marbles: [Marble] = []
    @State private var pendingMarbles: [Marble] = []
    @State private var displayedBabyIDs: Set<String> = []
    @State private var isAddingMarbles: Bool = false
    
    private let maxMarbleCount = 100
    private let marbleRadius: CGFloat = 12
    private let collisionIterations = 15
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
            }
            .onAppear {
                refreshMarbles(in: geometry.size)
            }
            .onChange(of: deliveries) { _ in
                refreshMarbles(in: geometry.size)
            }
            .onReceive(timer) { _ in
                updateMarbles(in: geometry.size)
            }
        }
    }
    
    private func refreshMarbles(in size: CGSize) {
        // DEBUG: Print how many deliveries JarView is actually receiving.
        print("DEBUG: JarView received deliveries: \(deliveries.count)")

        let monthDeliveries = deliveriesForCurrentMonth(deliveries)
        
        // DEBUG: Print the filtered deliveries for the current month.
        print("DEBUG: monthDeliveries count = \(monthDeliveries.count)")
        for d in monthDeliveries {
            print("DEBUG:   - Delivery ID: \(d.id), date: \(d.date)")
        }

        // Filter babies not already displayed
        let newBabies = monthDeliveries.flatMap { $0.babies }.filter {
            !displayedBabyIDs.contains($0.id)
        }

        // DEBUG: Print how many *new* babies we found (i.e., not in displayedBabyIDs).
        print("DEBUG: newBabies count = \(newBabies.count)")
        for baby in newBabies {
            print("DEBUG:   - Baby ID: \(baby.id), sex: \(baby.sex)")
        }
        
        // Add new marbles to pending list
        for baby in newBabies {
            if marbles.count + pendingMarbles.count < maxMarbleCount {
                let newMarble = createMarble(in: size, color: baby.sex.color)
                pendingMarbles.append(newMarble)
                displayedBabyIDs.insert(baby.id)
            }
        }
        
        // Add pending marbles sequentially
        addPendingMarblesSequentially()
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
            velocity: Velocity(
                dx: .random(in: -1.0...1.0),
                dy: .random(in: -1.0...1.0)
            ),
            marbleRadius: marbleRadius,
            color: color
        )
    }
    
    /// Applies all the physics steps each frame
    private func updateMarbles(in size: CGSize) {
        // Gravity & friction
        for i in marbles.indices {
            marbles[i].velocity.dy += gravity
            marbles[i].velocity.dx *= friction
            marbles[i].velocity.dy *= friction
            marbles[i].velocity.dx = min(max(marbles[i].velocity.dx, -3.0), 3.0)
            marbles[i].velocity.dy = min(max(marbles[i].velocity.dy, -3.0), 3.0)
        }

        // Move marbles
        for i in marbles.indices {
            marbles[i].position.x += marbles[i].velocity.dx
            marbles[i].position.y += marbles[i].velocity.dy
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
                marbles[i].velocity.dx *= -damping
            } else if marbles[i].position.x > size.width - r {
                marbles[i].position.x = size.width - r
                marbles[i].velocity.dx *= -damping
            }

            if marbles[i].position.y < r {
                marbles[i].position.y = r
                marbles[i].velocity.dy *= -damping
            } else if marbles[i].position.y > size.height - r {
                marbles[i].position.y = size.height - r
                marbles[i].velocity.dy *= -damping
            }
        }

        // Apply additional stabilization
        applyPressureCompensation(for: size)
        applyDynamicFriction(for: size)
        preventBottomOverlap(for: size)

        // Stop jittering marbles
        let velocityThreshold: CGFloat = 0.1
        for i in marbles.indices {
            if abs(marbles[i].velocity.dx) < velocityThreshold &&
               abs(marbles[i].velocity.dy) < velocityThreshold {
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
            let relativeVelocityX = m1.velocity.dx - m2.velocity.dx
            let relativeVelocityY = m1.velocity.dy - m2.velocity.dy
            let velAlongNormal = relativeVelocityX * nx + relativeVelocityY * ny
            if velAlongNormal > 0 { return }

            let restitution: CGFloat = 0.4
            let impulse = -(1 + restitution) * velAlongNormal / 2

            let impulseX = impulse * nx
            let impulseY = impulse * ny
            m1.velocity.dx += impulseX
            m1.velocity.dy += impulseY
            m2.velocity.dx -= impulseX
            m2.velocity.dy -= impulseY
        }
    }
    
    private func preventBottomOverlap(for size: CGSize) {
        for i in marbles.indices {
            if marbles[i].position.y > size.height - marbles[i].marbleRadius * 2 {
                marbles[i].position.y = size.height - marbles[i].marbleRadius * 2
                marbles[i].velocity.dy = 0
            }
        }
    }
    
    private func applyPressureCompensation(for size: CGSize) {
        let bottomThreshold = size.height * 0.9  // Near the bottom
        for i in marbles.indices {
            if marbles[i].position.y > bottomThreshold {
                // Apply resistance to downward velocity
                marbles[i].velocity.dy *= 0.5
            }
        }
    }
    
    private func applyDynamicFriction(for size: CGSize) {
        for i in marbles.indices {
            if marbles[i].position.y > size.height * 0.8 {
                marbles[i].velocity.dx *= 0.9  // Increase friction horizontally
                marbles[i].velocity.dy *= 0.9  // Increase friction vertically
            }
        }
    }
}

// MARK: - Marble & Velocity
struct Marble: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: Velocity
    var marbleRadius: CGFloat
    var color: Color
    
    var diameter: CGFloat {
        marbleRadius * 2
    }
}

