import SwiftUI

struct ParticleView: View {
    // Example parameters you can tweak
    @State private var marbles: [Marble] = []
    @State private var gravity: CGFloat = 0.4
    @State private var damping: CGFloat = 0.9     // how much velocity we lose on collisions
    @State private var friction: CGFloat = 0.99   // how much velocity we lose each frame
    @State private var marbleCount: Int = 20      // how many marbles to generate

    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw a "glass" shape as background (optional)
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.blue.opacity(0.5), lineWidth: 2)
                
                // Draw marbles
                ForEach(marbles) { marble in
                    Circle()
                        .fill(marble.color)
                        .frame(width: marble.diameter, height: marble.diameter)
                        .position(marble.position)
                }
            }
            .onAppear {
                initializeMarbles(in: geometry.size)
            }
            .onReceive(timer) { _ in
                updateMarbles(in: geometry.size)
            }
        }
    }
    
    private func initializeMarbles(in size: CGSize) {
        // If the view is really small, ensure at least 1x1 so random(in: ...) doesn't crash
        let safeWidth = max(size.width, 1)
        let safeHeight = max(size.height, 1)

        marbles = (0..<marbleCount).map { _ in
            let radius = CGFloat.random(in: 12.0...20.0)
            
            // Make sure we never form an invalid range for X
            let minX = radius
            let maxX = max(radius, safeWidth - radius)
            let x = CGFloat.random(in: minX...maxX)
            
            // Similarly for Y. If you only want them in the top half, clamp that as well
            let minY = radius
            let maxY = max(radius, safeHeight / 2)
            let y = CGFloat.random(in: minY...maxY)

            return Marble(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                velocity: Velocity(
                    dx: CGFloat.random(in: -1.0...1.0),
                    dy: CGFloat.random(in: -1.0...1.0)
                ),
                radius: radius,
                color: Color(
                    red: CGFloat.random(in: 0.0...1.0),
                    green: CGFloat.random(in: 0.0...1.0),
                    blue: CGFloat.random(in: 0.0...1.0)
                )
            )
        }
    }
    
    private func updateMarbles(in size: CGSize) {
        // Step 1: Apply gravity and friction
        for i in marbles.indices {
            // Apply gravity
            marbles[i].velocity.dy += gravity
            // Apply friction (slows them slightly every frame)
            marbles[i].velocity.dx *= friction
            marbles[i].velocity.dy *= friction
        }
        
        // Step 2: Move marbles
        for i in marbles.indices {
            marbles[i].position.x += marbles[i].velocity.dx
            marbles[i].position.y += marbles[i].velocity.dy
        }
        
        // Step 3: Marble–marble collisions (naive O(n^2) approach)
        for i in 0..<marbles.count {
            for j in (i+1)..<marbles.count {
                var m1 = marbles[i]
                var m2 = marbles[j]
                resolveCollision(between: &m1, and: &m2)
                marbles[i] = m1
                marbles[j] = m2
            }
        }
        
        // Step 4: Constrain to rectangle bounds (unchanged)
        for i in marbles.indices {
            let r = marbles[i].radius
            // Left / Right wall collisions
            if marbles[i].position.x < r {
                marbles[i].position.x = r
                marbles[i].velocity.dx *= -damping
            } else if marbles[i].position.x > size.width - r {
                marbles[i].position.x = size.width - r
                marbles[i].velocity.dx *= -damping
            }
            
            // Top / Bottom wall collisions
            if marbles[i].position.y < r {
                marbles[i].position.y = r
                marbles[i].velocity.dy *= -damping
            } else if marbles[i].position.y > size.height - r {
                marbles[i].position.y = size.height - r
                marbles[i].velocity.dy *= -damping
            }
        }
        
        // Step 5: Snap to zero if velocity is very small
        let velocityThreshold: CGFloat = 0.2
        for i in marbles.indices {
            if abs(marbles[i].velocity.dx) < velocityThreshold &&
               abs(marbles[i].velocity.dy) < velocityThreshold {
                marbles[i].velocity = .zero
            }
        }
    }
    
    /// Basic collision resolution for two circles (marbles) of equal mass
    private func resolveCollision(between m1: inout Marble, and m2: inout Marble) {
        let dx = m2.position.x - m1.position.x
        let dy = m2.position.y - m1.position.y
        let distance = sqrt(dx*dx + dy*dy)
        let minDist = m1.radius + m2.radius
        
        // If they're overlapping
        if distance < minDist {
            // Move them so they no longer overlap
            let overlap = 0.5 * (minDist - distance)
            let nx = dx / distance   // normal x
            let ny = dy / distance   // normal y
            
            m1.position.x -= overlap * nx
            m1.position.y -= overlap * ny
            m2.position.x += overlap * nx
            m2.position.y += overlap * ny
            
            // Now do a "perfectly elastic" collision, but damped
            // For simplicity, assume equal mass
            let kx = (m1.velocity.dx - m2.velocity.dx)
            let ky = (m1.velocity.dy - m2.velocity.dy)
            let p = (kx * nx + ky * ny) / 2
            // Multiply by a damping factor to mimic inelastic collisions
            let restitution: CGFloat = 0.9
            
            m1.velocity.dx -= p * nx * restitution
            m1.velocity.dy -= p * ny * restitution
            m2.velocity.dx += p * nx * restitution
            m2.velocity.dy += p * ny * restitution
        }
    }
}

struct Marble: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: Velocity   // <-- replaced CGVector with our custom Velocity
    var radius: CGFloat
    var color: Color
    
    var diameter: CGFloat {
        radius * 2
    }
}

// Custom velocity struct
struct Velocity {
    var dx: CGFloat
    var dy: CGFloat
    
    static var zero: Velocity {
        Velocity(dx: 0, dy: 0)
    }
}

#Preview {
    ParticleView()
}
