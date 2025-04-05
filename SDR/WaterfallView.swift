import SwiftUI

struct WaterfallView: View {
    let data: [[Float]]
    let height: CGFloat
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [.black, .blue, .cyan, .green, .yellow, .red, .white]),
        startPoint: .bottom,
        endPoint: .top
    )
    
    var body: some View {
        GeometryReader { geometry in
            if !data.isEmpty {
                let width = geometry.size.width
                let height = geometry.size.height
                let step = width / CGFloat(data[0].count - 1)
                
                ForEach(0..<data.count, id: \.self) { row in
                    Path { path in
                        let y = height * CGFloat(row) / CGFloat(data.count)
                        
                        path.move(to: CGPoint(x: 0, y: y))
                        
                        for i in 0..<data[row].count {
                            let x = CGFloat(i) * step
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color(white: CGFloat(data[row][0])), lineWidth: height / CGFloat(data.count))
                }
            }
        }
        .frame(height: height)
    }
}

#Preview {
    WaterfallView(data: [
        [0.1, 0.3, 0.5, 0.7, 0.9, 0.7, 0.5, 0.3, 0.1],
        [0.2, 0.4, 0.6, 0.8, 1.0, 0.8, 0.6, 0.4, 0.2],
        [0.1, 0.3, 0.5, 0.7, 0.9, 0.7, 0.5, 0.3, 0.1]
    ], height: 200)
} 