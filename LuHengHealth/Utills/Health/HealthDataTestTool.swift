//
//  HealthDataTestTool.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/10.
//
//  健康数据测试工具
//  用于向数据库中添加模拟的心率和血氧数据，方便测试功能

import SwiftUI
import Foundation

struct HealthDataTestTool: View {
    @State private var isGenerating = false
    @State private var generatedCount = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let healthDataStorage = HealthDataStorage.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题说明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("健康数据测试工具")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("用于生成模拟的心率和血氧数据，帮助测试HealthPage和HealthDataDetailPage的功能显示")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // 快速生成按钮
                    VStack(spacing: 16) {
                        Text("快速生成数据")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            TestDataButton(
                                title: "今天数据",
                                subtitle: "10条记录",
                                icon: "calendar.badge.plus",
                                color: .blue
                            ) {
                                generateTodayData()
                            }
                            
                            TestDataButton(
                                title: "最近7天",
                                subtitle: "每天5-15条",
                                icon: "calendar.badge.clock",
                                color: .green
                            ) {
                                generateRecentWeekData()
                            }
                            
                            TestDataButton(
                                title: "最近30天",
                                subtitle: "每天3-20条",
                                icon: "calendar",
                                color: .orange
                            ) {
                                generateRecentMonthData()
                            }
                            
                            TestDataButton(
                                title: "多样化数据",
                                subtitle: "包含异常值",
                                icon: "waveform.path.ecg",
                                color: .red
                            ) {
                                generateVariedData()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 自定义生成选项
                    VStack(spacing: 16) {
                        Text("自定义生成")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            CustomDataButton(
                                title: "高心率场景",
                                description: "模拟运动时的高心率数据 (100-160 bpm)",
                                icon: "bolt.fill",
                                color: .red
                            ) {
                                generateHighHeartRateData()
                            }
                            
                            CustomDataButton(
                                title: "低血氧场景",
                                description: "模拟低血氧情况 (88-94%)",
                                icon: "lungs.fill",
                                color: .yellow
                            ) {
                                generateLowBloodOxygenData()
                            }
                            
                            CustomDataButton(
                                title: "健康范围数据",
                                description: "正常健康范围内的数据",
                                icon: "heart.fill",
                                color: .green
                            ) {
                                generateHealthyData()
                            }
                            
                            CustomDataButton(
                                title: "清空测试数据",
                                description: "清除所有测试生成的数据",
                                icon: "trash",
                                color: .gray
                            ) {
                                clearAllTestData()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 状态显示
                    if isGenerating {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("正在生成数据...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    if generatedCount > 0 {
                        Text("已生成 \\(generatedCount) 条数据")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding()
                    }
                }
            }
            .navigationTitle("数据测试工具")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("操作完成", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 数据生成方法
    
    /// 生成今天的测试数据
    private func generateTodayData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let today = Date()
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: today)
            
            // 生成10条今天的数据，模拟不同时间点
            for i in 0..<10 {
                let timestamp = calendar.date(byAdding: .hour, value: i * 2, to: startOfDay) ?? today
                let heartRate = Int.random(in: 65...85) // 正常心率范围
                let bloodOxygen = Int.random(in: 96...99) // 正常血氧范围
                
                let success = self.healthDataStorage.saveHealthData(
                    heartRate: heartRate,
                    bloodOxygen: bloodOxygen,
                    timestamp: timestamp,
                    strategy: .immediate
                )
                
                if success {
                    DispatchQueue.main.async {
                        self.generatedCount += 1
                    }
                }
                
                // 短暂延迟避免过快插入
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成今天的\\(self.generatedCount)条测试数据"
                self.showAlert = true
            }
        }
    }
    
    /// 生成最近7天的测试数据
    private func generateRecentWeekData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            
            for dayOffset in 0..<7 {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                let startOfDay = calendar.startOfDay(for: targetDate)
                
                // 每天生成5-15条数据
                let recordsPerDay = Int.random(in: 5...15)
                
                for recordIndex in 0..<recordsPerDay {
                    let hourOffset = Int.random(in: 6...22) // 6点到22点之间
                    let minuteOffset = Int.random(in: 0...59)
                    
                    guard let timestamp = calendar.date(bySettingHour: hourOffset, minute: minuteOffset, second: 0, of: startOfDay) else { continue }
                    
                    // 模拟一天中的生理变化
                    let baseHeartRate = 70
                    let heartRateVariation = Int.random(in: -15...25)
                    let heartRate = max(50, min(120, baseHeartRate + heartRateVariation))
                    
                    let baseBloodOxygen = 97
                    let bloodOxygenVariation = Int.random(in: -2...2)
                    let bloodOxygen = max(94, min(100, baseBloodOxygen + bloodOxygenVariation))
                    
                    let success = self.healthDataStorage.saveHealthData(
                        heartRate: heartRate,
                        bloodOxygen: bloodOxygen,
                        timestamp: timestamp,
                        strategy: .immediate
                    )
                    
                    if success {
                        DispatchQueue.main.async {
                            self.generatedCount += 1
                        }
                    }
                    
                    Thread.sleep(forTimeInterval: 0.05)
                }
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成最近7天的\\(self.generatedCount)条测试数据"
                self.showAlert = true
            }
        }
    }
    
    /// 生成最近30天的测试数据
    private func generateRecentMonthData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            
            for dayOffset in 0..<30 {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
                let startOfDay = calendar.startOfDay(for: targetDate)
                
                // 每天生成3-20条数据，模拟不同的活动水平
                let recordsPerDay = Int.random(in: 3...20)
                
                for _ in 0..<recordsPerDay {
                    let hourOffset = Int.random(in: 6...23)
                    let minuteOffset = Int.random(in: 0...59)
                    
                    guard let timestamp = calendar.date(bySettingHour: hourOffset, minute: minuteOffset, second: 0, of: startOfDay) else { continue }
                    
                    // 模拟30天内的健康状态变化
                    let dayFactor = Double(dayOffset) / 30.0
                    
                    let baseHeartRate = 72 + Int(dayFactor * 8) // 随时间略有变化
                    let heartRateVariation = Int.random(in: -20...30)
                    let heartRate = max(45, min(150, baseHeartRate + heartRateVariation))
                    
                    let baseBloodOxygen = 97
                    let bloodOxygenVariation = Int.random(in: -3...3)
                    let bloodOxygen = max(92, min(100, baseBloodOxygen + bloodOxygenVariation))
                    
                    let success = self.healthDataStorage.saveHealthData(
                        heartRate: heartRate,
                        bloodOxygen: bloodOxygen,
                        timestamp: timestamp,
                        strategy: .immediate
                    )
                    
                    if success {
                        DispatchQueue.main.async {
                            self.generatedCount += 1
                        }
                    }
                    
                    Thread.sleep(forTimeInterval: 0.02)
                }
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成最近30天的\\(self.generatedCount)条测试数据"
                self.showAlert = true
            }
        }
    }
    
    /// 生成多样化数据（包含异常值）
    private func generateVariedData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            let today = Date()
            
            // 生成各种场景的数据
            let scenarios = [
                (heartRate: 45, bloodOxygen: 99, description: "休息状态"),
                (heartRate: 120, bloodOxygen: 96, description: "运动状态"),
                (heartRate: 88, bloodOxygen: 92, description: "轻微缺氧"),
                (heartRate: 160, bloodOxygen: 94, description: "高强度运动"),
                (heartRate: 52, bloodOxygen: 100, description: "深度休息"),
                (heartRate: 95, bloodOxygen: 89, description: "异常低血氧"),
                (heartRate: 105, bloodOxygen: 98, description: "轻度运动"),
                (heartRate: 78, bloodOxygen: 97, description: "正常状态"),
            ]
            
            for (index, scenario) in scenarios.enumerated() {
                let timestamp = calendar.date(byAdding: .hour, value: -index * 3, to: today) ?? today
                
                let success = self.healthDataStorage.saveHealthData(
                    heartRate: scenario.heartRate,
                    bloodOxygen: scenario.bloodOxygen,
                    timestamp: timestamp,
                    strategy: .immediate
                )
                
                if success {
                    DispatchQueue.main.async {
                        self.generatedCount += 1
                    }
                }
                
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成多样化的\\(self.generatedCount)条测试数据，包含各种健康状态场景"
                self.showAlert = true
            }
        }
    }
    
    /// 生成高心率数据
    private func generateHighHeartRateData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            let today = Date()
            
            for i in 0..<15 {
                let timestamp = calendar.date(byAdding: .minute, value: -i * 10, to: today) ?? today
                let heartRate = Int.random(in: 100...160) // 高心率范围
                let bloodOxygen = Int.random(in: 94...98) // 运动时血氧可能略低
                
                let success = self.healthDataStorage.saveHealthData(
                    heartRate: heartRate,
                    bloodOxygen: bloodOxygen,
                    timestamp: timestamp,
                    strategy: .immediate
                )
                
                if success {
                    DispatchQueue.main.async {
                        self.generatedCount += 1
                    }
                }
                
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成高心率场景的\\(self.generatedCount)条测试数据"
                self.showAlert = true
            }
        }
    }
    
    /// 生成低血氧数据
    private func generateLowBloodOxygenData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            let today = Date()
            
            for i in 0..<12 {
                let timestamp = calendar.date(byAdding: .minute, value: -i * 15, to: today) ?? today
                let heartRate = Int.random(in: 75...95) // 正常心率
                let bloodOxygen = Int.random(in: 88...94) // 低血氧范围
                
                let success = self.healthDataStorage.saveHealthData(
                    heartRate: heartRate,
                    bloodOxygen: bloodOxygen,
                    timestamp: timestamp,
                    strategy: .immediate
                )
                
                if success {
                    DispatchQueue.main.async {
                        self.generatedCount += 1
                    }
                }
                
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成低血氧场景的\\(self.generatedCount)条测试数据"
                self.showAlert = true
            }
        }
    }
    
    /// 生成健康范围数据
    private func generateHealthyData() {
        isGenerating = true
        generatedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            let today = Date()
            
            for i in 0..<20 {
                let timestamp = calendar.date(byAdding: .minute, value: -i * 5, to: today) ?? today
                let heartRate = Int.random(in: 60...100) // 健康心率范围
                let bloodOxygen = Int.random(in: 95...100) // 健康血氧范围
                
                let success = self.healthDataStorage.saveHealthData(
                    heartRate: heartRate,
                    bloodOxygen: bloodOxygen,
                    timestamp: timestamp,
                    strategy: .immediate
                )
                
                if success {
                    DispatchQueue.main.async {
                        self.generatedCount += 1
                    }
                }
                
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.alertMessage = "成功生成健康范围的\\(self.generatedCount)条测试数据"
                self.showAlert = true
            }
        }
    }
    
    /// 清空所有测试数据
    private func clearAllTestData() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 这里可以添加清理逻辑
            // 注意：实际项目中需要谨慎实现数据清理功能
            
            DispatchQueue.main.async {
                self.isGenerating = false
                self.generatedCount = 0
                self.alertMessage = "数据清理功能需要在实际项目中谨慎实现"
                self.showAlert = true
            }
        }
    }
}

// MARK: - 辅助组件

struct TestDataButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomDataButton: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HealthDataTestTool()
}