//
//  HealthDataStorageSettingsView.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/10.
//
//  健康数据存储设置界面
//  允许用户选择不同的存储策略以优化存储空间使用

import SwiftUI

struct HealthDataStorageSettingsView: View {
    @EnvironmentObject var bleViewModel: BLEViewModel
    @ObservedObject var healthDataService: HealthDataService  // 改为接收传入的实例
    @State private var selectedStrategy: HealthDataStorage.StorageStrategy
    @State private var selectedDisplayType: HealthDataStorage.HealthDataRetrievalType
    @State private var showingStrategyInfo = false
    
    init(healthDataService: HealthDataService) {
        self.healthDataService = healthDataService
        // 初始化时获取当前策略
        _selectedStrategy = State(initialValue: .smart)
        _selectedDisplayType = State(initialValue: healthDataService.dataDisplayType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("数据显示设置")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择日历显示的数据类型")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(DataDisplayOption.allCases, id: \.type) { option in
                            DataDisplaySelectionRow(
                                option: option,
                                isSelected: selectedDisplayType == option.type,
                                onTap: {
                                    selectedDisplayType = option.type
                                    healthDataService.setDataDisplayType(option.type)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("存储策略设置")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选择健康数据的存储策略")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(StorageStrategyOption.allCases, id: \.strategy) { option in
                            StrategySelectionRow(
                                option: option,
                                isSelected: selectedStrategy == option.strategy,
                                onTap: {
                                    selectedStrategy = option.strategy
                                    bleViewModel.setHealthDataStorageStrategy(option.strategy)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("当前状态")) {
                    HStack {
                        Text("存储策略")
                        Spacer()
                        Text(strategyDisplayName(selectedStrategy))
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("数据显示")
                        Spacer()
                        Text(displayTypeDisplayName(selectedDisplayType))
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        showingStrategyInfo = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("查看策略详情")
                        }
                    }
                }
                
                Section(header: Text("存储管理")) {
                    Button(action: {
                        bleViewModel.resetStorageCache()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("重置存储缓存")
                        }
                    }
                    
                    Button(action: {
                        bleViewModel.cleanupOldHealthData(keepDays: 30)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清理30天前的数据")
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("存储设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                selectedStrategy = bleViewModel.getCurrentStorageStrategy()
                selectedDisplayType = healthDataService.getDataDisplayType()
            }
            .sheet(isPresented: $showingStrategyInfo) {
                StrategyInfoView()
            }
        }
    }
    
    private func strategyDisplayName(_ strategy: HealthDataStorage.StorageStrategy) -> String {
        switch strategy {
        case .immediate: return "立即保存"
        case .significantChange: return "显著变化"
        case .timeInterval: return "定时保存"
        case .smart: return "智能策略"
        }
    }
    
    private func displayTypeDisplayName(_ type: HealthDataStorage.HealthDataRetrievalType) -> String {
        switch type {
        case .latest: return "最新数据"
        case .average: return "平均数据"
        case .statistics: return "统计数据"
        }
    }
}

// MARK: - 策略选项模型
struct StorageStrategyOption: CaseIterable {
    let strategy: HealthDataStorage.StorageStrategy
    let title: String
    let description: String
    let icon: String
    
    static let allCases: [StorageStrategyOption] = [
        StorageStrategyOption(
            strategy: .smart,
            title: "智能策略（推荐）",
            description: "心率变化≥5bpm或血氧变化≥2%时保存，最短间隔1分钟，最长间隔5分钟",
            icon: "brain.head.profile"
        ),
        StorageStrategyOption(
            strategy: .significantChange,
            title: "显著变化",
            description: "仅在数值有明显变化时保存",
            icon: "chart.line.uptrend.xyaxis"
        ),
        StorageStrategyOption(
            strategy: .timeInterval,
            title: "定时保存",
            description: "每隔1分钟保存一次数据",
            icon: "clock"
        ),
        StorageStrategyOption(
            strategy: .immediate,
            title: "立即保存",
            description: "接收到数据后立即保存（占用空间较大）",
            icon: "bolt.fill"
        )
    ]
}

// MARK: - 策略选择行组件
struct StrategySelectionRow: View {
    let option: StorageStrategyOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 策略详情页面
struct StrategyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InfoSection(
                        title: "智能策略",
                        icon: "brain.head.profile",
                        color: .blue,
                        content: """
                        推荐使用的策略，平衡了存储效率和数据完整性：
                        • 心率变化 ≥ 5bpm 时保存
                        • 血氧变化 ≥ 2% 时保存
                        • 最短保存间隔：1分钟
                        • 强制保存间隔：5分钟
                        • 适合日常健康监测
                        """
                    )
                    
                    InfoSection(
                        title: "显著变化",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        content: """
                        仅在数值有明显变化时保存：
                        • 心率变化 ≥ 5bpm
                        • 血氧变化 ≥ 2%
                        • 节省存储空间
                        • 可能错过一些数据变化
                        """
                    )
                    
                    InfoSection(
                        title: "定时保存",
                        icon: "clock",
                        color: .orange,
                        content: """
                        固定时间间隔保存：
                        • 每隔1分钟保存一次
                        • 数据连续性好
                        • 存储空间适中
                        • 适合需要连续监测的场景
                        """
                    )
                    
                    InfoSection(
                        title: "立即保存",
                        icon: "bolt.fill",
                        color: .red,
                        content: """
                        接收到数据立即保存：
                        • 数据完整性最高
                        • 存储空间占用最大
                        • 可能影响性能
                        • 仅在特殊需求时使用
                        """
                    )
                }
                .padding()
            }
            .navigationTitle("策略说明")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") { dismiss() })
        }
    }
}

struct InfoSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 数据显示选项模型
struct DataDisplayOption: CaseIterable {
    let type: HealthDataStorage.HealthDataRetrievalType
    let title: String
    let description: String
    let icon: String
    
    static let allCases: [DataDisplayOption] = [
        DataDisplayOption(
            type: .latest,
            title: "最新数据（默认）",
            description: "显示当日最后一次记录的心率和血氧数据",
            icon: "clock.arrow.circlepath"
        ),
        DataDisplayOption(
            type: .average,
            title: "平均数据",
            description: "显示当日所有记录的平均心率和血氧数据",
            icon: "chart.bar.fill"
        )
    ]
}

// MARK: - 数据显示选择行组件
struct DataDisplaySelectionRow: View {
    let option: DataDisplayOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: option.icon)
                    .foregroundColor(isSelected ? .green : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HealthDataStorageSettingsView(healthDataService: HealthDataService())
        .environmentObject(BLEViewModel())
}