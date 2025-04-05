import SwiftUI

struct SpectrumView: View {
    let data: [Float]
    let height: CGFloat
    let minDB: Float = -100
    let maxDB: Float = 0
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let step = width / CGFloat(data.count)
                
                path.move(to: CGPoint(x: 0, y: height))
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * step
                    let normalizedValue = CGFloat((value - minDB) / (maxDB - minDB))
                    let y = height * (1 - normalizedValue)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 1)
        }
        .frame(height: height)
    }
}

struct WaterfallView: View {
    let data: [[Float]]
    let height: CGFloat
    let minDB: Float = -100
    let maxDB: Float = 0
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let lineHeight = height / CGFloat(data.count)
                
                for (lineIndex, line) in data.enumerated() {
                    let y = CGFloat(lineIndex) * lineHeight
                    
                    for (index, value) in line.enumerated() {
                        let x = CGFloat(index) * width / CGFloat(line.count)
                        let normalizedValue = CGFloat((value - minDB) / (maxDB - minDB))
                        let color = Color(
                            hue: 0.7 - Double(normalizedValue) * 0.7,
                            saturation: 1,
                            brightness: 1
                        )
                        
                        let rect = CGRect(
                            x: x,
                            y: y,
                            width: width / CGFloat(line.count),
                            height: lineHeight
                        )
                        
                        context.fill(
                            Path(rect),
                            with: .color(color)
                        )
                    }
                }
            }
        }
        .frame(height: height)
    }
}

struct LevelMeter: View {
    let value: Float
    let title: String
    let height: CGFloat
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
            
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    // Level
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.green, .yellow, .red]),
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(height: geometry.size.height * CGFloat(value))
                }
            }
            .frame(height: height)
            .cornerRadius(5)
        }
    }
} 