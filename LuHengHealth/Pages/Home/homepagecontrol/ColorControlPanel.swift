//
//  ColorControlPanel.swift
//  LuHengHeath
//
//  Created by macios on 2025/7/18.
//
import SwiftUI

struct ColorControlPanel: View {
    @StateObject private var colorManager = AppConfigManager()
    @State var rgbColour = RGB(r: 0, g: 1, b: 1)
    @State var rgbPreview = RGB(r: 0, g: 1, b: 1)
    @Binding var brightness : Double
    @Binding var selectedColor: Color
//    @Binding var selectedColorPreview: Color
    var body: some View {
        VStack {
            HStack(spacing: 50) {
                
                ArcColorPicker(
                  previewRGB: $rgbPreview,     // 拖动中实时变化
                  selectedRGB: $rgbColour,   // 松手时确定写入
                  ringLineWidth: 26,
                  showsMiniDial: true
                )
                    .frame(width: 190 , height: 140)
                    .onChange(of: rgbPreview) { newRGB in
                        selectedColor = Color(red: newRGB.r, green: newRGB.g, blue: newRGB.b)
                    }
                    .onChange(of: rgbColour) { newRGB in
                        /// 只在确认颜色时记录历史记录
                        colorManager.addColor(Color(red: newRGB.r, green: newRGB.g, blue: newRGB.b))
                    }
                    .offset(x:20)




                
                ColorMemoryButtons(selectedColor: $selectedColor, recentColors: $colorManager.recentColors)
                    .scaleEffect(0.8)
            }
            CustomBrightnessSlider(brightness: $brightness)
                .scaleEffect(1)
                .frame(height: 30)
                .offset(x:-10)
        }
    
    }
    
}

// MARK:  - 三个按钮
struct ColorMemoryButtons: View {
    @Binding var selectedColor: Color
    @Binding var recentColors: [Color]  // 绑定外部颜色数组
    
    private let defaultColors: [Color] = [.red, .blue, .green]
    
    var body: some View {
        VStack(spacing: 30) {
            ForEach(0..<3, id: \.self) { index in
                let color = index < recentColors.count ? recentColors[index] : defaultColors[index]
                
                Button(action: {
                    selectedColor = color
                }) {
                    Circle()
                        .fill(color)
                        .frame(width: 40, height: 40)
                        .shadow(radius: 3)
                }
            }
        }
    }
}

#Preview{
    ColorControlPanel(brightness: .constant(1.0), selectedColor: .constant(.red))
}
