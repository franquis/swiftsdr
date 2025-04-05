import SwiftUI

struct SpectrumView: View {
    let data: [Float]
    let height: CGFloat
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [.blue, .cyan, .green, .yellow, .red]),
        startPoint: .bottom,
        endPoint: .top
    )
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let step = width / CGFloat(data.count - 1)
                
                path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(data[0]))))
                
                for i in 1..<data.count {
                    let x = CGFloat(i) * step
                    let y = height * (1 - CGFloat(data[i]))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(gradient, lineWidth: 2)
        }
        .frame(height: height)
    }
}

#Preview {
    SpectrumView(data: [0.1, 0.3, 0.5, 0.7, 0.9, 0.7, 0.5, 0.3, 0.1], height: 150)
} 