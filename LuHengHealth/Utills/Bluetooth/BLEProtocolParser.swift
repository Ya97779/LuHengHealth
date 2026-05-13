//
//  BLEProtocolParser.swift
//  bleframeworktest
//
//  Created by macios on 2025/8/25.
//
//  蓝牙协议解析器
//  负责解析蓝牙设备传输的数据协议
//  支持心率和血氧数据的解析

import Foundation

// MARK: - 解析结果结构体
/// 解析后的数据结构，包含心率、血氧值和电池电压
struct BLEHealthData {
    /// 心率值，单位：次/分钟
    let heartRate: Int?
    
    /// 血氧值，单位：百分比
    let bloodOxygen: Int?
    
    /// 电池电压，单位：毫伏(mV)
    let batteryVoltage: Int?
    	
    /// 原始十六进制字符串
    let hexString: String
    
    /// 原始十进制值
    let decimalValue: Int
    
    /// 是否是有效数据
    let isValid: Bool
}

// MARK: - 蓝牙协议解析器
/// 负责解析蓝牙设备传输的数据协议
class BLEProtocolParser {
    
    // 协议帧头帧尾常量
    private static let frameHeader1: UInt8 = 0xAA
    private static let frameHeader2: UInt8 = 0x55
    private static let frameFooter1: UInt8 = 0x55
    private static let frameFooter2: UInt8 = 0xAA
    
    // 数据包中各字段的位置索引
    private static let heartRateIndex = 2       // 心率位置
    private static let bloodOxygenIndex = 3     // 血氧位置
    private static let batteryHighIndex = 4     // 电池电压高8位位置
    private static let batteryLowIndex = 5      // 电池电压低8位位置
    
    /// 单例实例
    static let shared = BLEProtocolParser()
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    /// 解析FFE4特征的字节数据
    /// - Parameter data: 从FFE4特征读取的原始字节数据
    /// - Returns: 解析后的健康数据结构
    func parseFFE4Data(_ data: Data) -> BLEHealthData {
        // 转换为十六进制字符串（用于日志和调试）
        let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        // 转换为十进制值（用于兼容旧的显示方式）
        var decimalValue = 0
        for (index, byte) in data.enumerated() {
            decimalValue += Int(byte) << (8 * index)
        }
        
        // 检查数据长度是否足够（完整数据包应该是8字节）
        // 0xAA 0x55 心率 血氧 电池高8位 电池低8位 0x55 0xAA
        guard data.count >= 8 else {
            return BLEHealthData(
                heartRate: nil,
                bloodOxygen: nil,
                batteryVoltage: nil,
                hexString: hexString,
                decimalValue: decimalValue,
                isValid: false
            )
        }
        
        // 检查帧头帧尾
        guard data[0] == BLEProtocolParser.frameHeader1 && 
              data[1] == BLEProtocolParser.frameHeader2 && 
              data[6] == BLEProtocolParser.frameFooter1 && 
              data[7] == BLEProtocolParser.frameFooter2 else {
            return BLEHealthData(
                heartRate: nil,
                bloodOxygen: nil,
                batteryVoltage: nil,
                hexString: hexString,
                decimalValue: decimalValue,
                isValid: false
            )
        }
        
        // 提取心率和血氧值
        let heartRate = Int(data[BLEProtocolParser.heartRateIndex])
        let bloodOxygen = Int(data[BLEProtocolParser.bloodOxygenIndex])
        
        // 计算电池电压（高8位在前，低8位在后）
        let batteryHigh = Int(data[BLEProtocolParser.batteryHighIndex])
        let batteryLow = Int(data[BLEProtocolParser.batteryLowIndex])
        let batteryVoltage = ((batteryHigh << 8) + batteryLow - 2925 ) * 100 / 1171
        
        return BLEHealthData(
            heartRate: heartRate,
            bloodOxygen: bloodOxygen,
            batteryVoltage: batteryVoltage,
            hexString: hexString,
            decimalValue: decimalValue,
            isValid: true
        )
    }
    
    /// 将字节数组转换为十六进制字符串
    /// - Parameter data: 原始字节数据
    /// - Returns: 格式化的十六进制字符串
    func bytesToHexString(_ data: Data) -> String {
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
    
    /// 将字节数组转换为十进制数值
    /// - Parameter data: 原始字节数据
    /// - Returns: 转换后的十进制数值
    func bytesToDecimal(_ data: Data) -> Int {
        var value = 0
        for (index, byte) in data.enumerated() {
            value += Int(byte) << (8 * index)
        }
        return value
    }
}
