import SwiftUI

struct LevelMeter: View {
    let value: Float
    let title: String
    let height: CGFloat
    
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [.green, .yellow, .red]),
        startPoint: .bottom,
        endPoint: .top
    )
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
            
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Background
                    Rectangle()
                        .fill(Color(.windowBackgroundColor))
                        .cornerRadius(5)
                    
                    // Level indicator
                    Rectangle()
                        .fill(gradient)
                        .frame(height: geometry.size.height * CGFloat(value))
                        .cornerRadius(5)
                }
            }
            .frame(height: height)
        }
    }
}

/*#Preview {
    LevelMeter(value: 0.5, title: "Signal", height: 100)
} */