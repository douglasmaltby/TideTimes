//
//  tempicon.swift
//  TideTimes
//
//  Created by Douglas Maltby on 3/20/26.
//
import SwiftUI

struct TideAppIconView: View {
    var body: some View {
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
                .frame(width: 250, height: 250)
                .offset(x: -180, y: -220)
                .shadow(color: .white.opacity(0.4), radius: 30)

            // Background Wave
            WaveShape()
                .fill(Color.white.opacity(0.3))
                .frame(height: 500)
                .offset(x: 100, y: 250)
            
            // Foreground Wave
            WaveShape()
                .fill(Color.white)
                .frame(height: 500)
                .offset(x: -50, y: 320)
        }
        .frame(width: 1024, height: 1024) // Standard Single-Scale Icon Size
        // The clipShape is just to preview how it looks rounded.
        // App Store icons should be submitted as square!
        //.clipShape(RoundedRectangle(cornerRadius: 225, style: .continuous))
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
}
