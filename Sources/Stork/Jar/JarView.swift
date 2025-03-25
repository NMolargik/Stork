//
//  JarView.swift
//  skipapp-stork
//
//  Created by Nick Molargik on 01/01/25.
//

import SwiftUI
import StorkModel

struct JarView: View {
    @EnvironmentObject var appStorageManager: AppStorageManager
    
    /// The deliveries coming in from elsewhere in the app (optional for test mode)
    @Binding var deliveries: [Delivery]?
    @State private var timerActive = false
    let isMuster: Bool

    // Marble simulation states
    @State var marbles: [Marble] = []
    @State var pendingMarbles: [Marble] = []
    @State var displayedBabyIDs: Set<String> = []
    @State var isAddingMarbles: Bool = false
    
    let headerText: String
    let isTestMode: Bool

    private let maxMarbleCount = 200
    private let collisionIterations = 14
    private let gravity: CGFloat = 1.0
    private let damping: CGFloat = 0.98
    private let friction: CGFloat = 0.85

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Rectangle()
                    .foregroundStyle(appStorageManager.useDarkMode ? .black : .white)
                    .cornerRadius(20)
                    .shadow(color: appStorageManager.useDarkMode ? .white : .black, radius: 2)

                Text(headerText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
                    .padding(8)
                    .backgroundCard(colorScheme: appStorageManager.useDarkMode ? .dark : .light)
                    .padding(.top, 20)

                ZStack {
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

                    // Only stop the simulation if:
                    // - There are no pending marbles, AND
                    // - There are no marbles with significant velocity.
                    // For marbles near the bottom (>=80% of the jar height), use a lower vertical threshold.
                    if pendingMarbles.isEmpty &&
                       !marbles.contains(where: {
                           // Use a lower vertical threshold for marbles near the bottom.
                           let verticalThreshold: CGFloat = $0.position.y < (geometry.size.height * 0.8) ? 0.02 : 0.005
                           let isActive = abs($0.velocity.x) > 0.02 || (abs($0.velocity.y) > verticalThreshold)
                           return isActive
                       }) {
                        timerActive = false
                    }
                }
            }
        }
    }

    private func refreshMarbles(in size: CGSize) {
        guard let deliveries = deliveries else { return }
        timerActive = true

        // Use the week-based filter here and filter out babies that already have a marble.
        let newBabies = deliveriesForCurrentMonth(deliveries)
            .flatMap { $0.babies }
            .filter { !displayedBabyIDs.contains($0.id) }

        for baby in newBabies {
            if marbles.count + pendingMarbles.count < maxMarbleCount {
                let newMarble = createMarble(in: size, color: baby.sex.color)
                pendingMarbles.append(newMarble)
                displayedBabyIDs.insert(baby.id)
            }
        }
        
        // If any marbles are stationary (likely because the view just regenerated), give them an initial velocity.
        for i in marbles.indices {
            let marble = marbles[i]
            if abs(marble.velocity.x) < 0.01 && abs(marble.velocity.y) < 0.01 {
                marbles[i].velocity = CGPoint(
                    x: .random(in: -1.0...1.0),
                    y: .random(in: 1.0...3.0) // a positive y velocity so they fall
                )
            }
        }

        addPendingMarblesSequentially()
    }

    private func addTestMarbles(in size: CGSize) {
        Task {
            let testColors: [Color] = [Color("storkBlue"), Color("storkPink"), Color("storkPurple")]
            timerActive = true // ✅ Ensure marbles update properly

            for _ in 0..<(isMuster ? 40 : 25) {
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
                    marbles.append(movingMarble)
                }
                
                try? await Task.sleep(nanoseconds: 100_000_000) // Stagger slightly (0.03s delay)
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
    
    private func deliveriesForCurrentWeek(_ all: [Delivery]) -> [Delivery] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: now)
        
        // Calculate the most recent Sunday.
        let daysSinceSunday = weekday - 1
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysSinceSunday, to: today) else {
            return []
        }
        
        // Calculate the upcoming Saturday.
        guard let saturday = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return []
        }
        let saturdayStart = calendar.startOfDay(for: saturday)
        
        // Get the start of next Sunday and subtract one second to get the end of Saturday (23:59:59).
        guard let startOfNextSunday = calendar.date(byAdding: .day, value: 1, to: saturdayStart) else {
            return []
        }
        let endOfWeek = startOfNextSunday.addingTimeInterval(-1)
        
        return all.filter { delivery in
            delivery.date >= startOfWeek && delivery.date <= endOfWeek
        }
    }
    
    /// Creates a marble with random x-position and velocity, ensuring no initial overlap.
    /// Positions it in the top half of the container so it can fall down.
    /// - Parameters:
    ///   - size: The size of the container.
    ///   - color: The color of the marble based on baby's sex.
    /// - Returns: A new `Marble` instance.
    private func createMarble(in size: CGSize, color: Color) -> Marble {
        let minX = isMuster ? 12.0 : 16.0
        let maxX = max(isMuster ? 12.0 : 16.0, size.width - (isMuster ? 12.0 : 16.0))
        let minY = isMuster ? 12.0 : 16.0
        let maxY = max(isMuster ? 12.0 : 16.0, size.height / 2)
        
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
                let distance = sqrt(dx * dx + dy * dy)
                return distance < (existingMarble.marbleRadius + (isMuster ? 12.0 : 16.0) + 2)
            }
            
            attempts += 1
            if attempts >= maxAttempts { break }
        } while isOverlapping
        
        // Assign a stronger initial velocity
        let initialVelocityX = CGFloat.random(in: -2.0...2.0)
        let initialVelocityY = CGFloat.random(in: 1.0...3.0)  // positive so they fall
        return Marble(
            id: UUID(),
            position: position,
            velocity: CGPoint(x: initialVelocityX, y: initialVelocityY),
            marbleRadius: isMuster ? 12.0 : 16.0,
            color: color
        )
    }
    
    /// Applies all the physics steps each frame
    private func updateMarbles(in size: CGSize) {

        // Apply gravity and friction
        for i in marbles.indices {
            var marble = marbles[i]
            
            // Apply gravity and friction
            marble.velocity.y += gravity
            marble.velocity.x *= friction
            marble.velocity.y *= friction
            marble.velocity.x = min(max(marble.velocity.x, -3.0), 3.0)
            marble.velocity.y = min(max(marble.velocity.y, -3.0), 3.0)
            
            
            marbles[i] = marble
        }
        
        // Move marbles
        for i in marbles.indices {
            marbles[i].position.x += marbles[i].velocity.x
            marbles[i].position.y += marbles[i].velocity.y
        }

        // Dynamically reduce collision iterations
        let activeMarbles = marbles.filter {
            abs($0.velocity.x) > 0.05 || abs($0.velocity.y) > 0.05
        }
        let dynamicCollisionIterations = max(3, min(14, activeMarbles.count / 5))

        for _ in 0..<dynamicCollisionIterations {
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

        // Detect and stop small oscillations
        let velocityThreshold: CGFloat = 0.05
        let maxSettledFrames = 20  // Increased to allow more frames before freezing

        for i in marbles.indices {
            var marble = marbles[i]

            if abs(marble.velocity.x) < velocityThreshold && abs(marble.velocity.y) < velocityThreshold {
                marble.settledFrames += 1
            } else {
                marble.settledFrames = 0
            }

            // Only stop the marble if it has been moving very little for a while AND it's near the bottom.
            if marble.settledFrames >= maxSettledFrames && marble.position.y > (size.height * 0.8) {
                marble.velocity = .zero
            }

            marbles[i] = marble
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
