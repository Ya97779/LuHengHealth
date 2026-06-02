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
    @Binding var slot0R: UInt8
    @Binding var slot0G: UInt8
    @Binding var slot0B: UInt8
    @Binding var slot1R: UInt8
    @Binding var slot1G: UInt8
    @Binding var slot1B: UInt8
    @Binding var slot2R: UInt8
    @Binding var slot2G: UInt8
    @Binding var slot2B: UInt8
    var onSlotTapped: ((UInt8) -> Void)? = nil
    
    private var slot0Color: Color {
        Color(red: Double(slot0R) / 255.0, green: Double(slot0G) / 255.0, blue: Double(slot0B) / 255.0)
    }
    private var slot1Color: Color {
        Color(red: Double(slot1R) / 255.0, green: Double(slot1G) / 255.0, blue: Double(slot1B) / 255.0)
    }
    private var slot2Color: Color {
        Color(red: Double(slot2R) / 255.0, green: Double(slot2G) / 255.0, blue: Double(slot2B) / 255.0)
    }
    
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
                
                ColorMemoryButtons(
                    slot0Color: slot0Color,
                    slot1Color: slot1Color,
                    slot2Color: slot2Color,
                    onSlotTapped: onSlotTapped
                )
                .scaleEffect(0.8)
            }
            CustomBrightnessSlider(brightness: $brightness)
                .scaleEffect(1)
                .frame(height: 30)
                .offset(x:-10)
        }
    }
}

// MARK:  - 三个灯光槽按钮（仅用于切换灯光槽和显示颜色）
struct ColorMemoryButtons: View {
    var slot0Color: Color
    var slot1Color: Color
    var slot2Color: Color
    var onSlotTapped: ((UInt8) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 30) {
            slotButton(index: 0, color: slot0Color)
            slotButton(index: 1, color: slot1Color)
            slotButton(index: 2, color: slot2Color)
        }
    }
    
    private func slotButton(index: UInt8, color: Color) -> some View {
        Button(action: {
            onSlotTapped?(index)
        }) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .shadow(radius: 3)
                .overlay(
                    Text("\(index)")
                        .font(.caption2)
                        .foregroundColor(.white)
                )
        }
    }
}

#Preview{
    ColorControlPanel(
        brightness: .constant(1.0),
        selectedColor: .constant(.red),
        slot0R: .constant(255),
        slot0G: .constant(0),
        slot0B: .constant(0),
        slot1R: .constant(0),
        slot1G: .constant(0),
        slot1B: .constant(255),
        slot2R: .constant(0),
        slot2G: .constant(255),
        slot2B: .constant(0)
    )
}
