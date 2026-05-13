//
//  HealthDataService.swift
//  test
//
//  Created by macios on 2025/7/14.
//

import Foundation
import SwiftUI
import CoreData

// 健康数据模型
struct HealthData: Codable, Identifiable, Equatable {
    let id = UUID()
    let date: String
    let bloodOxygen: Double
    let bloodPressure: BloodPressure
    let heartRate: Int
    let bloodSugar: Double
    let stress: Double
    let sleep: SleepData
    let overallHealth: Double
    
    struct BloodPressure: Codable, Equatable {
        let systolic: Int
        let diastolic: Int
    }
    
    struct SleepData: Codable, Equatable {
        let hours: Int
        let minutes: Int
        let quality: String
    }
}

// 健康数据服务
class HealthDataService: ObservableObject {
    @Published var currentHealthData: HealthData?
    @Published var selectedDate: Date = Date()
    
    // 健康数据存储服务
    private let healthDataStorage = HealthDataStorage.shared
    
    // 数据显示类型设置（用户可配置）
    @Published var dataDisplayType: HealthDataStorage.HealthDataRetrievalType = .latest
    
    // 缓存最近6天的日期
    private var cachedRecentDates: [Date] = []
    
    // 监听健康数据保存通知
    private var healthDataSavedObserver: NSObjectProtocol?
    
    init() {
        // 只计算日期，不立即加载数据
        cachedRecentDates = calculateRecentDates()
        
        // 监听健康数据保存通知，当有新数据保存时自动刷新当前显示
        healthDataSavedObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HealthDataSaved"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // 如果当前选中的是今天，则刷新数据
            if let self = self, Calendar.current.isDateInToday(self.selectedDate) {
                self.loadHealthData(for: self.selectedDate)
            }
        }
    }
    
    deinit {
        if let observer = healthDataSavedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // 从数据库加载指定日期的健康数据
    func loadHealthData(for date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // 防止重复加载相同日期的数据
        if let existingData = currentHealthData, existingData.date == dateString {
            print("数据已缓存，跳过重复加载: \(dateString)")
            return
        }
        
        print("加载健康数据: \(dateString)")
        
        // 从数据库读取真实数据
        DispatchQueue.global(qos: .userInitiated).async {
            // 根据设置的显示类型获取数据
            let retrievedData = self.healthDataStorage.getHealthData(for: date, type: self.dataDisplayType)
            
            DispatchQueue.main.async {
                if let coreData = retrievedData {
                    let dataTypeDescription = self.dataDisplayType == .latest ? "最新" : "平均"
                    
                    // 将Core Data转换为HealthData模型
                    let healthData = HealthData(
                        date: dateString,
                        bloodOxygen: Double(coreData.bloodoxygen),
                        bloodPressure: HealthData.BloodPressure(
                            systolic: 120, // 默认值，因为Core Data模型中暂时没有血压数据
                            diastolic: 80
                        ),
                        heartRate: Int(coreData.heartrate),
                        bloodSugar: 5.5, // 默认值，因为Core Data模型中暂时没有血糖数据
                        stress: self.calculateStressFromHealthData(heartRate: Int(coreData.heartrate), bloodOxygen: Int(coreData.bloodoxygen)),
                        sleep: HealthData.SleepData(
                            hours: 8, // 默认值
                            minutes: 0,
                            quality: "良好"
                        ),
                        overallHealth: self.calculateOverallHealth(heartRate: Int(coreData.heartrate), bloodOxygen: Int(coreData.bloodoxygen))
                    )
                    
                    print("找到(\(dataTypeDescription)): 心率\(coreData.heartrate)bpm, 血氧\(coreData.bloodoxygen)%")
                    self.currentHealthData = healthData
                } else {
                    // 如果数据库中没有数据，则使用模拟数据作为后备
                    print("未找到数据，使用默认值")
                    self.currentHealthData = self.createMockHealthData(for: dateString)
                }
            }
        }
    }
    
    // 加载当前日期的数据
    func loadCurrentDateData() {
        loadHealthData(for: selectedDate)
    }
    
    // 获取最近6天的日期（当前日期和向前5天）
    func getRecentDates() -> [Date] {
        // 如果缓存为空，重新计算
        if cachedRecentDates.isEmpty {
            cachedRecentDates = calculateRecentDates()
        }
        return cachedRecentDates
    }
    
    // 计算最近6天的日期
    private func calculateRecentDates() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(date)
            }
        }
        
        return dates.reversed()
    }
    
    // 格式化日期显示
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        return dateFormatter.string(from: date)
    }
    
    // 获取星期几
    func getDayOfWeek(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_CN")
        dateFormatter.dateFormat = "EEEE"
        let dayString = dateFormatter.string(from: date)
        
        // 转换为中文简写
        switch dayString {
        case "星期一": return "周一"
        case "星期二": return "周二"
        case "星期三": return "周三"
        case "星期四": return "周四"
        case "星期五": return "周五"
        case "星期六": return "周六"
        case "星期日": return "周日"
        default: return dayString
        }
    }
    
    // 检查是否为今天
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // 检查是否为选中日期
    func isSelectedDate(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    // MARK: - 私有辅助方法
    
    /// 根据心率和血氧计算压力指数
    private func calculateStressFromHealthData(heartRate: Int, bloodOxygen: Int) -> Double {
        // 简单的压力计算逻辑：心率越高、血氧越低，压力越大
        let heartRateStress = max(0, Double(heartRate - 70)) / 50.0 * 30 // 心率超过70后开始计算压力
        let oxygenStress = max(0, Double(98 - bloodOxygen)) / 8.0 * 20 // 血氧低于98%开始计算压力
        
        return min(50.0, heartRateStress + oxygenStress) // 压力指数上限50%
    }
    
    /// 根据心率和血氧计算整体健康评分
    private func calculateOverallHealth(heartRate: Int, bloodOxygen: Int) -> Double {
        // 心率健康评分：60-100为最佳，其他范围递减
        let heartRateScore: Double
        if heartRate >= 60 && heartRate <= 100 {
            heartRateScore = 100
        } else if heartRate < 60 {
            heartRateScore = max(50, 100 - Double(60 - heartRate) * 2)
        } else {
            heartRateScore = max(50, 100 - Double(heartRate - 100) * 1.5)
        }
        
        // 血氧健康评分：95%以上为最佳
        let oxygenScore: Double
        if bloodOxygen >= 95 {
            oxygenScore = 100
        } else {
            oxygenScore = max(60, Double(bloodOxygen) / 95.0 * 100)
        }
        
        // 综合评分（心率占40%，血氧占60%）
        return (heartRateScore * 0.4 + oxygenScore * 0.6)
    }
    
    /// 创建模拟健康数据作为后备
    private func createMockHealthData(for dateString: String) -> HealthData {
        // 为没有数据的日期创建基础的模拟数据
        return HealthData(
            date: dateString,
            bloodOxygen: 0.0,
            bloodPressure: HealthData.BloodPressure(systolic: 0, diastolic: 0),
            heartRate: 0,
            bloodSugar: 0.0,
            stress: 0.0,
            sleep: HealthData.SleepData(hours: 0, minutes: 0, quality: "无数据"),
            overallHealth: 0.0
        )
    }
    
    // MARK: - 数据显示类型管理
    
    /// 设置数据显示类型
    /// - Parameter type: 显示类型（最新或平均）
    func setDataDisplayType(_ type: HealthDataStorage.HealthDataRetrievalType) {
        dataDisplayType = type
        // 切换类型后，重新加载当前数据
        loadHealthData(for: selectedDate)
        print("数据显示类型已更改为: \(type == .latest ? "最新数据" : "平均数据")")
    }
    
    /// 获取当前数据显示类型
    func getDataDisplayType() -> HealthDataStorage.HealthDataRetrievalType {
        return dataDisplayType
    }
}
