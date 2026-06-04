//
//  HistoryDataPage.swift
//  LuHengHealth
//
//  历史数据显示页面
//  显示设备返回的心率、血氧、步数历史数据

import SwiftUI

struct HistoryDataPage: View {
    @ObservedObject var viewModel: BLEViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部标签选择器
                Picker("数据类型", selection: $selectedTab) {
                    Text("心率").tag(0)
                    Text("血氧").tag(1)
                    Text("步数").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 内容区域
                TabView(selection: $selectedTab) {
                    heartRateHistoryView.tag(0)
                    bloodOxygenHistoryView.tag(1)
                    stepCountHistoryView.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("历史数据")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 心率历史视图
    
    private var heartRateHistoryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 当前数据卡片
                dataCard(
                    title: "当前心率",
                    value: viewModel.heartRate != nil ? "\(viewModel.heartRate!) bpm" : "未获取",
                    icon: "waveform.path.ecg",
                    color: .red
                )
                
                // 刷新按钮
                Button(action: {
                    viewModel.requestHeartRateHistory()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("刷新心率历史数据")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
                
                // 历史数据列表（新协议：3天数据，每天24小时）
                if !viewModel.heartRateHistory.isEmpty {
                    ForEach(viewModel.heartRateHistory.indices, id: \.self) { dayIndex in
                        let dayData = viewModel.heartRateHistory[dayIndex]
                        dayHistoryCard(
                            date: dayData.date,
                            hourlyValues: dayData.hourlyValues,
                            unit: "bpm",
                            color: .red
                        )
                    }
                } else {
                    emptyStateView(message: "暂无心率历史数据\n点击上方刷新按钮获取")
                }
                
                // 说明卡片
                infoCard(
                    title: "数据说明",
                    content: "设备返回3天历史数据，每天记录24小时的心率值。"
                )
                
                // 调试台
                debugConsole(
                    title: "心率历史原始数据",
                    rawData: viewModel.heartRateHistoryRawData,
                    color: .red
                )
            }
            .padding()
        }
    }
    
    // MARK: - 血氧历史视图
    
    private var bloodOxygenHistoryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 当前数据卡片
                dataCard(
                    title: "当前血氧",
                    value: viewModel.bloodOxygen != nil ? "\(viewModel.bloodOxygen!)%" : "未获取",
                    icon: "drop.fill",
                    color: .blue
                )
                
                // 刷新按钮
                Button(action: {
                    viewModel.requestBloodOxygenHistory()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("刷新血氧历史数据")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // 历史数据列表（新协议：3天数据，每天24小时）
                if !viewModel.bloodOxygenHistory.isEmpty {
                    ForEach(viewModel.bloodOxygenHistory.indices, id: \.self) { dayIndex in
                        let dayData = viewModel.bloodOxygenHistory[dayIndex]
                        dayHistoryCard(
                            date: dayData.date,
                            hourlyValues: dayData.hourlyValues,
                            unit: "%",
                            color: .blue
                        )
                    }
                } else {
                    emptyStateView(message: "暂无血氧历史数据\n点击上方刷新按钮获取")
                }
                
                // 说明卡片
                infoCard(
                    title: "数据说明",
                    content: "设备返回3天历史数据，每天记录24小时的血氧值。"
                )
                
                // 调试台
                debugConsole(
                    title: "血氧历史原始数据",
                    rawData: viewModel.bloodOxygenHistoryRawData,
                    color: .blue
                )
            }
            .padding()
        }
    }
    
    // MARK: - 步数历史视图
    
    private var stepCountHistoryView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 当前数据卡片
                dataCard(
                    title: "当前步数",
                    value: viewModel.stepCount != nil ? "\(viewModel.stepCount!)步" : "未获取",
                    icon: "figure.walk",
                    color: .orange
                )
                
                // 刷新按钮
                Button(action: {
                    viewModel.requestStepCountHistory()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("刷新步数历史数据")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                
                // 历史数据列表
                if !viewModel.stepCountHistory.isEmpty {
                    ForEach(viewModel.stepCountHistory.indices, id: \.self) { index in
                        let history = viewModel.stepCountHistory[index]
                        historyCard(
                            title: "历史记录 \(index + 1)",
                            time: "\(2000 + history.year)年\(history.month)月\(history.day)日 \(history.hour):\(String(format: "%02d", history.minute))",
                            value: "\(history.value)步",
                            icon: "clock.fill",
                            color: .orange
                        )
                    }
                } else {
                    emptyStateView(message: "暂无步数历史数据\n点击上方刷新按钮获取")
                }
                
                // 说明卡片
                infoCard(
                    title: "数据说明",
                    content: "设备按小时记录步数数据，每条记录包含时间和对应的步数值。"
                )
                
                // 调试台
                debugConsole(
                    title: "步数历史原始数据",
                    rawData: viewModel.stepCountHistoryRawData,
                    color: .orange
                )
            }
            .padding()
        }
    }
    
    // MARK: - 通用组件
    
    private func dataCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func historyCard(title: String, time: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("最新记录")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(4)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("记录时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(time)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("数值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - 每日历史数据卡片（新协议：24小时数据）
    
    private func dayHistoryCard(date: String, hourlyValues: [Int], unit: String, color: Color) -> some View {
        let nonZeroCount = hourlyValues.filter { $0 > 0 }.count
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(color)
                Text(date)
                    .font(.headline)
                Spacer()
                Text("\(nonZeroCount)小时有数据")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(4)
            }
            
            Divider()
            
            // 24小时数据网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 4) {
                ForEach(0..<24, id: \.self) { hour in
                    let value = hourlyValues[hour]
                    VStack(spacing: 2) {
                        Text("\(hour)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(value > 0 ? "\(value)" : "-")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(value > 0 ? color : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(value > 0 ? color.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func infoCard(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
    
    // MARK: - 调试台组件
    
    private func debugConsole(title: String, rawData: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(rawData.count)条")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(4)
            }
            
            Divider()
            
            if rawData.isEmpty {
                Text("暂无原始数据")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(rawData.indices, id: \.self) { index in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                Text(rawData[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
}

// MARK: - 预览

#Preview {
    HistoryDataPage(viewModel: BLEViewModel())
}
