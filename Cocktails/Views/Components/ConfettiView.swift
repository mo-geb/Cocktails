import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = []
    @State private var startDate = Date()

    private let duration = 3.5

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1 / 60)) { timeline in
                Canvas { context, _ in
                    let elapsed = timeline.date.timeIntervalSince(startDate)
                    guard elapsed < duration else { return }
                    for p in particles {
                        let t = max(0, elapsed - p.delay)
                        guard t > 0 else { continue }
                        let x = p.x0 + p.vx * t
                        let y = p.y0 + p.vy * t + 0.5 * 380 * t * t
                        let rot = (p.rotation0 + p.rotationSpeed * t) * .pi / 180
                        let fadeStart = duration - 1.2
                        let opacity = elapsed > fadeStart ? max(0, 1 - (elapsed - fadeStart) / 1.2) : 1
                        let transform = CGAffineTransform(translationX: x, y: y).rotated(by: rot)
                        let rect = CGRect(x: -p.w / 2, y: -p.h / 2, width: p.w, height: p.h)
                        context.fill(Path(rect).applying(transform), with: .color(p.color.opacity(opacity)))
                    }
                }
            }
            .onAppear { spawn(in: geo.size) }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func spawn(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint]
        particles = (0..<160).map { _ in
            Particle(
                x0: .random(in: 0...size.width),
                y0: .random(in: -80 ... -10),
                vx: .random(in: -80...80),
                vy: .random(in: 40...160),
                rotation0: .random(in: 0...360),
                rotationSpeed: .random(in: -300...300),
                color: colors.randomElement()!,
                w: .random(in: 8...14),
                h: .random(in: 4...8),
                delay: .random(in: 0...0.5)
            )
        }
        startDate = Date()
    }
}

private struct Particle {
    let x0, y0, vx, vy, rotation0, rotationSpeed: Double
    let color: Color
    let w, h, delay: Double
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        ConfettiView()
    }
}
