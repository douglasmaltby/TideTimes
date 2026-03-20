//
//  tempicon.swift
//  TideTimes
//
//  Created by Douglas Maltby on 3/20/26.
//
import SwiftUI

struct TideAppIconView: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            
            ZStack {
                // Ocean Gradient Background
                LinearGradient(
                    colors: [Color.cyan, Color.blue.opacity(0.8), Color.indigo],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Moon
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.25, height: h * 0.25)
                    .offset(x: -w * 0.18, y: -h * 0.22)
                    .shadow(color: .white.opacity(0.4), radius: w * 0.03)

                // Background Wave
                WaveShape()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: h * 0.5)
                    .offset(x: w * 0.1, y: h * 0.25)
                
                // Foreground Wave
                WaveShape()
                    .fill(Color.white)
                    .frame(height: h * 0.5)
                    .offset(x: -w * 0.05, y: h * 0.31)
            }
        }
        // Force the icon to remain a perfect square
        .aspectRatio(1, contentMode: .fit)
    }
}

// A custom bezier path to draw a smooth wave
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: -rect.width * 0.5, y: rect.midY))
        
        // Draw a smooth bezier curve for the wave
        path.addCurve(
            to: CGPoint(x: rect.maxX * 1.5, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.25, y: rect.height * 0.1),
            control2: CGPoint(x: rect.width * 0.75, y: rect.height * 0.9)
        )
        
        path.addLine(to: CGPoint(x: rect.maxX * 1.5, y: rect.maxY))
        path.addLine(to: CGPoint(x: -rect.width * 0.5, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    TideAppIconView()
        .padding()
}
