//
//  BLEProtocolParser.swift
//  LuHengHealth
//
//  蓝牙协议解析器 (最新协议版)
//  负责解析蓝牙设备传输的数据协议
//  支持 CMD 请求-响应模式 + ACK模式
//  帧格式: AA 56 LEN CMD DATA[LEN] CHECK 56 AA

import Foundation

// MARK: - 帧类型枚举
enum FrameType {
    case responseFrame     // 返回帧: AA 56 ...
    case ackFrame         // ACK帧: AA 57 ...
    case otaAck          // OTA ACK帧: A5 ...
    case unknown
}

// MARK: - 解析后的帧结构
struct ParsedFrame {
    let type: FrameType
    let cmd: UInt8
    let data: [UInt8]
    let isValid: Bool
    let originalCmd: UInt8?   // ACK帧中: 被应答的原CMD
    let status: UInt8?        // ACK帧中: 01成功/02失败
}

// MARK: - 告警数据
struct AlarmData {
    let alarmCode: UInt8
    let paramA: UInt8
    let paramB: UInt8
    let paramC: UInt8

    var description: String {
        switch alarmCode {
        case 0x02:
            return "低电量告警: \(paramA)%"
        case 0x11:
            return "心率过低告警: \(paramA) bpm (< \(paramB))"
        case 0x12:
            return "心率过高告警: \(paramA) bpm (> \(paramB))"
        case 0x21:
            return "血氧过低告警: \(paramA)% (< \(paramB)%)"
        case 0x22:
            return "血氧无效告警: \(paramA)% (> 100%)"
        default:
            return "未知告警: code=\(alarmCode)"
        }
    }
}

// MARK: - 历史记录时间帧
struct HistoryTimeFrame {
    let year: UInt8
    let month: UInt8
    let day: UInt8
    let hour: UInt8
    let minute: UInt8

    var dateString: String {
        return String(format: "%02d-%02d-%02d %02d:%02d", year, month, day, hour, minute)
    }
}

// MARK: - 灯光参数帧 (合并颜色和亮度)
struct LightParamsFrame {
    let slot: UInt8
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let currentSlot: UInt8
    let brightness: UInt16
    let breathing: Bool
}

// MARK: - 健康异常阈值
struct HealthAnomalyThresholds: Equatable {
    let heartRateLow: UInt8
    let heartRateHigh: UInt8
    let bloodOxygenLow: UInt8
}

// MARK: - 蓝牙协议解析器
class BLEProtocolParser {

    // MARK: - 协议常量

    static let responseFrameHeader1: UInt8 = 0xAA  // 返回帧帧头1
    static let responseFrameHeader2: UInt8 = 0x56  // 返回帧帧头2
    static let responseFrameFooter1: UInt8 = 0x56  // 返回帧帧尾1
    static let responseFrameFooter2: UInt8 = 0xAA  // 返回帧帧尾2

    static let ackFrameHeader1: UInt8 = 0xAA      // ACK帧帧头1
    static let ackFrameHeader2: UInt8 = 0x57      // ACK帧帧头2
    static let ackFrameFooter1: UInt8 = 0x57      // ACK帧帧尾1
    static let ackFrameFooter2: UInt8 = 0xAA      // ACK帧帧尾2

    static let otaFrameHeader: UInt8 = 0xA5       // OTA ACK帧帧头
    static let otaFrameFooter: UInt8 = 0x5A       // OTA ACK帧帧尾

    // MARK: - 单例

    static let shared = BLEProtocolParser()
    private init() {}

    // MARK: - 帧解析入口

    /// 解析 FFE4 特征的字节数据
    /// - Parameter data: 从 FFE4 特征读取的原始字节数据
    /// - Returns: 解析后的帧结构
    func parse(_ data: Data) -> ParsedFrame {
        let bytes = [UInt8](data)
        guard !bytes.isEmpty else {
            return ParsedFrame(type: .unknown, cmd: 0, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        // 识别帧类型
        let frameType = identifyFrameType(bytes)

        switch frameType {
        case .responseFrame:
            return parseResponseFrame(bytes)
        case .ackFrame:
            return parseAckFrame(bytes)
        case .otaAck:
            return parseOtaAckFrame(bytes)
        case .unknown:
            return ParsedFrame(type: .unknown, cmd: 0, data: [], isValid: false, originalCmd: nil, status: nil)
        }
    }

    // MARK: - 帧类型识别

    private func identifyFrameType(_ bytes: [UInt8]) -> FrameType {
        guard bytes.count >= 2 else { return .unknown }

        if bytes[0] == Self.responseFrameHeader1 && bytes[1] == Self.responseFrameHeader2 {
            return .responseFrame
        } else if bytes[0] == Self.ackFrameHeader1 && bytes[1] == Self.ackFrameHeader2 {
            // 区分普通ACK和OTA ACK：OTA ACK的CMD是0x40/0x90/0x91/0x92
            if bytes.count >= 4 {
                let cmd = bytes[3]
                if cmd == 0x40 || cmd == 0x90 || cmd == 0x91 || cmd == 0x92 {
                    return .otaAck
                }
            }
            return .ackFrame
        }
        return .unknown
    }

    // MARK: - 返回帧解析

    private func parseResponseFrame(_ bytes: [UInt8]) -> ParsedFrame {
        // 格式: AA 56 LEN CMD DATA[N] CHECK 56 AA
        // LEN字段值N = LEN(1) + CMD(1) + DATA(N-3) + CHECK(1)，包含LEN字节本身
        // 例如: AA 56 08 03 00 00 00 00 00 0B 56 AA → N=8, DATA=5字节
        guard bytes.count >= 6 else {
            return ParsedFrame(type: .responseFrame, cmd: 0, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let length = bytes[2]  // LEN字段值，包含LEN+CMD+DATA+CHECK
        let cmd = bytes[3]
        let dataLength = Int(length) - 3  // 实际数据长度 = LEN - LEN字节 - CMD - CHECK
        let expectedTotalLength = Int(length) + 4  // 帧头(2) + LEN值 + 帧尾(2)

        guard dataLength >= 0 && bytes.count >= expectedTotalLength else {
            return ParsedFrame(type: .responseFrame, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        // 索引计算: [0]=AA [1]=56 [2]=LEN [3]=CMD [4..4+dataLength-1]=DATA [4+dataLength]=CHECK [4+dataLength+1]=56 [4+dataLength+2]=AA
        let dataIndexStart = 4
        let dataIndexEnd = dataIndexStart + dataLength - 1
        let checksumIndex = dataIndexEnd + 1
        let footerIndex1 = checksumIndex + 1
        let footerIndex2 = checksumIndex + 2

        // 验证帧尾
        guard bytes[footerIndex1] == Self.responseFrameFooter1 &&
              bytes[footerIndex2] == Self.responseFrameFooter2 else {
            return ParsedFrame(type: .responseFrame, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        // 验证校验和 (从帧头到数据区结束)
        let calculatedChecksum = calculateChecksum(Array(bytes[0...dataIndexEnd]))
        guard bytes[checksumIndex] == calculatedChecksum else {
            print("[BLE] 校验和不匹配: 计算=\(String(format: "%02X", calculatedChecksum)), 实际=\(String(format: "%02X", bytes[checksumIndex]))")
            return ParsedFrame(type: .responseFrame, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let payload = Array(bytes[dataIndexStart...dataIndexEnd])
        return ParsedFrame(type: .responseFrame, cmd: cmd, data: payload, isValid: true, originalCmd: nil, status: nil)
    }

    // MARK: - ACK帧解析

    private func parseAckFrame(_ bytes: [UInt8]) -> ParsedFrame {
        // 格式: AA 57 08 7F 原CMD STATUS 00 00 00 CHECK 57 AA
        // 索引:  [0]=AA [1]=57 [2]=08 [3]=7F [4]=CMD [5]=STATUS [6]=00 [7]=00 [8]=00 [9]=CHECK [10]=57 [11]=AA
        guard bytes.count >= 12 else {
            return ParsedFrame(type: .ackFrame, cmd: 0x7F, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let length = bytes[2]
        let cmd = bytes[3]
        let originalCmd = bytes[4]
        let status = bytes[5]

        // 验证固定字节
        guard length == 0x08 && cmd == 0x7F && bytes[6] == 0x00 && bytes[7] == 0x00 && bytes[8] == 0x00 else {
            return ParsedFrame(type: .ackFrame, cmd: cmd, data: [], isValid: false, originalCmd: originalCmd, status: status)
        }

        // 验证帧尾 (索引 10 和 11)
        guard bytes[10] == Self.ackFrameFooter1 && bytes[11] == Self.ackFrameFooter2 else {
            return ParsedFrame(type: .ackFrame, cmd: cmd, data: [], isValid: false, originalCmd: originalCmd, status: status)
        }

        // 验证校验和 (索引 9)
        let calculatedChecksum = calculateChecksum(Array(bytes[0...8]))
        guard bytes[9] == calculatedChecksum else {
            print("[BLE] ACK校验和不匹配: 计算=\(String(format: "%02X", calculatedChecksum)), 实际=\(String(format: "%02X", bytes[9]))")
            return ParsedFrame(type: .ackFrame, cmd: cmd, data: [], isValid: false, originalCmd: originalCmd, status: status)
        }

        return ParsedFrame(type: .ackFrame, cmd: cmd, data: [originalCmd, status, 0x00, 0x00, 0x00], isValid: true, originalCmd: originalCmd, status: status)
    }

    // MARK: - OTA ACK帧解析

    private func parseOtaAckFrame(_ bytes: [UInt8]) -> ParsedFrame {
        // 格式: AA 57 08 CMD STATUS SEQ_H SEQ_L PROGRESS ERR CHECK 57 AA
        // 索引:  [0]=AA [1]=57 [2]=08 [3]=CMD [4]=STATUS [5]=SEQ_H [6]=SEQ_L [7]=PROGRESS [8]=ERR [9]=CHECK [10]=57 [11]=AA
        // CMD = 0x40/0x90/0x91/0x92 (OTA相关命令)
        guard bytes.count >= 12 else {
            return ParsedFrame(type: .otaAck, cmd: 0, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let length = bytes[2]
        let cmd = bytes[3]
        let status = bytes[4]
        let seqHigh = bytes[5]
        let seqLow = bytes[6]
        let progress = bytes[7]
        let errorCode = bytes[8]

        // 验证长度和帧尾 (索引 10 和 11)
        guard length == 0x08 && bytes[10] == Self.ackFrameFooter1 && bytes[11] == Self.ackFrameFooter2 else {
            return ParsedFrame(type: .otaAck, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: status)
        }

        // 验证校验和 (索引 9)
        let calculatedChecksum = calculateChecksum(Array(bytes[0...8]))
        guard bytes[9] == calculatedChecksum else {
            print("[BLE] OTA ACK校验和不匹配: 计算=\(String(format: "%02X", calculatedChecksum)), 实际=\(String(format: "%02X", bytes[9]))")
            return ParsedFrame(type: .otaAck, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: status)
        }

        let payload = [cmd, status, seqHigh, seqLow, progress, errorCode]
        return ParsedFrame(type: .otaAck, cmd: cmd, data: payload, isValid: true, originalCmd: nil, status: status)
    }

    // MARK: - 校验和计算

    private func calculateChecksum(_ bytes: [UInt8]) -> UInt8 {
        let sum = bytes.reduce(0) { $0 + Int($1) }
        return UInt8(sum & 0xFF)
    }

    // MARK: - CMD 分发解析

    /// 解析心率返回帧 (CMD 0x01)
    /// 数据格式: HR 00 00 00 00
    func parseHeartRateResponse(_ frame: ParsedFrame) -> Int? {
        guard frame.isValid && frame.cmd == 0x01 && frame.data.count >= 5 else { return nil }
        return Int(frame.data[0])
    }

    /// 解析血氧返回帧 (CMD 0x02)
    /// 数据格式: SPO2 00 00 00 00
    func parseBloodOxygenResponse(_ frame: ParsedFrame) -> Int? {
        guard frame.isValid && frame.cmd == 0x02 && frame.data.count >= 5 else { return nil }
        return Int(frame.data[0])
    }

    /// 解析步数返回帧 (CMD 0x03)
    /// 数据格式: STEP_H STEP_M STEP_L 00 00
    /// step = STEP_H * 65536 + STEP_M * 256 + STEP_L
    func parseStepCountResponse(_ frame: ParsedFrame) -> Int? {
        guard frame.isValid && frame.cmd == 0x03 && frame.data.count >= 5 else { return nil }
        return Int(frame.data[0]) << 16 | Int(frame.data[1]) << 8 | Int(frame.data[2])
    }

    /// 解析电量返回帧 (CMD 0x04)
    /// 数据格式: PERCENT 00 00 00 00 (0~100%)
    func parseBatteryLevelResponse(_ frame: ParsedFrame) -> Int? {
        guard frame.isValid && frame.cmd == 0x04 && frame.data.count >= 5 else { return nil }
        return Int(frame.data[0])
    }

    /// 解析固件版本返回帧 (CMD 0x05)
    /// 数据格式: VERSION 00 00 00 00
    func parseFirmwareVersionResponse(_ frame: ParsedFrame) -> Int? {
        guard frame.isValid && frame.cmd == 0x05 && frame.data.count >= 5 else { return nil }
        return Int(frame.data[0])
    }

    /// 解析序列号返回帧 (CMD 0x06)
    /// 单帧格式: UID0 UID1 UID2 UID3 UID4 UID5 UID6 UID7 (8字节)
    func parseSerialNumberResponse(_ frame: ParsedFrame) -> String? {
        guard frame.isValid && frame.cmd == 0x06 && frame.data.count >= 8 else { return nil }
        return frame.data.prefix(8).map { String(format: "%02X", $0) }.joined()
    }

    /// 解析告警返回帧 (CMD 0x80)
    /// 数据格式: ALARM_CODE A B C 00
    func parseAlarmResponse(_ frame: ParsedFrame) -> AlarmData? {
        guard frame.isValid && frame.cmd == 0x80 && frame.data.count >= 5 else { return nil }
        return AlarmData(
            alarmCode: frame.data[0],
            paramA: frame.data[1],
            paramB: frame.data[2],
            paramC: frame.data[3]
        )
    }

    /// 解析产品型号返回帧 (CMD 0x0B)
    /// 数据格式: MODEL 00 00 00 00
    func parseProductModelResponse(_ frame: ParsedFrame) -> UInt8? {
        guard frame.isValid && frame.cmd == 0x0B && frame.data.count >= 5 else { return nil }
        return frame.data[0]
    }

    /// 解析健康异常阈值返回帧 (CMD 0x0A)
    /// 数据格式: HR_LOW HR_HIGH SPO2_LOW 00 00
    func parseHealthAnomalyThresholdsResponse(_ frame: ParsedFrame) -> HealthAnomalyThresholds? {
        guard frame.isValid && frame.cmd == 0x0A && frame.data.count >= 5 else { return nil }
        return HealthAnomalyThresholds(
            heartRateLow: frame.data[0],
            heartRateHigh: frame.data[1],
            bloodOxygenLow: frame.data[2]
        )
    }

    /// 解析灯光参数返回帧 (CMD 0x30)
    /// 单帧格式: SS RR GG BB CUR BR_H BR_L BREATH (8字节)
    func parseLightParamsResponse(_ frame: ParsedFrame) -> LightParamsFrame? {
        guard frame.isValid && frame.cmd == 0x30 && frame.data.count >= 8 else { return nil }
        let brightness = UInt16(frame.data[5]) << 8 | UInt16(frame.data[6])
        let breathing = frame.data[7] == 0x01
        return LightParamsFrame(
            slot: frame.data[0],
            r: frame.data[1],
            g: frame.data[2],
            b: frame.data[3],
            currentSlot: frame.data[4],
            brightness: brightness,
            breathing: breathing
        )
    }

    /// 解析心率历史返回帧 (CMD 0x07)
    /// 新协议格式: 3天数据，每天24小时心率值
    /// 数据区81字节 = 3 × (3字节日期 + 24字节小时心率)
    /// 返回: [(日期, [(小时, 心率)])]
    func parseHeartRateHistoryResponse(_ frame: ParsedFrame) -> [(date: String, hourlyData: [(hour: Int, value: Int)])]? {
        guard frame.isValid && frame.cmd == 0x07 && frame.data.count >= 81 else { return nil }
        
        var result: [(date: String, hourlyData: [(hour: Int, value: Int)])] = []
        
        for dayIndex in 0..<3 {
            let baseIndex = dayIndex * 27
            let year = Int(frame.data[baseIndex]) + 2000
            let month = Int(frame.data[baseIndex + 1])
            let day = Int(frame.data[baseIndex + 2])
            let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
            
            var hourlyData: [(hour: Int, value: Int)] = []
            for hour in 0..<24 {
                let hr = Int(frame.data[baseIndex + 3 + hour])
                hourlyData.append((hour: hour, value: hr))
            }
            
            result.append((date: dateStr, hourlyData: hourlyData))
        }
        
        return result
    }

    /// 解析血氧历史返回帧 (CMD 0x08)
    /// 新协议格式: 3天数据，每天24小时血氧值
    /// 数据区81字节 = 3 × (3字节日期 + 24字节小时血氧)
    /// 返回: [(日期, [(小时, 血氧)])]
    func parseBloodOxygenHistoryResponse(_ frame: ParsedFrame) -> [(date: String, hourlyData: [(hour: Int, value: Int)])]? {
        guard frame.isValid && frame.cmd == 0x08 && frame.data.count >= 81 else { return nil }
        
        var result: [(date: String, hourlyData: [(hour: Int, value: Int)])] = []
        
        for dayIndex in 0..<3 {
            let baseIndex = dayIndex * 27
            let year = Int(frame.data[baseIndex]) + 2000
            let month = Int(frame.data[baseIndex + 1])
            let day = Int(frame.data[baseIndex + 2])
            let dateStr = String(format: "%04d-%02d-%02d", year, month, day)
            
            var hourlyData: [(hour: Int, value: Int)] = []
            for hour in 0..<24 {
                let spo2 = Int(frame.data[baseIndex + 3 + hour])
                hourlyData.append((hour: hour, value: spo2))
            }
            
            result.append((date: dateStr, hourlyData: hourlyData))
        }
        
        return result
    }

    /// 解析步数历史返回帧 (CMD 0x09)
    /// 单帧格式: YY MM DD HH MIN STEP_H STEP_L (7字节)
    /// 返回: (时间信息, 步数值)
    func parseStepCountHistoryResponse(_ frame: ParsedFrame) -> (time: HistoryTimeFrame, steps: Int)? {
        guard frame.isValid && frame.cmd == 0x09 && frame.data.count >= 7 else { return nil }
        let timeFrame = HistoryTimeFrame(
            year: frame.data[0],
            month: frame.data[1],
            day: frame.data[2],
            hour: frame.data[3],
            minute: frame.data[4]
        )
        let steps = Int(frame.data[5]) << 8 | Int(frame.data[6])
        return (time: timeFrame, steps: steps)
    }

    // MARK: - 辅助方法

    /// 将字节数组转换为十六进制字符串
    func bytesToHexString(_ data: Data) -> String {
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    /// 将字节数组转换为十进制数值
    func bytesToDecimal(_ data: Data) -> Int {
        var value = 0
        for (index, byte) in data.enumerated() {
            value += Int(byte) << (8 * index)
        }
        return value
    }
}
