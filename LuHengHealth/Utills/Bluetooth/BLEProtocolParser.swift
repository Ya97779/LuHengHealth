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

// MARK: - 灯光颜色参数帧
struct LightColorFrame {
    let slot: UInt8
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let currentSlot: UInt8
}

// MARK: - 灯光亮度参数帧
struct LightBrightnessFrame {
    let slot: UInt8
    let brightness: UInt16
    let breathing: Bool
    let direction: UInt8
}

// MARK: - 序列号帧数据
struct SerialNumberFrame {
    let isFirstFrame: Bool   // true=第一帧(前4字节), false=第二帧(后4字节)
    let bytes: [UInt8]
}

// MARK: - 历史记录数据
struct HistoryDataFrame {
    let minValue: UInt8
    let maxValue: UInt8
}

// MARK: - 多帧数据缓冲区
struct MultiFrameBuffer {
    private var buffer: [UInt8: [ParsedFrame]] = [:]
    private let timeout: TimeInterval = 2.0

    mutating func addFrame(_ frame: ParsedFrame) {
        buffer[frame.cmd, default: []].append(frame)
    }

    mutating func getFrames(for cmd: UInt8) -> [ParsedFrame]? {
        return buffer.removeValue(forKey: cmd)
    }

    mutating func clear() {
        buffer.removeAll()
    }
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

    // MARK: - 多帧缓冲区

    private var multiFrameBuffer = MultiFrameBuffer()

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
            return .ackFrame
        } else if bytes[0] == Self.otaFrameHeader {
            return .otaAck
        }
        return .unknown
    }

    // MARK: - 返回帧解析

    private func parseResponseFrame(_ bytes: [UInt8]) -> ParsedFrame {
        // 格式: AA 56 LEN CMD DATA[LEN] CHECK 56 AA
        guard bytes.count >= 6 else {
            return ParsedFrame(type: .responseFrame, cmd: 0, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let length = bytes[2]
        let cmd = bytes[3]
        let expectedTotalLength = 6 + Int(length) + 1 + 1  // 帧头2 + 长度1 + CMD1 + 数据LEN + 校验1 + 帧尾2

        guard bytes.count >= expectedTotalLength else {
            return ParsedFrame(type: .responseFrame, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let dataEndIndex = 4 + Int(length) - 1
        let checksumIndex = dataEndIndex + 1
        let footerIndex1 = checksumIndex + 1
        let footerIndex2 = checksumIndex + 2

        // 验证帧尾
        guard bytes[footerIndex1] == Self.responseFrameFooter1 &&
              bytes[footerIndex2] == Self.responseFrameFooter2 else {
            return ParsedFrame(type: .responseFrame, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        // 验证校验和
        let calculatedChecksum = calculateChecksum(Array(bytes[0...dataEndIndex]))
        guard bytes[checksumIndex] == calculatedChecksum else {
            print("校验和不匹配: 计算=\(String(format: "%02X", calculatedChecksum)), 实际=\(String(format: "%02X", bytes[checksumIndex]))")
            return ParsedFrame(type: .responseFrame, cmd: cmd, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let payload = Array(bytes[4...dataEndIndex])
        return ParsedFrame(type: .responseFrame, cmd: cmd, data: payload, isValid: true, originalCmd: nil, status: nil)
    }

    // MARK: - ACK帧解析

    private func parseAckFrame(_ bytes: [UInt8]) -> ParsedFrame {
        // 格式: AA 57 05 7F 原CMD STATUS 00 00 00 CHECK 57 AA
        guard bytes.count >= 10 else {
            return ParsedFrame(type: .ackFrame, cmd: 0x7F, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let length = bytes[2]
        let cmd = bytes[3]
        let originalCmd = bytes[4]
        let status = bytes[5]

        // 验证固定字节
        guard length == 0x05 && cmd == 0x7F && bytes[6] == 0x00 && bytes[7] == 0x00 && bytes[8] == 0x00 else {
            return ParsedFrame(type: .ackFrame, cmd: cmd, data: [], isValid: false, originalCmd: originalCmd, status: status)
        }

        // 验证帧尾
        guard bytes[9] == Self.ackFrameFooter1 && bytes[10] == Self.ackFrameFooter2 else {
            return ParsedFrame(type: .ackFrame, cmd: cmd, data: [], isValid: false, originalCmd: originalCmd, status: status)
        }

        // 验证校验和
        let calculatedChecksum = calculateChecksum(Array(bytes[0...8]))
        guard bytes[9] == calculatedChecksum else {
            return ParsedFrame(type: .ackFrame, cmd: cmd, data: [], isValid: false, originalCmd: originalCmd, status: status)
        }

        return ParsedFrame(type: .ackFrame, cmd: cmd, data: [originalCmd, status, 0x00, 0x00, 0x00], isValid: true, originalCmd: originalCmd, status: status)
    }

    // MARK: - OTA ACK帧解析

    private func parseOtaAckFrame(_ bytes: [UInt8]) -> ParsedFrame {
        // 格式: A5 CMD STATUS SEQ_H SEQ_L PROGRESS ERR 5A
        guard bytes.count >= 7 else {
            return ParsedFrame(type: .otaAck, cmd: 0, data: [], isValid: false, originalCmd: nil, status: nil)
        }

        let cmd = bytes[1]
        let status = bytes[2]
        let seqHigh = bytes[3]
        let seqLow = bytes[4]
        let progress = bytes[5]
        let errorCode = bytes[6]

        // 验证帧尾
        guard bytes.count >= 8 && bytes[7] == Self.otaFrameFooter else {
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
    /// 数据格式: STEP_H STEP_L 00 00 00
    func parseStepCountResponse(_ frame: ParsedFrame) -> Int? {
        guard frame.isValid && frame.cmd == 0x03 && frame.data.count >= 5 else { return nil }
        return Int(frame.data[0]) << 8 | Int(frame.data[1])
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
    /// 第一帧: 00 UID0 UID1 UID2 UID3
    /// 第二帧: 01 UID4 UID5 UID6 UID7
    func parseSerialNumberResponse(_ frame: ParsedFrame) -> SerialNumberFrame? {
        guard frame.isValid && frame.cmd == 0x06 && frame.data.count >= 5 else { return nil }
        let isFirstFrame = frame.data[0] == 0x00
        let bytes = Array(frame.data[1...4])
        return SerialNumberFrame(isFirstFrame: isFirstFrame, bytes: bytes)
    }

    /// 组合解析完整序列号 (需要两帧)
    func combineSerialNumber(frames: [ParsedFrame]) -> String? {
        guard frames.count == 2 else { return nil }

        let sortedFrames = frames.sorted { $0.data[0] < $1.data[0] }
        guard let firstFrame = sortedFrames.first,
              let secondFrame = sortedFrames.last,
              firstFrame.data[0] == 0x00,
              secondFrame.data[0] == 0x01 else {
            return nil
        }

        let firstBytes = Array(firstFrame.data[1...4])
        let secondBytes = Array(secondFrame.data[1...4])
        let allBytes = firstBytes + secondBytes

        return allBytes.map { String(format: "%02X", $0) }.joined()
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

    /// 解析灯光颜色参数返回帧 (CMD 0x30)
    /// 数据格式: SS RR GG BB CUR
    func parseLightColorResponse(_ frame: ParsedFrame) -> LightColorFrame? {
        guard frame.isValid && frame.cmd == 0x30 && frame.data.count >= 5 else { return nil }
        return LightColorFrame(
            slot: frame.data[0],
            r: frame.data[1],
            g: frame.data[2],
            b: frame.data[3],
            currentSlot: frame.data[4]
        )
    }

    /// 解析灯光亮度参数返回帧 (CMD 0x31)
    /// 数据格式: SS BR_H BR_L BREATH DIR
    func parseLightBrightnessResponse(_ frame: ParsedFrame) -> LightBrightnessFrame? {
        guard frame.isValid && frame.cmd == 0x31 && frame.data.count >= 5 else { return nil }
        let brightness = UInt16(frame.data[1]) << 8 | UInt16(frame.data[2])
        let breathing = frame.data[3] == 0x01
        return LightBrightnessFrame(
            slot: frame.data[0],
            brightness: brightness,
            breathing: breathing,
            direction: frame.data[4]
        )
    }

    /// 解析历史记录时间返回帧 (CMD 0x07/0x08/0x09 第一帧)
    /// 数据格式: YY MM DD HH MIN
    func parseHistoryTimeResponse(_ frame: ParsedFrame) -> HistoryTimeFrame? {
        guard frame.isValid && frame.data.count >= 5 else { return nil }
        return HistoryTimeFrame(
            year: frame.data[0],
            month: frame.data[1],
            day: frame.data[2],
            hour: frame.data[3],
            minute: frame.data[4]
        )
    }

    /// 解析历史记录数据返回帧 (CMD 0x07/0x08/0x09 第二帧)
    /// 数据格式: 80 MIN MAX 00 00
    func parseHistoryDataResponse(_ frame: ParsedFrame) -> HistoryDataFrame? {
        guard frame.isValid && frame.data.count >= 5 && frame.data[0] == 0x80 else { return nil }
        return HistoryDataFrame(minValue: frame.data[1], maxValue: frame.data[2])
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

    /// 清空多帧缓冲区
    func clearBuffer() {
        multiFrameBuffer.clear()
    }
}
