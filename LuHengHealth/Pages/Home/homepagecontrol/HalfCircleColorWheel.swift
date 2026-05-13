//
//  HalfCircleColorWheel.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//


import SwiftUI

struct HalfCircleColorWheel: View {
    @Binding var previewColor: Color       // 拖动时预览颜色
    @Binding var selectedColor: Color      // 松手后确定颜色

    let radius: CGFloat = 120
    let lineWidth: CGFloat = 30
    let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink]
    
    @State private var angle: Double = 0   // 当前角度（-180 到 0）

    var body: some View {
        ZStack {
            // 半圆颜色环
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(
                    AngularGradient(gradient: Gradient(colors: colors),
                                    center: .center,
                                    startAngle: .degrees(180),
                                    endAngle: .degrees(0)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: radius * 2, height: radius * 2)
                .rotationEffect(.degrees(180)) // 上半圆

            // 拖动箭头
            ArrowPointer()
                .fill(previewColor)
                .frame(width: 20, height: 20)
                .offset(x: cos(CGFloat(angle) * .pi / 180) * (radius + 15),
                        y: sin(CGFloat(angle) * .pi / 180) * (radius + 15))
                .rotationEffect(.degrees(angle))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let center = CGPoint(x: radius, y: radius)
                            let dx = value.location.x - center.x
                            let dy = value.location.y - center.y
                            let dragAngle = atan2(dy, dx) * 180 / .pi

                            // 限制角度在 -180° 到 0°
                            angle = min(0, max(-180, dragAngle))

                            // 映射角度到 0~1 区间
                            let t = (angle + 180) / 180
                            previewColor = interpolateColor(t: t)
                        }
                        .onEnded { _ in
                            selectedColor = previewColor
                        }
                )
        }
        .frame(width: radius * 2, height: radius)
    }

    // 插值计算当前颜色
    private func interpolateColor(t: Double) -> Color {
        let segments = colors.count - 1
        let scaledT = t * Double(segments)
        let index = Int(scaledT)
        let remainder = scaledT - Double(index)

        guard index < colors.count - 1 else { return colors.last ?? .white }

        let start = UIColor(colors[index])
        let end = UIColor(colors[index + 1])

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        start.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        end.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = Double(r1 + (r2 - r1) * remainder)
        let g = Double(g1 + (g2 - g1) * remainder)
        let b = Double(b1 + (b2 - b1) * remainder)
        return Color(red: r, green: g, blue: b)
    }
}

// 箭头指示器
struct ArrowPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let height = rect.height

        path.move(to: CGPoint(x: midX, y: 0)) // 顶部
        path.addLine(to: CGPoint(x: midX - 5, y: height))
        path.addLine(to: CGPoint(x: midX + 5, y: height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    HalfCircleColorWheel(previewColor: .constant(.red), selectedColor: .constant(.red))
}
