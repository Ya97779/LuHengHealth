//
//  BLEOTAService.swift
//  LuHengHealth
//
//  OTA固件升级服务
//  负责管理OTA升级流程、进度跟踪和日志记录

import Foundation
import Combine

// MARK: - OTA状态枚举
enum OTAState {
    case idle           // 等待选择固件
    case fileSelected   // 已选择固件
    case entering       // 进入OTA模式
    case transferring   // 传输中
    case verifying      // 验证中
    case complete       // 完成
    case failed         // 失败
}

// MARK: - OTA日志条目
struct OTALogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let isError: Bool
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - OTA升级服务
class BLEOTAService: ObservableObject {
    
    // MARK: - 发布属性
    
    /// 当前OTA状态
    @Published var state: OTAState = .idle
    
    /// 升级进度 (0~100)
    @Published var progress: Int = 0
    
    /// 日志列表
    @Published var logs: [OTALogEntry] = []
    
    /// 已选择的固件文件名
    @Published var firmwareFileName: String?
    
    /// 已选择的固件数据
    @Published var firmwareData: Data?
    
    /// 错误信息
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    
    /// 固件总大小
    private var firmwareSize: UInt32 = 0
    
    /// 固件校验和
    private var firmwareChecksum: UInt16 = 0
    
    /// 当前发送的包序号
    private var currentSequence: UInt16 = 0
    
    /// 总包数
    private var totalPackets: UInt16 = 0
    
    /// 写入数据回调
    private var writeHandler: ((Data) -> Void)?
    
    /// 取消订阅
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    /// 设置写入回调
    /// - Parameter handler: 写入数据的回调函数
    func setWriteHandler(_ handler: @escaping (Data) -> Void) {
        self.writeHandler = handler
    }
    
    // MARK: - 固件文件管理
    
    /// 选择固件文件
    /// - Parameter data: 固件文件数据
    /// - Parameter fileName: 文件名
    func selectFirmware(data: Data, fileName: String) {
        self.firmwareData = data
        self.firmwareFileName = fileName
        self.firmwareSize = UInt32(data.count)
        self.firmwareChecksum = calculateFirmwareChecksum(data)
        self.state = .fileSelected
        self.errorMessage = nil
        
        addLog("已选择固件文件: \(fileName)")
        addLog("文件大小: \(data.count) 字节")
        addLog("校验和: \(String(format: "%04X", firmwareChecksum))")
    }
    
    /// 清除固件选择
    func clearFirmware() {
        self.firmwareData = nil
        self.firmwareFileName = nil
        self.firmwareSize = 0
        self.firmwareChecksum = 0
        self.state = .idle
        self.progress = 0
        self.errorMessage = nil
    }
    
    // MARK: - OTA升级流程
    
    /// 开始OTA升级
    func startOTA() {
        guard let firmwareData = firmwareData, firmwareData.count > 0 else {
            addLog("错误: 未选择固件文件", isError: true)
            return
        }
        
        guard let writeHandler = writeHandler else {
            addLog("错误: 蓝牙未连接", isError: true)
            return
        }
        
        // 重置状态
        self.progress = 0
        self.currentSequence = 0
        self.totalPackets = UInt16((firmwareData.count + 63) / 64) // 向上取整
        self.state = .entering
        self.errorMessage = nil
        
        addLog("开始OTA升级...")
        addLog("固件大小: \(firmwareData.count) 字节")
        addLog("总包数: \(totalPackets)")
        
        // 步骤1: 发送进入OTA模式命令
        addLog("发送进入OTA模式命令...")
        let enterCommand = BLECommandBuilder.enterOTAMode()
        writeHandler(enterCommand)
        
        // 等待设备响应后继续（通过handleOTAAck处理）
    }
    
    /// 处理OTA ACK响应
    /// - Parameters:
    ///   - cmd: 命令码
    ///   - status: 状态码
    ///   - seqHigh: 序列号高字节
    ///   - seqLow: 序列号低字节
    ///   - progress: 进度
    ///   - errorCode: 错误码
    func handleOTAAck(cmd: UInt8, status: UInt8, seqHigh: UInt8, seqLow: UInt8, progress: UInt8, errorCode: UInt8) {
        let seq = UInt16(seqHigh) << 8 | UInt16(seqLow)
        
        switch cmd {
        case 0x40: // 进入OTA模式响应
            if status == 0x00 {
                addLog("成功进入OTA模式")
                self.state = .transferring
                // 发送开始升级帧
                sendStartFrame()
            } else {
                addLog("进入OTA模式失败: 错误码 \(errorCode)", isError: true)
                self.state = .failed
                self.errorMessage = "进入OTA模式失败"
            }
            
        case 0x90: // 开始升级响应
            if status == 0x00 {
                addLog("开始升级成功，开始传输数据包...")
                self.state = .transferring
                // 开始发送数据包
                sendNextDataPacket()
            } else {
                addLog("开始升级失败: 错误码 \(errorCode)", isError: true)
                self.state = .failed
                self.errorMessage = "开始升级失败"
            }
            
        case 0x91: // 数据包响应
            if status == 0x00 {
                self.progress = Int(progress)
                addLog("数据包 \(seq + 1)/\(totalPackets) 已确认")
                // 发送下一个数据包
                sendNextDataPacket()
            } else {
                addLog("数据包 \(seq) 传输失败: 错误码 \(errorCode)", isError: true)
                self.state = .failed
                self.errorMessage = "数据包传输失败"
            }
            
        case 0x92: // 结束升级响应
            if status == 0x00 {
                addLog("OTA升级完成！")
                self.progress = 100
                self.state = .complete
                addLog("请重启设备以完成固件更新")
            } else {
                addLog("OTA结束校验失败: 错误码 \(errorCode)", isError: true)
                self.state = .failed
                self.errorMessage = "OTA结束校验失败"
            }
            
        default:
            break
        }
    }
    
    // MARK: - 私有方法
    
    /// 发送开始升级帧
    private func sendStartFrame() {
        guard let writeHandler = writeHandler else { return }
        
        addLog("发送开始升级帧...")
        let startFrame = BLECommandBuilder.buildOTAStartFrame(
            firmwareSize: firmwareSize,
            checksum: firmwareChecksum
        )
        writeHandler(startFrame)
    }
    
    /// 发送下一个数据包
    private func sendNextDataPacket() {
        guard let firmwareData = firmwareData, let writeHandler = writeHandler else { return }
        
        // 检查是否已发送完所有数据包
        guard currentSequence < totalPackets else {
            // 所有数据包已发送，发送结束帧
            sendEndFrame()
            return
        }
        
        // 计算当前包的数据范围
        let startIndex = Int(currentSequence) * 64
        let endIndex = min(startIndex + 64, firmwareData.count)
        let packetData = firmwareData.subdata(in: startIndex..<endIndex)
        
        // 发送数据包
        let dataPacket = BLECommandBuilder.buildOTADataPacket(
            sequence: currentSequence,
            data: packetData
        )
        writeHandler(dataPacket)
        
        currentSequence += 1
    }
    
    /// 发送结束升级帧
    private func sendEndFrame() {
        guard let writeHandler = writeHandler else { return }
        
        addLog("发送结束升级帧...")
        let endFrame = BLECommandBuilder.buildOTAEndFrame(
            firmwareSize: firmwareSize,
            checksum: firmwareChecksum
        )
        writeHandler(endFrame)
    }
    
    /// 计算固件校验和
    /// - Parameter data: 固件数据
    /// - Returns: 16位校验和
    private func calculateFirmwareChecksum(_ data: Data) -> UInt16 {
        var sum: UInt32 = 0
        for byte in data {
            sum += UInt32(byte)
        }
        return UInt16(sum & 0xFFFF)
    }
    
    /// 添加日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - isError: 是否为错误日志
    private func addLog(_ message: String, isError: Bool = false) {
        let entry = OTALogEntry(
            timestamp: Date(),
            message: message,
            isError: isError
        )
        
        DispatchQueue.main.async {
            self.logs.append(entry)
            print("[OTA] \(message)")
        }
    }
}
