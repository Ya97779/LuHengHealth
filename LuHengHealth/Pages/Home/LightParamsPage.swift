//
//  LightParamsPage.swift
//  LuHengHealth
//
//  灯光参数详情页面
//  显示三个灯光槽的详细参数

import SwiftUI

struct LightParamsPage: View {
    @ObservedObject var viewModel: BLEViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 灯光槽 0
                    lightSlotCard(slot: 0, r: viewModel.slot0R, g: viewModel.slot0G, b: viewModel.slot0B, brightness: viewModel.slot0Brightness, breathing: viewModel.slot0Breathing)
                    
                    // 灯光槽 1
                    lightSlotCard(slot: 1, r: viewModel.slot1R, g: viewModel.slot1G, b: viewModel.slot1B, brightness: viewModel.slot1Brightness, breathing: viewModel.slot1Breathing)
                    
                    // 灯光槽 2
                    lightSlotCard(slot: 2, r: viewModel.slot2R, g: viewModel.slot2G, b: viewModel.slot2B, brightness: viewModel.slot2Brightness, breathing: viewModel.slot2Breathing)
                    
                    // 刷新按钮
                    Button(action: {
                        viewModel.requestAllLightSlotParams()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("刷新所有灯光参数")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
                .padding(.bottom, 60)
            }
            .navigationTitle("灯光参数")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 进入页面时刷新数据
                viewModel.requestAllLightSlotParams()
            }
        }
    }
    
    // MARK: - 灯光槽卡片
    
    private func lightSlotCard(slot: UInt8, r: UInt8, g: UInt8, b: UInt8, brightness: UInt16, breathing: Bool) -> some View {
        let isSelected = viewModel.lightCurrentSlot == slot
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(isSelected ? .yellow : .orange)
                Text("灯光槽 \(slot)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
                
                if isSelected {
                    Text("当前选中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Divider()
            
            // 颜色预览和RGB值
            HStack(spacing: 20) {
                // 颜色预览
                VStack {
                    Circle()
                        .fill(Color(
                            red: Double(r) / 255.0,
                            green: Double(g) / 255.0,
                            blue: Double(b) / 255.0
                        ))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(radius: 3)
                    
                    Text("颜色预览")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // RGB值
                VStack(alignment: .leading, spacing: 8) {
                    rgbRow(label: "R (红)", value: r, color: .red)
                    rgbRow(label: "G (绿)", value: g, color: .green)
                    rgbRow(label: "B (蓝)", value: b, color: .blue)
                }
                
                Spacer()
            }
            
            // 亮度和呼吸灯状态
            HStack(spacing: 20) {
                // 亮度
                VStack(alignment: .leading, spacing: 4) {
                    Text("亮度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("\(brightness)")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // 呼吸灯状态
                VStack(alignment: .leading, spacing: 4) {
                    Text("呼吸灯")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: breathing ? "waveform.path.ecg" : "waveform.path.ecg.rectangle")
                            .foregroundColor(breathing ? .green : .gray)
                            .font(.caption)
                        Text(breathing ? "开启" : "关闭")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(breathing ? .green : .gray)
                    }
                }
                
                Spacer()
                
                // HEX值
                VStack(alignment: .leading, spacing: 4) {
                    Text("HEX")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "#%02X%02X%02X", r, g, b))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }
            
            // 切换按钮
            HStack {
                Spacer()
                
                Button(action: {
                    viewModel.switchLightSlot(slot: slot)
                }) {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                        Text(isSelected ? "已选中" : "切换到此槽")
                    }
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isSelected)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - RGB行
    
    private func rgbRow(label: String, value: UInt8, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 255.0, height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(value)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - 预览

#Preview {
    LightParamsPage(viewModel: BLEViewModel())
}
