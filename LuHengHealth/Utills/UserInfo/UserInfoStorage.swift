//
//  UserInfoStorage.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/10.
//
//  用户信息存储服务
//  负责管理用户基本信息的Core Data存储和读取

import Foundation
import CoreData
import Combine

/// 用户信息存储服务
/// 提供用户基本信息的增删改查功能
class UserInfoStorage: ObservableObject {
    
    // MARK: - 单例实例
    static let shared = UserInfoStorage()
    
    // MARK: - Core Data相关
    private let persistenceController: PersistenceController
    private var context: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    // MARK: - 初始化
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - 用户信息保存方法
    
    /// 保存或更新用户基本信息
    /// - Parameters:
    ///   - username: 用户昵称
    ///   - gender: 性别
    ///   - height: 身高（厘米）
    ///   - weight: 体重（千克，使用Double精度存储）
    /// - Returns: 是否保存成功
    @discardableResult
    func saveUserInfo(username: String?, gender: String?, height: Int?, weight: Double?) -> Bool {
        do {
            // 查找现有用户信息，如果没有则创建新的
            let userInfo = getCurrentUserInfo() ?? UserInfo(context: context)
            
            // 更新用户信息
            if let username = username, !username.isEmpty {
                userInfo.username = username
            }
            
            if let gender = gender, !gender.isEmpty {
                userInfo.gender = gender
            }
            
            if let height = height, height > 0 {
                userInfo.height = Int16(height)
            }
            
            if let weight = weight, weight > 0 {
                // 将Double转换为整数保存（保留一位小数的精度）
                userInfo.weight = Int16(weight * 10) // 例如：70.5kg -> 705
            }
            
            // 保存到数据库
            try context.save()
            
            print("用户信息保存成功 - 昵称:\(userInfo.username ?? ""), 性别:\(userInfo.gender ?? ""), 身高:\(userInfo.height)cm, 体重:\(Double(userInfo.weight)/10.0)kg")
            
            // 发送通知告知UI更新
            NotificationCenter.default.post(name: .userInfoUpdated, object: nil)
            
            return true
            
        } catch {
            print("用户信息保存失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 用户信息查询方法
    
    /// 获取当前用户信息
    /// - Returns: 用户信息对象，如果没有则返回nil
    func getCurrentUserInfo() -> UserInfo? {
        let request: NSFetchRequest<UserInfo> = UserInfo.fetchRequest()
        request.fetchLimit = 1 // 只获取一个用户信息
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("查询用户信息失败：\(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取用户昵称
    /// - Returns: 用户昵称，如果没有则返回默认值
    func getUsername() -> String {
        return getCurrentUserInfo()?.username ?? ""
    }
    
    /// 获取用户性别
    /// - Returns: 用户性别，如果没有则返回默认值
    func getGender() -> String {
        return getCurrentUserInfo()?.gender ?? ""
    }
    
    /// 获取用户身高
    /// - Returns: 用户身高（厘米），如果没有则返回0
    func getHeight() -> Int {
        return Int(getCurrentUserInfo()?.height ?? 0)
    }
    
    /// 获取用户体重
    /// - Returns: 用户体重（千克），如果没有则返回0
    func getWeight() -> Double {
        let weightInt = getCurrentUserInfo()?.weight ?? 0
        return Double(weightInt) / 10.0 // 将整数转换回Double
    }
    
    // MARK: - 体重历史记录方法
    
    /// 保存体重记录到健康数据中（用于体重变化跟踪）
    /// - Parameter weight: 体重值
    /// - Returns: 是否保存成功
    @discardableResult
    func saveWeightRecord(_ weight: Double) -> Bool {
        do {
            // 创建体重记录实体（如果有的话，或者扩展现有实体）
            // 这里我们暂时使用UserInfo来存储最新体重
            // 实际项目中可能需要单独的体重历史记录实体
            
            let userInfo = getCurrentUserInfo() ?? UserInfo(context: context)
            userInfo.weight = Int16(weight * 10)
            
            try context.save()
            
            print("体重记录保存成功：\(weight)kg")
            
            // 发送通知告知UI更新
            NotificationCenter.default.post(name: .weightUpdated, object: weight)
            
            return true
            
        } catch {
            print("体重记录保存失败：\(error.localizedDescription)")
            return false
        }
    }
    
    /// 获取体重变化信息
    /// - Returns: 体重变化信息（变化值和趋势）
    func getWeightChange() -> WeightChangeInfo {
        // 这里需要实现体重历史记录查询
        // 由于当前模型只有一个体重字段，我们先返回模拟数据
        // 实际应用中需要扩展数据模型来存储体重历史
        
        let currentWeight = getWeight()
        
        // 模拟上次体重（实际应从历史记录中获取）
        let previousWeight = currentWeight - 0.8 // 假设上次体重比当前重0.8kg
        
        let change = currentWeight - previousWeight
        let isIncrease = change > 0
        let isDecrease = change < 0
        
        return WeightChangeInfo(
            currentWeight: currentWeight,
            previousWeight: previousWeight,
            change: abs(change),
            isIncrease: isIncrease,
            isDecrease: isDecrease,
            isStable: !isIncrease && !isDecrease
        )
    }
    
    // MARK: - 数据删除方法
    
    /// 删除用户信息
    /// - Returns: 是否删除成功
    @discardableResult
    func deleteUserInfo() -> Bool {
        guard let userInfo = getCurrentUserInfo() else {
            print("没有找到用户信息")
            return true
        }
        
        do {
            context.delete(userInfo)
            try context.save()
            print("用户信息删除成功")
            
            // 发送通知告知UI更新
            NotificationCenter.default.post(name: .userInfoUpdated, object: nil)
            
            return true
        } catch {
            print("用户信息删除失败：\(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - 数据验证方法
    
    /// 验证身高是否有效
    /// - Parameter height: 身高值
    /// - Returns: 是否有效
    func isValidHeight(_ height: Int) -> Bool {
        return height > 0 && height <= 300 // 身高范围0-300cm
    }
    
    /// 验证体重是否有效
    /// - Parameter weight: 体重值
    /// - Returns: 是否有效
    func isValidWeight(_ weight: Double) -> Bool {
        return weight > 0 && weight <= 1000 // 体重范围0-1000kg
    }
    
    /// 验证用户名是否有效
    /// - Parameter username: 用户名
    /// - Returns: 是否有效
    func isValidUsername(_ username: String) -> Bool {
        return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - 体重变化信息结构体
/// 体重变化信息
struct WeightChangeInfo {
    let currentWeight: Double     // 当前体重
    let previousWeight: Double    // 上次体重
    let change: Double           // 变化量（绝对值）
    let isIncrease: Bool         // 是否增加
    let isDecrease: Bool         // 是否减少
    let isStable: Bool           // 是否稳定
    
    /// 获取变化趋势图标
    var trendIcon: String {
        if isIncrease {
            return "arrow.up"
        } else if isDecrease {
            return "arrow.down"
        } else {
            return "minus"
        }
    }
    
    /// 获取变化趋势颜色
    var trendColor: String {
        if isIncrease {
            return "red"      // 体重增加用红色
        } else if isDecrease {
            return "green"    // 体重减少用绿色
        } else {
            return "gray"     // 稳定用灰色
        }
    }
    
    /// 获取变化描述文本
    var changeDescription: String {
        if isStable {
            return "与上次相同"
        } else {
            let direction = isIncrease ? "增加" : "减少"
            return "\(String(format: "%.1f", change))kg对比上次"
        }
    }
}

// MARK: - 通知名称扩展
extension Notification.Name {
    static let userInfoUpdated = Notification.Name("userInfoUpdated")
    static let weightUpdated = Notification.Name("weightUpdated")
}