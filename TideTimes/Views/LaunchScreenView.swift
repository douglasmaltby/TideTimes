import SwiftUI

struct LaunchScreenView: View {
    @State private var waveOffset = -100.0
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Wave animation
                WaveShape(offset: waveOffset)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 200)
                    .overlay {
                        WaveShape(offset: waveOffset - 50)
                            .fill(Color.blue.opacity(0.5))
                    }
                
                // App title
                Text("Tide Times")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                waveOffset = 100
                opacity = 1
            }
        }
    }
}

// Custom wave shape
struct WaveShape: Shape {
    var offset: Double
    
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.50))
        
        // Create a sine wave path
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / 50 + offset / 50
            let y = sin(relativeX) * 20 + height * 0.50
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}

#Preview {
    LaunchScreenView()
} 