//
//  HealthDataStorage.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/10.
//
//  健康数据存储服务
//  负责管理心率和血氧数据的Core Data存储和读取

import Foundation
import CoreData
import Combine

/// 健康数据存储服务
/// 提供心率和血氧数据的增删改查功能
/// 支持智能存储策略，避免重复数据浪费存储空间
class HealthDataStorage: ObservableObject {
    
    // MARK: - 单例实例
    static let shared = HealthDataStorage()
    
    // MARK: - Core Data相关
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    // MARK: - 智能存储配置
    
    /// 数据变化阈值配置
    private struct StorageThresholds {
        static let heartRateThreshold: Int = 5      // 心率变化超过5bpm才保存
        static let bloodOxygenThreshold: Int = 2    // 血氧变化超过2%才保存
        static let minimumInterval: TimeInterval = 60  // 最少间隔60秒才能保存新数据
        static let forceUpdateInterval: TimeInterval = 300 // 强制更新间隔5分钟
    }
    
    /// 上次保存的数据缓存
    private var lastSavedData: (heartRate: Int, bloodOxygen: Int, timestamp: Date)?
    
    /// 存储策略枚举
    enum StorageStrategy {
        case immediate          // 立即保存（原有策略）
        case significantChange  // 显著变化时保存
        case timeInterval      // 定时保存
        case smart             // 智能策略（推荐）
    }
    
    /// 当前使用的存储策略
    private var currentStrategy: StorageStrategy = .smart
    
    // MARK: - 初始化
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - 数据保存方法
    
    /// 保存BLE设备读取的健康数据（使用智能存储策略）
    /// - Parameters:
    ///   - heartRate: 心率值（次/分钟）
    ///   - bloodOxygen: 血氧值（百分比）
    ///   - timestamp: 记录时间，默认为当前时间
    ///   - strategy: 存储策略，默认使用智能策略
    /// - Returns: 是否保存成功
    @discardableResult
    func saveHealthData(heartRate: Int?, bloodOxygen: Int?, timestamp: Date = Date(), strategy: StorageStrategy? = nil) -> Bool {
        // 检查输入参数
        guard let heartRate = heartRate, let bloodOxygen = bloodOxygen else {
            print("健康数据保存失败：心率或血氧值为空")
            return false
        }
        
        // 检查数据有效性
        guard isValidHeartRate(heartRate) && isValidBloodOxygen(bloodOxygen) else {
            print("健康数据保存失败：数据值无效 - 心率:\(heartRate), 血氧:\(bloodOxygen)")
            return false
        }
        
        // 应用存储策略
        let useStrategy = strategy ?? currentStrategy
        if !shouldSaveData(heartRate: heartRate, bloodOxygen: bloodOxygen, timestamp: timestamp, strategy: useStrategy) {
            print("根据存储策略(\(useStrategy))跳过保存 - 心率:\(heartRate), 血氧:\(bloodOxygen)")
            return false
        }
        
        do {
            // 创建新的健康数据实体
            let healthData = BodyhealthData(context: context)
            healthData.heartrate = Int16(heartRate)
            healthData.bloodoxygen = Int16(bloodOxygen)
            healthData.timestamp = timestamp
            
            // 保存到数据库
            try context.save()
            
            // 更新缓存
            lastSavedData = (heartRate: heartRate, bloodOxygen: bloodOxygen, timestamp: timestamp)
            
            print("健康数据保存成功 - 心率:\(heartRate)bpm, 血氧:\(bloodOxygen)%, 时间:\(formatDate(timestamp))")
            return true
            
        } catch {
            print("健康数据保存失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 数据查询方法
    
    /// 获取指定日期的健康数据
    /// - Parameter date: 查询日期
    /// - Returns: 该日期的健康数据列表
    func getHealthData(for date: Date) -> [BodyhealthData] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<BodyhealthData> = BodyhealthData.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", 
                                      startOfDay as NSDate, 
                                      endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            print("查询到 \(formatDate(date)) 的健康数据：\(results.count) 条")
            return results
        } catch {
            print("查询健康数据失败：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取指定日期的最新健康数据
    /// - Parameter date: 查询日期
    /// - Returns: 该日期最新的一条健康数据
    func getLatestHealthData(for date: Date) -> BodyhealthData? {
        let dataList = getHealthData(for: date)
        return dataList.first // 由于已按时间倒序排列，第一个就是最新的
    }
    
    /// 获取指定日期的平均健康数据
    /// - Parameter date: 查询日期
    /// - Returns: 该日期的平均健康数据（虚拟BodyhealthData对象）
    func getAverageHealthData(for date: Date) -> BodyhealthData? {
        let dataList = getHealthData(for: date)
        
        guard !dataList.isEmpty else {
            return nil
        }
        
        // 计算平均值
        let totalHeartRate = dataList.reduce(0) { $0 + Int($1.heartrate) }
        let totalBloodOxygen = dataList.reduce(0) { $0 + Int($1.bloodoxygen) }
        
        let averageHeartRate = totalHeartRate / dataList.count
        let averageBloodOxygen = totalBloodOxygen / dataList.count
        
        // 创建一个表示平均值的虚拟对象
        let averageData = BodyhealthData(context: context)
        averageData.heartrate = Int16(averageHeartRate)
        averageData.bloodoxygen = Int16(averageBloodOxygen)
        averageData.timestamp = Calendar.current.startOfDay(for: date)
        
        print("计算 \(formatDate(date)) 的平均数据: 心率\(averageHeartRate)bpm, 血氧\(averageBloodOxygen)%, 基于\(dataList.count)条记录")
        
        return averageData
    }
    
    /// 获取指定日期的健康数据类型枚举
    enum HealthDataRetrievalType {
        case latest      // 最新数据
        case average     // 平均数据
        case statistics  // 统计数据
    }
    
    /// 根据指定类型获取健康数据
    /// - Parameters:
    ///   - date: 查询日期
    ///   - type: 数据类型（最新、平均、统计）
    /// - Returns: 对应类型的健康数据
    func getHealthData(for date: Date, type: HealthDataRetrievalType) -> BodyhealthData? {
        switch type {
        case .latest:
            return getLatestHealthData(for: date)
        case .average:
            return getAverageHealthData(for: date)
        case .statistics:
            // 这里可以返回更复杂的统计数据，暂时返回平均值
            return getAverageHealthData(for: date)
        }
    }
    
    /// 获取指定日期范围内的健康数据
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 指定范围内的健康数据列表
    func getHealthData(from startDate: Date, to endDate: Date) -> [BodyhealthData] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        let request: NSFetchRequest<BodyhealthData> = BodyhealthData.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", 
                                      startOfDay as NSDate, 
                                      endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let results = try context.fetch(request)
            print("查询到 \(formatDate(startDate)) 至 \(formatDate(endDate)) 的健康数据：\(results.count) 条")
            return results
        } catch {
            print("查询健康数据失败：\(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取最近N天的健康数据概要
    /// - Parameter days: 天数
    /// - Returns: 每天的最新健康数据字典，键为日期字符串
    func getRecentHealthDataSummary(days: Int = 7) -> [String: BodyhealthData] {
        let calendar = Calendar.current
        let today = Date()
        var summary: [String: BodyhealthData] = [:]
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateString = formatDateString(date)
                if let latestData = getLatestHealthData(for: date) {
                    summary[dateString] = latestData
                }
            }
        }
        
        return summary
    }
    
    // MARK: - 数据删除方法
    
    /// 删除指定日期的所有健康数据
    /// - Parameter date: 要删除数据的日期
    /// - Returns: 是否删除成功
    @discardableResult
    func deleteHealthData(for date: Date) -> Bool {
        let dataList = getHealthData(for: date)
        
        do {
            for data in dataList {
                context.delete(data)
            }
            try context.save()
            print("成功删除 \(formatDate(date)) 的 \(dataList.count) 条健康数据")
            return true
        } catch {
            print("删除健康数据失败：\(error.localizedDescription)")
            return false
        }
    }
    
    /// 删除超过指定天数的旧数据
    /// - Parameter days: 保留天数，超过此天数的数据将被删除
    /// - Returns: 删除的数据条数
    @discardableResult
    func deleteOldHealthData(olderThan days: Int) -> Int {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            return 0
        }
        
        let request: NSFetchRequest<BodyhealthData> = BodyhealthData.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
        
        do {
            let oldData = try context.fetch(request)
            let count = oldData.count
            
            for data in oldData {
                context.delete(data)
            }
            
            try context.save()
            print("成功删除 \(count) 条超过 \(days) 天的旧健康数据")
            return count
        } catch {
            print("删除旧健康数据失败：\(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - 数据统计方法
    
    /// 获取指定日期的健康数据统计
    /// - Parameter date: 查询日期
    /// - Returns: 健康数据统计信息
    func getHealthDataStatistics(for date: Date) -> HealthDataStatistics? {
        let dataList = getHealthData(for: date)
        
        guard !dataList.isEmpty else {
            return nil
        }
        
        let heartRates = dataList.map { Int($0.heartrate) }
        let bloodOxygens = dataList.map { Int($0.bloodoxygen) }
        
        return HealthDataStatistics(
            date: date,
            recordCount: dataList.count,
            averageHeartRate: heartRates.reduce(0, +) / heartRates.count,
            minHeartRate: heartRates.min() ?? 0,
            maxHeartRate: heartRates.max() ?? 0,
            averageBloodOxygen: bloodOxygens.reduce(0, +) / bloodOxygens.count,
            minBloodOxygen: bloodOxygens.min() ?? 0,
            maxBloodOxygen: bloodOxygens.max() ?? 0
        )
    }
    
    // MARK: - 存储策略方法
    
    /// 判断是否应该保存数据
    private func shouldSaveData(heartRate: Int, bloodOxygen: Int, timestamp: Date, strategy: StorageStrategy) -> Bool {
        switch strategy {
        case .immediate:
            return true
            
        case .significantChange:
            return isSignificantChange(heartRate: heartRate, bloodOxygen: bloodOxygen)
            
        case .timeInterval:
            return isTimeIntervalMet(timestamp: timestamp)
            
        case .smart:
            return isSmartSaveRequired(heartRate: heartRate, bloodOxygen: bloodOxygen, timestamp: timestamp)
        }
    }
    
    /// 检查是否有显著变化
    private func isSignificantChange(heartRate: Int, bloodOxygen: Int) -> Bool {
        guard let lastData = lastSavedData else {
            return true // 第一次保存
        }
        
        let heartRateChange = abs(heartRate - lastData.heartRate)
        let bloodOxygenChange = abs(bloodOxygen - lastData.bloodOxygen)
        
        return heartRateChange >= StorageThresholds.heartRateThreshold ||
               bloodOxygenChange >= StorageThresholds.bloodOxygenThreshold
    }
    
    /// 检查时间间隔是否满足
    private func isTimeIntervalMet(timestamp: Date) -> Bool {
        guard let lastData = lastSavedData else {
            return true // 第一次保存
        }
        
        return timestamp.timeIntervalSince(lastData.timestamp) >= StorageThresholds.minimumInterval
    }
    
    /// 智能保存策略
    private func isSmartSaveRequired(heartRate: Int, bloodOxygen: Int, timestamp: Date) -> Bool {
        guard let lastData = lastSavedData else {
            return true // 第一次保存
        }
        
        let timeSinceLastSave = timestamp.timeIntervalSince(lastData.timestamp)
        
        // 强制更新：超过5分钟必须保存
        if timeSinceLastSave >= StorageThresholds.forceUpdateInterval {
            print("智能策略：强制更新（超过\(Int(StorageThresholds.forceUpdateInterval/60))分钟）")
            return true
        }
        
        // 最小间隔检查：60秒内不保存
        if timeSinceLastSave < StorageThresholds.minimumInterval {
            return false
        }
        
        // 显著变化检查
        if isSignificantChange(heartRate: heartRate, bloodOxygen: bloodOxygen) {
            print("智能策略：检测到显著变化")
            return true
        }
        
        return false
    }
    
    // MARK: - 配置方法
    
    /// 设置存储策略
    func setStorageStrategy(_ strategy: StorageStrategy) {
        currentStrategy = strategy
        print("存储策略已更改为: \(strategy)")
    }
    
    /// 获取当前存储策略
    func getCurrentStrategy() -> StorageStrategy {
        return currentStrategy
    }
    
    /// 重置缓存数据（用于新设备连接时）
    func resetCache() {
        lastSavedData = nil
        print("存储缓存已重置")
    }
    
    // MARK: - 私有辅助方法
    
    /// 验证心率值是否有效
    private func isValidHeartRate(_ heartRate: Int) -> Bool {
        return heartRate > 0 && heartRate <= 300 // 正常心率范围扩展
    }
    
    /// 验证血氧值是否有效
    private func isValidBloodOxygen(_ bloodOxygen: Int) -> Bool {
        return bloodOxygen > 0 && bloodOxygen <= 100 // 血氧百分比范围
    }
    
    /// 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// 格式化日期字符串（仅日期）
    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 健康数据统计结构体
/// 健康数据统计信息
struct HealthDataStatistics {
    let date: Date
    let recordCount: Int
    let averageHeartRate: Int
    let minHeartRate: Int
    let maxHeartRate: Int
    let averageBloodOxygen: Int
    let minBloodOxygen: Int
    let maxBloodOxygen: Int
    
    var description: String {
        return """
        日期: \(date)
        记录数: \(recordCount)
        心率: 平均\(averageHeartRate) (范围: \(minHeartRate)-\(maxHeartRate))
        血氧: 平均\(averageBloodOxygen)% (范围: \(minBloodOxygen)%-\(maxBloodOxygen)%)
        """
    }
}
