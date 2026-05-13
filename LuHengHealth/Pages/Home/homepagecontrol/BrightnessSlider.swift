//
//  BrightnessSlider.swift
//  LuHengHeath
//
//  Created by macios on 2025/7/17.
//


import SwiftUI

struct CustomBrightnessSlider: View {
    @Binding var brightness: Double // 范围 0 ~ 1
    
    // 滑块宽度
    let sliderWidth: CGFloat = 250
    let sliderHeight: CGFloat = 30
    let thumbSize: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                //                Image(systemName: "sun.min.fill")
                //                    .foregroundColor(.gray)
                //
                ZStack(alignment: .leading) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.black.opacity(0.4))
                        .zIndex(999)
                        .frame(width: 25)
                    // 背景条
                    RoundedRectangle(cornerRadius: sliderHeight / 2.5)
                        .fill(Color(hex: "#F4E8DA"))
                        .frame(width: sliderWidth, height: sliderHeight)
                    
                    // 进度条
                    RoundedRectangle(cornerRadius: sliderHeight / 2.5)
                        .fill(Color(hex: "# F9C57B"))
                        .frame(width: CGFloat(brightness) * sliderWidth, height: sliderHeight)
                    // 箭头（叠在进度条上方）
                    Triangle()
                        .fill(Color(hex: "# F9C57B"))
                        .frame(width: 12, height: 12)
                        .offset(
                            x: CGFloat(brightness) * sliderWidth - 12 / 2,
                            y: -sliderHeight/2
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = max(0, min(value.location.x, sliderWidth))
                                    brightness = location / sliderWidth
                                }
                        )
                        .shadow(radius: 2)
                        .zIndex(4)
                }
                .frame(height: thumbSize)
                .padding(.horizontal)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let location = max(0, min(value.location.x, sliderWidth))
                            brightness = location / sliderWidth
                        }
                )
                
            }
            
            Text(String(format: "Brightness: %.2f", brightness))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CustomBrightnessSliderPreview()
}

struct CustomBrightnessSliderPreview: View {
    @State private var brightness = 0.7
    
    var body: some View {
        CustomBrightnessSlider(brightness: $brightness)
    }
}

// 自定义三角形（箭头）
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.minX, y: 0))
        path.closeSubpath()
        return path
    }
}
