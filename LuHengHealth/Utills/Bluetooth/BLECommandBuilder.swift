//
//  BLECommandBuilder.swift
//  LuHengHealth
//
//  蓝牙命令构建工具
//  封装所有"手机→设备"的写入命令构建
//  基于最新通信协议 (CMD请求-响应 + ACK模式)

import Foundation

class BLECommandBuilder {

    // MARK: - 帧格式常量

    static let frameHeaderWrite: UInt8 = 0xAA  // 写入帧帧头1
    static let frameHeaderWrite2: UInt8 = 0x55  // 写入帧帧头2
    static let frameFooterWrite1: UInt8 = 0x55  // 写入帧帧尾1
    static let frameFooterWrite2: UInt8 = 0xAA  // 写入帧帧尾2

    // MARK: - 校验和计算

    /// 计算校验和: 帧头到数据区所有字节累加和取低8位
    /// - Parameter bytes: 需要计算校验和的字节数组(不包含校验和本身)
    /// - Returns: 校验和字节
    static func calculateChecksum(_ bytes: [UInt8]) -> UInt8 {
        let sum = bytes.reduce(0) { $0 + Int($1) }
        return UInt8(sum & 0xFF)
    }

    // MARK: - 通用写入帧构建

    /// 标准数据区长度（协议规定所有标准命令固定为5字节）
    static let standardDataLength: Int = 5

    /// 构建标准写入帧: AA 55 08 CMD DATA[5] CHECK 55 AA
    /// - Parameters:
    ///   - cmd: 命令码
    ///   - data: 数据区字节数组（不足5字节自动补0x00）
    /// - Returns: 完整的帧数据
    static func buildWriteFrame(cmd: UInt8, data: [UInt8] = []) -> Data {
        // 数据区固定5字节，不足补0x00
        var paddedData = data
        while paddedData.count < standardDataLength {
            paddedData.append(0x00)
        }
        // 长度字段 = 数据区长度 + 3（LEN + CMD + CHECK）
        let length = UInt8(standardDataLength + 3)
        let header: [UInt8] = [frameHeaderWrite, frameHeaderWrite2, length, cmd]
        let payload = header + paddedData
        let checksum = calculateChecksum(payload)
        let frame: [UInt8] = payload + [checksum, frameFooterWrite1, frameFooterWrite2]
        return Data(frame)
    }

    // MARK: - 数据读取命令 (手机→设备)

    /// 读取心率命令
    /// 完整帧: AA 55 08 11 00 00 00 00 00 CHECK 55 AA
    static func readHeartRate() -> Data {
        buildWriteFrame(cmd: 0x11)
    }

    /// 读取血氧命令
    /// 完整帧: AA 55 08 12 00 00 00 00 00 CHECK 55 AA
    static func readBloodOxygen() -> Data {
        buildWriteFrame(cmd: 0x12)
    }

    /// 读取步数命令
    /// 完整帧: AA 55 08 13 00 00 00 00 00 CHECK 55 AA
    static func readStepCount() -> Data {
        buildWriteFrame(cmd: 0x13)
    }

    /// 读取电量命令
    /// 完整帧: AA 55 08 14 00 00 00 00 00 CHECK 55 AA
    static func readBatteryLevel() -> Data {
        buildWriteFrame(cmd: 0x14)
    }

    /// 读取固件版本号命令
    /// 完整帧: AA 55 08 15 00 00 00 00 00 CHECK 55 AA
    static func readFirmwareVersion() -> Data {
        buildWriteFrame(cmd: 0x15)
    }

    /// 读取序列号命令
    /// 完整帧: AA 55 08 16 00 00 00 00 00 CHECK 55 AA
    static func readSerialNumber() -> Data {
        buildWriteFrame(cmd: 0x16)
    }

    // MARK: - 历史数据读取命令

    /// 读取心率历史命令
    /// 完整帧: AA 55 08 17 00 00 00 00 00 CHECK 55 AA
    static func readHeartRateHistory() -> Data {
        buildWriteFrame(cmd: 0x17)
    }

    /// 读取血氧历史命令
    /// 完整帧: AA 55 08 18 00 00 00 00 00 CHECK 55 AA
    static func readBloodOxygenHistory() -> Data {
        buildWriteFrame(cmd: 0x18)
    }

    /// 读取步数历史命令
    /// 完整帧: AA 55 08 19 00 00 00 00 00 CHECK 55 AA
    static func readStepCountHistory() -> Data {
        buildWriteFrame(cmd: 0x19)
    }

    // MARK: - 灯光控制命令

    /// 设置灯光槽颜色
    /// - Parameters:
    ///   - slot: 灯光槽编号 (00/01/02 指定槽, FF 表示当前灯光槽)
    ///   - r: 红色分量 (0x00~0xFF)
    ///   - g: 绿色分量 (0x00~0xFF)
    ///   - b: 蓝色分量 (0x00~0xFF)
    /// 完整帧: AA 55 08 21 SS RR GG BB 00 CHECK 55 AA
    static func setLightSlotColor(slot: UInt8, r: UInt8, g: UInt8, b: UInt8) -> Data {
        buildWriteFrame(cmd: 0x21, data: [slot, r, g, b])
    }

    /// 设置灯光槽亮度
    /// - Parameters:
    ///   - slot: 灯光槽编号 (00/01/02 指定槽, FF 表示当前灯光槽)
    ///   - brightness: 亮度值 (0~400)
    /// 完整帧: AA 55 08 22 SS BR_H BR_L 00 00 CHECK 55 AA
    static func setLightSlotBrightness(slot: UInt8, brightness: UInt16) -> Data {
        let brightnessHigh = UInt8(brightness >> 8)
        let brightnessLow = UInt8(brightness & 0xFF)
        return buildWriteFrame(cmd: 0x22, data: [slot, brightnessHigh, brightnessLow])
    }

    /// 设置呼吸灯开关
    /// - Parameters:
    ///   - enabled: true 打开呼吸灯, false 关闭呼吸灯
    /// 完整帧: AA 55 08 23 EN 00 00 00 00 CHECK 55 AA
    static func setBreathingLight(enabled: Bool) -> Data {
        let value: UInt8 = enabled ? 0x01 : 0x00
        return buildWriteFrame(cmd: 0x23, data: [value])
    }

    /// 切换当前灯光槽
    /// - Parameter slot: 灯光槽编号 (只能为 00/01/02)
    /// 完整帧: AA 55 08 24 SS 00 00 00 00 CHECK 55 AA
    static func switchLightSlot(slot: UInt8) -> Data {
        return buildWriteFrame(cmd: 0x24, data: [slot])
    }

    // MARK: - 灯光参数读取命令

    /// 读取灯光参数
    /// - Parameter slot: 灯光槽编号 (00/01/02 指定槽, FF 表示读取当前灯光槽)
    /// 完整帧: AA 55 08 30 SS 00 00 00 00 CHECK 55 AA
    static func readLightParams(slot: UInt8) -> Data {
        return buildWriteFrame(cmd: 0x30, data: [slot])
    }

    // MARK: - 产品信息命令

    /// 读取产品型号命令
    /// 完整帧: AA 55 08 1B 00 00 00 00 00 CHECK 55 AA
    static func readProductModel() -> Data {
        return buildWriteFrame(cmd: 0x1B)
    }

    // MARK: - 健康阈值设置命令

    /// 设置心率低阈值
    /// - Parameter threshold: 心率低阈值 (bpm)
    /// 完整帧: AA 55 08 25 HR_LOW 00 00 00 00 CHECK 55 AA
    static func setHeartRateLowThreshold(_ threshold: UInt8) -> Data {
        return buildWriteFrame(cmd: 0x25, data: [threshold])
    }

    /// 设置心率高阈值
    /// - Parameter threshold: 心率高阈值 (bpm)
    /// 完整帧: AA 55 08 26 HR_HIGH 00 00 00 00 CHECK 55 AA
    static func setHeartRateHighThreshold(_ threshold: UInt8) -> Data {
        return buildWriteFrame(cmd: 0x26, data: [threshold])
    }

    /// 设置血氧低阈值
    /// - Parameter threshold: 血氧低阈值 (%)
    /// 完整帧: AA 55 08 27 SPO2_LOW 00 00 00 00 CHECK 55 AA
    static func setBloodOxygenLowThreshold(_ threshold: UInt8) -> Data {
        return buildWriteFrame(cmd: 0x27, data: [threshold])
    }

    /// 读取健康异常阈值命令
    /// 完整帧: AA 55 08 28 00 00 00 00 00 CHECK 55 AA
    static func readHealthAnomalyThresholds() -> Data {
        return buildWriteFrame(cmd: 0x28)
    }

    // MARK: - 测试命令

    /// 写入假历史数据（测试用）
    /// 完整帧: AA 55 08 1A 00 00 00 00 00 CHECK 55 AA
    static func writeFakeHistoryData() -> Data {
        return buildWriteFrame(cmd: 0x1A)
    }

    // MARK: - OTA 升级命令

    /// 请求进入 OTA 模式
    /// 完整帧: AA 55 08 40 00 00 00 00 00 CHECK 55 AA
    static func enterOTAMode() -> Data {
        return buildWriteFrame(cmd: 0x40)
    }

    /// 构建 OTA 开始升级帧
    /// - Parameters:
    ///   - firmwareSize: 固件真实总长度
    ///   - checksum: 整个固件真实字节的16位累加和
    /// 完整帧: AA 55 09 90 SIZE3 SIZE2 SIZE1 SIZE0 SUM_H SUM_L CHECK 55 AA
    static func buildOTAStartFrame(firmwareSize: UInt32, checksum: UInt16) -> Data {
        var payload: [UInt8] = []
        payload.append(0x90)                                      // CMD
        payload.append(UInt8((firmwareSize >> 24) & 0xFF))        // SIZE3
        payload.append(UInt8((firmwareSize >> 16) & 0xFF))        // SIZE2
        payload.append(UInt8((firmwareSize >> 8) & 0xFF))         // SIZE1
        payload.append(UInt8(firmwareSize & 0xFF))                // SIZE0
        payload.append(UInt8((checksum >> 8) & 0xFF))             // SUM_H
        payload.append(UInt8(checksum & 0xFF))                    // SUM_L
        
        // LEN = CMD(1) + DATA(6) + CHECK(1) = 8，但协议文档说是0x09
        // 实际上 LEN = payload.count + 2 (加上LEN本身和CHECK)
        let length = UInt8(payload.count + 2)  // 7 + 2 = 9 = 0x09
        let header: [UInt8] = [frameHeaderWrite, frameHeaderWrite2, length]
        let headerAndPayload = header + payload
        let checksumByte = calculateChecksum(headerAndPayload)
        let frame: [UInt8] = headerAndPayload + [checksumByte, frameFooterWrite1, frameFooterWrite2]
        return Data(frame)
    }

    /// 构建 OTA 固件数据包
    /// - Parameters:
    ///   - sequence: 包序号 (从0开始递增)
    ///   - data: 固件数据 (固定64字节, 不足补0xFF)
    /// 完整帧: AA 55 47 91 SEQ_H SEQ_L DATA_LEN CHECK_H CHECK_L DATA[64] CHECK 55 AA
    static func buildOTADataPacket(sequence: UInt16, data: Data) -> Data {
        var payload: [UInt8] = []
        payload.append(0x91)                                      // CMD
        payload.append(UInt8((sequence >> 8) & 0xFF))             // SEQ_H
        payload.append(UInt8(sequence & 0xFF))                    // SEQ_L

        // 固定64字节数据区
        var dataBytes = [UInt8](data)
        while dataBytes.count < 64 {
            dataBytes.append(0xFF)  // 不足补0xFF
        }

        // 计算DATA[64]的16位累加和
        let dataSum = dataBytes.reduce(0) { $0 + Int($1) }
        let checksumHigh = UInt8((dataSum >> 8) & 0xFF)
        let checksumLow = UInt8(dataSum & 0xFF)

        payload.append(0x40)  // DATA_LEN 固定为 0x40 (64)
        payload.append(checksumHigh)
        payload.append(checksumLow)
        payload.append(contentsOf: dataBytes.prefix(64))

        // LEN = payload.count + 2 (加上LEN本身和CHECK)
        // 1(CMD) + 2(SEQ) + 1(DATA_LEN) + 2(CHECK_H/L) + 64(DATA) = 70
        // LEN = 70 + 2 = 72 = 0x48
        let length = UInt8(payload.count + 2)
        let header: [UInt8] = [frameHeaderWrite, frameHeaderWrite2, length]
        let headerAndPayload = header + payload
        let checksumByte = calculateChecksum(headerAndPayload)
        let frame: [UInt8] = headerAndPayload + [checksumByte, frameFooterWrite1, frameFooterWrite2]
        return Data(frame)
    }

    /// 构建 OTA 结束升级帧
    /// - Parameters:
    ///   - firmwareSize: 固件真实总长度
    ///   - checksum: 整个固件真实字节的16位累加和
    /// 完整帧: AA 55 09 92 SIZE3 SIZE2 SIZE1 SIZE0 SUM_H SUM_L CHECK 55 AA
    static func buildOTAEndFrame(firmwareSize: UInt32, checksum: UInt16) -> Data {
        var payload: [UInt8] = []
        payload.append(0x92)                                      // CMD
        payload.append(UInt8((firmwareSize >> 24) & 0xFF))        // SIZE3
        payload.append(UInt8((firmwareSize >> 16) & 0xFF))        // SIZE2
        payload.append(UInt8((firmwareSize >> 8) & 0xFF))         // SIZE1
        payload.append(UInt8(firmwareSize & 0xFF))                // SIZE0
        payload.append(UInt8((checksum >> 8) & 0xFF))             // SUM_H
        payload.append(UInt8(checksum & 0xFF))                    // SUM_L

        // LEN = payload.count + 2 (加上LEN本身和CHECK)
        let length = UInt8(payload.count + 2)  // 7 + 2 = 9 = 0x09
        let header: [UInt8] = [frameHeaderWrite, frameHeaderWrite2, length]
        let headerAndPayload = header + payload
        let checksumByte = calculateChecksum(headerAndPayload)
        let frame: [UInt8] = headerAndPayload + [checksumByte, frameFooterWrite1, frameFooterWrite2]
        return Data(frame)
    }

    // MARK: - 便捷方法

    /// 同时设置灯光颜色和亮度 (发送两条命令)
    /// - Parameters:
    ///   - slot: 灯光槽编号
    ///   - r: 红色分量
    ///   - g: 绿色分量
    ///   - b: 蓝色分量
    ///   - brightness: 亮度值
    /// - Returns: 包含两条命令的数组
    static func setLightColorAndBrightness(slot: UInt8, r: UInt8, g: UInt8, b: UInt8, brightness: UInt16) -> [Data] {
        return [
            setLightSlotColor(slot: slot, r: r, g: g, b: b),
            setLightSlotBrightness(slot: slot, brightness: brightness)
        ]
    }
}
