//
//  BLEViewModel.swift
//  bleframeworktest
//
//  Created by macios on 2025/8/25.
//
//  蓝牙低功耗(BLE)视图模型
//  负责管理蓝牙设备的扫描、连接、断开等核心功能
//  使用WCHBLELibrary进行蓝牙设备管理

import Foundation
import CoreBluetooth

#if !targetEnvironment(simulator)
import WCHBLELibrary
#else
// 模拟器环境下的WCHBLEManager空实现
class WCHBLEManager: NSObject {
    weak var delegate: BLEAssistDelegate?
    var isDebug: Bool = false
    var serviceUUIDS: [CBUUID]?
    
    private static let instance = WCHBLEManager()
    
    static func getInstance() -> WCHBLEManager {
        return instance
    }
    
    func startScan(_ serviceUUIDs: [CBUUID]?, options: [String: Any]?) {
        print("[模拟器] WCHBLEManager.startScan - 蓝牙功能在模拟器上不可用")
    }
    
    func stopScan() {
        print("[模拟器] WCHBLEManager.stopScan")
    }
    
    func connect(_ peripheral: CBPeripheral?) {
        print("[模拟器] WCHBLEManager.connect - 蓝牙功能在模拟器上不可用")
    }
    
    func disconnect(_ peripheral: CBPeripheral?) {
        print("[模拟器] WCHBLEManager.disconnect")
    }
    
    func readLog() -> [Any] {
        return []
    }
}

@objc protocol BLEAssistDelegate: AnyObject {
    @objc optional func bleManagerDidUpdateState(_ error: Error?)
    @objc optional func bleManagerDidDiscover(_ peripheral: CBPeripheral?, advertisementData: [String: Any]?, rssi RSSI: NSNumber?)
    @objc optional func bleManagerDidPeripheralConnectUpateState(_ peripheral: CBPeripheral?, error: Error?)
    @objc optional func bleManagerPeriphearl(_ peripheral: CBPeripheral?, services: [CBService]?, error: Error?)
    @objc optional func bleManagerService(_ service: CBService?, characteristics: [CBCharacteristic]?, error: Error?)
    @objc optional func bleManagerUpdateValue(forCharacteristic peripheral: CBPeripheral?, characteristic: CBCharacteristic?, error: Error?)
}
#endif


// MARK: - 设备连接状态枚举
/// 定义蓝牙设备的连接状态
/// 用于跟踪设备从发现到连接再到断开的完整生命周期
enum DeviceConnectionState {
    case disconnected    // 未连接状态：设备已发现但未建立连接
    case connecting     // 连接中状态：正在尝试建立连接
    case connected      // 已连接状态：成功建立连接，可以进行数据通信
    case disconnecting  // 断开中状态：正在断开连接
}

// MARK: - 蓝牙设备数据模型
/// 蓝牙设备的数据结构，包含设备的基本信息和连接状态
/// 实现了Identifiable协议，支持在SwiftUI列表中显示
struct BluetoothDevice: Identifiable {
    /// 设备的唯一标识符，用于在UI中区分不同设备
    let id = UUID()
    
    /// 系统蓝牙外设对象，包含设备的底层信息
    let peripheral: CBPeripheral
    
    /// 设备的当前连接状态，默认为未连接
    var connectionState: DeviceConnectionState = .disconnected
    
    /// 接收信号强度指示器(RSSI)，数值越大信号越强
    /// 通常范围：-100dBm(很弱) 到 -30dBm(很强)
    var rssi: NSNumber = -100
    
    /// 设备的广播数据，包含制造商信息、服务UUID等
    /// 这些数据在设备发现时获取，用于设备识别和过滤
    var advertisementData: [String: Any] = [:]
    
    // MARK: - 计算属性
    
    /// 设备显示名称
    var name: String {
        return peripheral.name ?? "未知设备"
    }
    
    /// 设备唯一标识符
    var identifier: UUID {
        return peripheral.identifier
    }
    
    /// 是否可连接（来自广播数据 kCBAdvDataIsConnectable）
    var isConnectable: Bool {
        if let v = advertisementData["kCBAdvDataIsConnectable"] as? NSNumber {
            return v.boolValue
        }
        if let v = advertisementData["kCBAdvDataIsConnectable"] as? Bool {
            return v
        }
        return false
    }
    
    /// 服务UUID展示（如: FDAA, 180D），优先 16-bit 展示，若为空返回 "-"
    var serviceUUIDsText: String {
        if let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID], !uuids.isEmpty {
            let items = uuids.map { u in
                let s = u.uuidString
                // 常见厂商用16-bit短UUID，直接显示大写
                return s
            }
            return items.joined(separator: ", ")
        }
        return "-"
    }
    
    /// 厂商数据预览（长度与前几个字节的十六进制），如: len=22 8F032B11...
    var manufacturerPreview: String {
        if let data = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let hex = data.prefix(8).map { String(format: "%02X", $0) }.joined()
            return "len=\(data.count) \(hex)"
        }
        return "-"
    }
}

// MARK: - 蓝牙视图模型主类
/// 蓝牙功能的核心视图模型类
/// 继承NSObject以支持Objective-C代理模式
/// 实现ObservableObject协议以支持SwiftUI的数据绑定
class BLEViewModel: NSObject, ObservableObject {
    
    // 1) 目标 UUID：集中定义
    private let targetServiceUUID = CBUUID(string: "FFE0")  // 服务
    private let notifyCharUUID    = CBUUID(string: "FFE4")  // 订阅通知
    private let writeCharUUID     = CBUUID(string: "FFE3")  // 写入数据
    
    // 2) 持久保存发现到的目标特征，便于后续直接使用
    private var notifyChar: CBCharacteristic?   // FFE4
    private var writeChar:  CBCharacteristic?   // FFE3
    
    // 3) 健康数据存储服务
    private let healthDataStorage = HealthDataStorage.shared
    
    
    
    // MARK: - 发布属性 (UI数据绑定)
    
    // 3) 给 UI 的可观察字段
    @Published var ffe4HexText: String = "--"   // FFE4 最新十六进制文本
    @Published var heartRate: Int? = nil        // 解析后的心率值
    @Published var bloodOxygen: Int? = nil      // 解析后的血氧值
    @Published var batteryVoltage: Int? = nil   // 解析后的电池电压值（百分比）
    @Published var stepCount: Int? = nil        // 解析后的步数 (v1.2新增)
    @Published var firmwareVersion: Int? = nil  // 解析后的固件版本号 (v1.2新增)
    @Published var isFfe4Notifying = false      // FFE4 订阅状态（可在 UI 做开关展示）

    // MARK: - 新协议属性 (v2.0 CMD模式)

    // OTA服务引用（用于转发OTA ACK）
    weak var otaService: BLEOTAService?

    // 序列号
    @Published var serialNumber: String? = nil

    // 告警相关
    @Published var currentAlarm: AlarmData? = nil
    @Published var alarmMessage: String? = nil
    @Published var showAlarm: Bool = false

    // 灯光参数回读（当前槽）
    @Published var lightSlot: UInt8 = 0
    @Published var lightRed: UInt8 = 0
    @Published var lightGreen: UInt8 = 0
    @Published var lightBlue: UInt8 = 0
    @Published var lightCurrentSlot: UInt8 = 0
    @Published var lightBrightness: UInt16 = 0
    @Published var lightBreathing: Bool = false

    // 三个灯光槽的RGB颜色存储
    @Published var slot0R: UInt8 = 128
    @Published var slot0G: UInt8 = 128
    @Published var slot0B: UInt8 = 128
    @Published var slot1R: UInt8 = 128
    @Published var slot1G: UInt8 = 128
    @Published var slot1B: UInt8 = 128
    @Published var slot2R: UInt8 = 128
    @Published var slot2G: UInt8 = 128
    @Published var slot2B: UInt8 = 128
    
    // 三个灯光槽的独立亮度存储
    @Published var slot0Brightness: UInt16 = 0
    @Published var slot1Brightness: UInt16 = 0
    @Published var slot2Brightness: UInt16 = 0

    // 历史数据（新协议：3天数据，每天24小时）
    @Published var heartRateHistory: [DayHistoryData] = []
    @Published var bloodOxygenHistory: [DayHistoryData] = []
    @Published var stepCountHistory: [HistoryRecord] = []  // 步数保持单条格式
    
    // 原始历史数据（用于调试）
    @Published var heartRateHistoryRawData: [String] = []
    @Published var bloodOxygenHistoryRawData: [String] = []
    @Published var stepCountHistoryRawData: [String] = []

    // 产品信息
    @Published var productModel: UInt8? = nil

    // 健康阈值
    @Published var healthThresholds: HealthAnomalyThresholds? = nil

    // ACK状态
    @Published var lastAckCmd: UInt8? = nil
    @Published var lastAckStatus: UInt8? = nil

    // MARK: - 历史记录结构体
    struct HistoryRecord: Equatable {
        let year: Int, month: Int, day: Int, hour: Int, minute: Int
        let value: Int
    }
    
    // MARK: - 每日历史数据结构体（新协议）
    struct DayHistoryData: Equatable {
        let date: String  // 格式: "2026-06-01"
        let hourlyValues: [Int]  // 24小时的值，索引0-23对应0-23时
    }

    // MARK: - 轮询定时器
    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 5.0

    // MARK: - 独立轮询控制
    @Published var isHeartRatePolling: Bool = false
    @Published var isBloodOxygenPolling: Bool = false
    @Published var isStepCountPolling: Bool = false

    // MARK: - 三个灯光槽的独立呼吸模式状态
    @Published var slot0Breathing: Bool = false
    @Published var slot1Breathing: Bool = false
    @Published var slot2Breathing: Bool = false
    
    // MARK: - 呼吸模式状态（根据当前槽位自动计算）
    var isBreathingMode: Bool {
        switch lightCurrentSlot {
        case 0: return slot0Breathing
        case 1: return slot1Breathing
        case 2: return slot2Breathing
        default: return false
        }
    }

    /// 发现的蓝牙设备列表，UI会自动响应此数组的变化
    @Published var discoveredDevices: [BluetoothDevice] = []
    
    /// 已连接的蓝牙设备列表，显示当前活跃连接
    @Published var connectedDevices: [BluetoothDevice] = []
    
    /// 扫描状态标志，用于控制UI中扫描按钮的显示
    @Published var isScanning = false
    
    /// 蓝牙系统状态，影响整个应用的功能可用性
    @Published var bluetoothState: CBManagerState = .unknown
    
    /// 是否显示提示框的标志
    @Published var showAlert = false
    
    /// 提示框显示的消息内容
    @Published var alertMessage = ""
    
    /// 详情页当前选中的设备（用于展示详情）
    @Published var selectedDeviceForDetail: BluetoothDevice?
    
    /// 每个外设的服务列表（按外设UUID存储）
    @Published var servicesByPeripheral: [UUID: [CBService]] = [:]
    
    /// 每个服务的特征列表（按服务UUID存储）
    @Published var characteristicsByService: [CBUUID: [CBCharacteristic]] = [:]
    
    /// 最新的广告数据（实时覆盖）
    @Published var latestAdvertisementByPeripheral: [UUID: [String: Any]] = [:]
    
    /// 最新的RSSI（实时覆盖）
    @Published var latestRSSIByPeripheral: [UUID: NSNumber] = [:]
    
    /// 最新的特征值（实时覆盖）
    @Published var latestValueByCharacteristic: [CBUUID: Data] = [:]
    
    /// 特征值日志（按时间追加，最多保留最近50条）
    @Published var valueLogByCharacteristic: [CBUUID: [Data]] = [:]

    /// 当前已连接设备的 GATT 概览（服务/特征/属性），供UI展示
    @Published var gattSummaryText: String = "（尚未发现任何服务）"

    /// 便捷获取以 Jewel 开头的已发现设备
    var jewelDevices: [BluetoothDevice] {
        discoveredDevices.filter { ($0.name.hasPrefix("Jewel")) }
    }
    
    // MARK: - 私有属性
    
    /// 第三方蓝牙管理器实例，负责与WCHBLELibrary交互
    private var bleManager: WCHBLEManager!
    
    /// 系统级 CBCentralManager（用于可靠获取蓝牙状态）
    private var systemCentral: CBCentralManager!
    
    // MARK: - 初始化方法
    
    /// 视图模型的初始化方法
    /// 设置蓝牙管理器、代理和初始状态检查
    override init() {
        super.init()
        
        print("初始化BLEViewModel...")
        
        // 使用系统 CBCentralManager 持久化实例 + 委托，确保能收到状态回调
        self.systemCentral = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        
        // 获取WCHBLELibrary的单例实例
        bleManager = WCHBLEManager.getInstance()
        
        if let manager = bleManager {
            print("WCHBLEManager获取成功")
            
            // 设置代理，接收蓝牙事件回调
            manager.delegate = self
            
            // 开启调试模式，输出详细的蓝牙操作日志
            manager.isDebug = false
            print("设置delegate和debug模式完成")
            
            // 不再延迟主动调用 checkBluetoothState，由 CBCentralManagerDelegate 回调触发
        
        // 启动时清理超过30天的旧数据
        cleanupOldHealthData(keepDays: 30)
        } else {
            print("WCHBLEManager获取失败")
            // 如果获取失败，设置蓝牙状态为不支持
            DispatchQueue.main.async {
                self.bluetoothState = .unsupported
            }
        }
    }
    
    // MARK: - 蓝牙状态检查
    
    /// 检查蓝牙系统状态的方法
    /// 结合系统蓝牙状态和第三方库状态，确定最终的蓝牙可用性
    private func checkBluetoothState() {
        print("开始检查蓝牙状态(系统Central现态)...")
        guard let central = self.systemCentral else {
            print("systemCentral 未初始化")
            DispatchQueue.main.async { self.bluetoothState = .unknown }
            return
        }
        let systemState = central.state
        print("系统蓝牙状态: \(systemState.rawValue)")
        DispatchQueue.main.async { self.bluetoothState = systemState }
    }
    
    // MARK: - 扫描控制方法
    
    /// 开始扫描蓝牙设备
    /// 使用WCHBLELibrary进行设备扫描
    func startScan() {
        // 仅当系统蓝牙已开启时允许扫描
        guard bluetoothState == .poweredOn else {
            showAlertMessage("蓝牙不可用：\(bluetoothState)")
            return
        }
        // 避免重复调用导致底层报“已经在扫描”
        guard !isScanning else {
            print("已在扫描中，忽略重复 startScan()")
            return
        }
        // 复位旧列表
        discoveredDevices.removeAll()
        // 防御性：先停止一次底层扫描，确保干净状态
        bleManager.stopScan()
        // 切换状态并启动扫描
        isScanning = true
        print("开始扫描...")
        // 允许重复广播回调（若底层支持该选项，无则传空字典）
        bleManager.startScan(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        // 20秒后自动停止扫描，避免持续扫描消耗电量
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.isScanning {
                self.stopScan()
                self.showAlertMessage("扫描完成")
            }
        }
    }
    
    /// 停止扫描蓝牙设备
    /// 版本只在扫描中才触发停止并在结束后打印 Jewel 清单
    func stopScan() {
        guard isScanning else {
            print("当前未在扫描，忽略 stopScan()")
            return
        }
        isScanning = false
        bleManager.stopScan()
        // 扫描结束后打印 Jewel* 设备列表，便于在控制台确认并选择
        printJewelDeviceList()
    }
    
    // MARK: - 设备连接管理
    
    /// 连接到指定的蓝牙设备
    /// 更新设备状态并调用底层连接方法
    /// - Parameter device: 要连接的蓝牙设备
    func connect(to device: BluetoothDevice) {
        // 在发现的设备列表中找到目标设备并更新状态
        if let index = discoveredDevices.firstIndex(where: { $0.identifier == device.identifier }) {
            discoveredDevices[index].connectionState = .connecting
        }
        // 触发底层连接
        bleManager.connect(device.peripheral)
    }
    
    /// 断开与指定设备的连接
    /// 更新设备状态并调用底层断开方法
    /// - Parameter device: 要断开的蓝牙设备
    func disconnect(from device: BluetoothDevice) {
        // 标记断开中
        if let index = connectedDevices.firstIndex(where: { $0.identifier == device.identifier }) {
            connectedDevices[index].connectionState = .disconnecting
        }
        // 发起底层断开
        bleManager.disconnect(device.peripheral)
    }
    /// 将某个外设标记为“已连接”：从 discovered 移入 connected，并设置 .connected
    private func markConnected(_ peripheral: CBPeripheral) {
        let pid = peripheral.identifier
        // 从发现列表中取出（如果存在），并构造最新的模型
        var dev: BluetoothDevice
        if let idx = discoveredDevices.firstIndex(where: { $0.identifier == pid }) {
            dev = discoveredDevices.remove(at: idx)
        } else if let idx = connectedDevices.firstIndex(where: { $0.identifier == pid }) {
            dev = connectedDevices[idx]
        } else {
            // 若两个列表都没有，就根据缓存临时构造
            dev = BluetoothDevice(
                peripheral: peripheral,
                rssi: latestRSSIByPeripheral[pid] ?? -100,
                advertisementData: latestAdvertisementByPeripheral[pid] ?? [:]
            )
        }
        dev.connectionState = .connected
        // 如果 connected 中已有相同设备，先移除旧项，避免重复
        if let dup = connectedDevices.firstIndex(where: { $0.identifier == pid }) {
            connectedDevices.remove(at: dup)
        }
        connectedDevices.append(dev)
        
        // 连接上后，通常可以停止扫描以省电（如你不希望自动停止，可删除此行）
        if isScanning { stopScan() }
    }
    
    /// 将某个外设标记为“未连接”：从 connected 移回 discovered，并设置 .disconnected，清理缓存
    private func markDisconnected(_ peripheral: CBPeripheral, reason: String?) {
        let pid = peripheral.identifier
        
        // 从已连接列表移除
        var dev: BluetoothDevice?
        if let idx = connectedDevices.firstIndex(where: { $0.identifier == pid }) {
            dev = connectedDevices.remove(at: idx)
        }
        // 如果没在 connected 里，尝试从 discovered 里取（用于连接失败等场景）
        if dev == nil, let dIdx = discoveredDevices.firstIndex(where: { $0.identifier == pid }) {
            dev = discoveredDevices[dIdx]
        }
        // 构造/更新一个断开状态的设备模型
        var model = dev ?? BluetoothDevice(
            peripheral: peripheral,
            rssi: latestRSSIByPeripheral[pid] ?? -100,
            advertisementData: latestAdvertisementByPeripheral[pid] ?? [:]
        )
        model.connectionState = .disconnected
        
        // 写回到 discovered（去重）
        if let exist = discoveredDevices.firstIndex(where: { $0.identifier == pid }) {
            discoveredDevices[exist] = model
        } else {
            discoveredDevices.append(model)
        }
        
        // 清理该外设关联的服务/特征/值缓存
        servicesByPeripheral[pid] = nil
        // 移除与该外设服务相关的特征条目
        let relatedServiceUUIDs = characteristicsByService.keys.filter { svcUUID in
            // 这里无法直接从 UUID 反查外设，只做保守清理：若你项目有映射表可更精准
            return true
        }
        relatedServiceUUIDs.forEach { characteristicsByService[$0] = nil }
        
        // 如果当前详情页展示的就是该设备，关闭详情
        if let selected = selectedDeviceForDetail, selected.identifier == pid {
            selectedDeviceForDetail = nil
        }
        
        // 无论断开的是哪个设备，都清空实时数据
        notifyChar = nil
        writeChar  = nil
        isFfe4Notifying = false
        ffe4HexText = "--"
        heartRate = nil
        bloodOxygen = nil
        batteryVoltage = nil
        stepCount = nil  // v1.2新增
        firmwareVersion = nil  // v1.2新增
        stopPolling()

        if let why = reason, !why.isEmpty {
            print("已断开：\(peripheral.name ?? "未知设备")，原因：\(why)")
        } else {
            print("已断开：\(peripheral.name ?? "未知设备")")
        }
    }
    
    // MARK: - 辅助方法
    
    /// 显示提示消息
    /// 设置提示内容和显示标志，触发UI更新
    /// - Parameter message: 要显示的消息内容
    private func showAlertMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    /// 添加或更新发现的蓝牙设备
    /// 包含设备过滤逻辑，确保只显示有用的设备
    /// - Parameters:
    ///   - peripheral: 系统蓝牙外设对象
    ///   - rssi: 信号强度
    ///   - advertisementData: 广播数据
    private func addOrUpdateDevice(_ peripheral: CBPeripheral, rssi: NSNumber, advertisementData: [String: Any]) {
        // 仅按 UUID 去重，保留所有设备（无论信号强弱、是否有名称）
        if let index = discoveredDevices.firstIndex(where: { $0.identifier == peripheral.identifier }) {
            // 更新已存在设备的信息
            discoveredDevices[index].rssi = rssi
            discoveredDevices[index].advertisementData = advertisementData
        } else {
            // 新增设备
            let device = BluetoothDevice(
                peripheral: peripheral,
                rssi: rssi,
                advertisementData: advertisementData
            )
            discoveredDevices.append(device)
        }
    }

    /// 打印以 Jewel 开头的设备列表（在停止扫描后调用）
    private func printJewelDeviceList() {
        let list = jewelDevices
        print("====== 扫描完成：Jewel* 设备清单（共 \(list.count) 台）======")
        if list.isEmpty {
            print("（无）")
            return
        }
        for (idx, dev) in list.enumerated() {
            let name = dev.name
            let id   = dev.identifier.uuidString
            let rssi = dev.rssi.intValue
            let svcText = dev.serviceUUIDsText
            print("[\(idx)] \(name)  RSSI:\(rssi)  ID:\(id)  Services:\(svcText)")
        }
        print("====== （点击列表项进行连接）======")
    }

    /// 根据当前缓存的 services/characteristics 生成 GATT 概览文本
    private func rebuildGattSummary(for peripheral: CBPeripheral) {
        let pid = peripheral.identifier
        guard let services = servicesByPeripheral[pid], !services.isEmpty else {
            gattSummaryText = "（尚未发现任何服务）"
            return
        }
        var lines: [String] = []
        lines.append("设备：\(peripheral.name ?? "未知")")
        lines.append("ID：\(pid.uuidString)")
        lines.append("服务数量：\(services.count)")
        for (sidx, svc) in services.enumerated() {
            lines.append(String(format: "\n[%02d] Service %@", sidx, svc.uuid.uuidString))
            let chars = characteristicsByService[svc.uuid] ?? []
            if chars.isEmpty {
                lines.append("  （无特征）")
            } else {
                for (cidx, ch) in chars.enumerated() {
                    let props = describeProperties(ch.properties)
                    lines.append(String(format: "  (%02d) Char %@  Properties: %@", cidx, ch.uuid.uuidString, props))
                    // 如果有Descriptors，也列出
                    if let descs = ch.descriptors, descs.isEmpty == false {
                        for d in descs {
                            lines.append("       • Desc \(d.uuid.uuidString)")
                        }
                    }
                }
            }
        }
        gattSummaryText = lines.joined(separator: "\n")
        // 同时打印到控制台
        print("====== GATT 概览 ======\n\(gattSummaryText)\n=======================")
    }

    /// 将 CBCharacteristicProperties 转为可读文本
    private func describeProperties(_ p: CBCharacteristicProperties) -> String {
        var items: [String] = []
        if p.contains(.read) { items.append("Read") }
        if p.contains(.write) { items.append("Write") }
        if p.contains(.writeWithoutResponse) { items.append("WriteNR") }
        if p.contains(.notify) { items.append("Notify") }
        if p.contains(.indicate) { items.append("Indicate") }
        if p.contains(.broadcast) { items.append("Broadcast") }
        if p.contains(.authenticatedSignedWrites) { items.append("SignedWrites") }
        if p.contains(.extendedProperties) { items.append("ExtendedProps") }
        if p.contains(.notifyEncryptionRequired) { items.append("NotifyEncReq") }
        if p.contains(.indicateEncryptionRequired) { items.append("IndicateEncReq") }
        return items.isEmpty ? "-" : items.joined(separator: "|")
    }
    
    // MARK: - 公共操作（读取/订阅）
    
    /// 读取特征值（若支持可读）
    func readValue(for characteristic: CBCharacteristic) {
        characteristic.service?.peripheral?.readValue(for: characteristic)
    }
    
    /// 设置特征订阅（通知）
    func setNotify(_ enabled: Bool, for characteristic: CBCharacteristic) {
        characteristic.service?.peripheral?.setNotifyValue(enabled, for: characteristic)
    }
}

// MARK: - WCHBLELibrary代理实现
/// 实现WCHBLELibrary的代理协议
/// 处理蓝牙事件回调，更新UI状态
extension BLEViewModel: BLEAssistDelegate {
    
    /// 蓝牙管理器状态更新回调
    /// 当蓝牙系统状态发生变化时被调用
    /// - Parameter error: 错误信息，如果为nil表示状态正常
    func bleManagerDidUpdateState(_ error: (any Error)!) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCH 状态回调（仅日志，不影响UI）：\(error.localizedDescription)")
            } else {
                print("WCH 状态回调（无错误）")
            }
        }
    }
    
    /// 发现蓝牙设备回调
    /// 当扫描到新的蓝牙设备时被调用
    /// - Parameters:
    ///   - peripheral: 发现的蓝牙外设对象
    ///   - advertisementData: 设备的广播数据
    ///   - RSSI: 信号强度
    func bleManagerDidDiscover(_ peripheral: CBPeripheral!,
                               advertisementData: [String : Any]!,
                               rssi RSSI: NSNumber!) {
        // ：WCH 的回调可能不在主线程，UI 相关状态更新统一切回主线程
        DispatchQueue.main.async {
            // 1) 兜底拿到外设对象；若为空直接返回
            guard let p = peripheral else { return }
            
            // 2) 读取设备名：优先 peripheral.name，若无则用广播本地名
            let advName = (advertisementData?[CBAdvertisementDataLocalNameKey] as? String) ?? ""
            let deviceName = p.name ?? advName
            
            // 4) 日志便于观测
            let rssiVal = RSSI ?? -100
            print("发现设备: \(deviceName)  RSSI:\(rssiVal)")
            
            // 5) 既然能发现设备，基本可认为蓝牙处于可用态；若 UI 尚未更新则同步一下
            if self.bluetoothState != .poweredOn {
                self.bluetoothState = .poweredOn
            }
            
            // 6) 缓存该外设的最新广播与 RSSI，供详情页/列表展示
            self.latestAdvertisementByPeripheral[p.identifier] = advertisementData
            self.latestRSSIByPeripheral[p.identifier] = rssiVal
            
            // 7) 构造或更新一个 BluetoothDevice（你的项目模型）
            //    - isConnectable/服务UUID/厂商数据等可从 advertisementData 里读取，模型里已有相应计算属性做展示
            var candidate = BluetoothDevice(
                peripheral: p,
                connectionState: .disconnected,
                rssi: rssiVal,
                advertisementData: advertisementData ?? [:]
            )
            
            // 8) 若该外设已在「已连接列表」中，就不再往「已发现列表」重复添加
            if self.connectedDevices.contains(where: { $0.identifier == p.identifier }) {
                // 但我们仍可更新缓存的广播与 RSSI（第 6 步已做）
                return
            }
            
            // 9) 根据 identifier 去重：已存在则做就地更新（RSSI/广告）；不存在则新增
            if let idx = self.discoveredDevices.firstIndex(where: { $0.identifier == p.identifier }) {
                // 更新已有项（保持列表稳定，避免闪烁）
                candidate.connectionState = self.discoveredDevices[idx].connectionState
                self.discoveredDevices[idx] = candidate
            } else {
                // 新发现：追加进列表
                self.discoveredDevices.append(candidate)
            }
        }
    }
    
    /// 设备连接状态更新回调
    /// 当设备连接或断开连接时被调用
    /// - Parameters:
    ///   - peripheral: 状态发生变化的蓝牙外设
    ///   - error: 连接过程中的错误信息
    func bleManagerDidPeripheralConnectUpateState(_ peripheral: CBPeripheral!, error: (any Error)!) {
        print("连接状态更新: \(peripheral?.name ?? "未知") 错误: \(error?.localizedDescription ?? "无")")
        
        DispatchQueue.main.async {
            guard let p = peripheral else { return }
            if error == nil {
                // 连接成功：迁移到已连接列表，更新状态，并开始发现服务
                self.markConnected(p)
                self.notifyChar = nil
                self.writeChar  = nil
                self.isFfe4Notifying = false
                self.ffe4HexText = "--"
                self.heartRate = nil
                self.bloodOxygen = nil
                self.batteryVoltage = nil
                self.stepCount = nil  // v1.2新增
                self.firmwareVersion = nil  // v1.2新增

                // 重置存储缓存，开始新设备的数据记录
                self.resetStorageCache()
                
                p.discoverServices([self.targetServiceUUID])   // 仅发现目标服务
            } else {
                // 连接失败或已断开：迁移回发现列表并提示
                self.markDisconnected(p, reason: error.localizedDescription)
                self.showAlertMessage("连接失败或已断开：\(error.localizedDescription)")
            }
        }
    }
    
    
    /// 发现设备服务回调
    /// 当连接到设备后发现其提供的服务时被调用
    /// - Parameters:
    ///   - peripheral: 蓝牙外设
    ///   - services: 发现的服务列表
    ///   - error: 服务发现过程中的错误
    func bleManagerPeriphearl(_ peripheral: CBPeripheral!, services: [CBService]!, error: (any Error)!) {
        print("发现服务: \(services?.map{$0.uuid.uuidString} ?? [])")
        DispatchQueue.main.async {
            guard let p = peripheral, let services = services else { return }
            // 存起来（若你 UI 需要展示服务列表）
            self.servicesByPeripheral[p.identifier] = services

            // 只对 FFE0 继续发现特征
            if let svc = services.first(where: { $0.uuid == self.targetServiceUUID }) {
                p.discoverCharacteristics(nil, for: svc)  // 发现全部特征后再筛
            }
            // 服务一经发现就重建一次概览（此时可能还没有特征，后续会继续完善）
            self.rebuildGattSummary(for: p)
        }
    }
    
    /// 发现服务特征回调
    /// 当发现服务的特征时被调用
    /// - Parameters:
    ///   - service: 包含特征的服务
    ///   - characteristics: 发现的特征列表
    ///   - error: 特征发现过程中的错误
    func bleManagerService(_ service: CBService!, characteristics: [CBCharacteristic]!, error: (any Error)!) {
        print("发现特征: \(characteristics?.map{$0.uuid.uuidString} ?? [])")
        DispatchQueue.main.async {
            guard let service = service,
                  let chars = characteristics,
                  let peripheral = service.peripheral else { return }

            // 存起来（若 UI 需要展示特征列表）
            self.characteristicsByService[service.uuid] = chars

            // 仅处理目标服务 FFE0
            guard service.uuid == self.targetServiceUUID else {
                // 不是目标服务也可能需要展示特征，重建概览
                self.rebuildGattSummary(for: peripheral)
                return
            }

            // 1) 找到 FEE4（订阅通知的特征）
            if let c = chars.first(where: { $0.uuid == self.notifyCharUUID }) {
                self.notifyChar = c
                // 能订阅就订阅
                if c.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: c) // 打开通知
                    self.isFfe4Notifying = true
                }
                // 能读就读一次，让 UI 立即有内容
                if c.properties.contains(.read) {
                    peripheral.readValue(for: c)
                }
            } else {
                // 可选：打印帮助排查
                // print("未在 FFE0 下发现 FEE4")
            }

            // 2) 找到 FFE3（写入数据的特征）
            if let w = chars.first(where: { $0.uuid == self.writeCharUUID }) {
                self.writeChar = w
                self.startPolling()
            } else {
                // print("未在 FFE0 下发现 FFE3")
            }
            // 每当某个服务的特征发现完成后，重建概览，UI 将显示更完整的信息
            self.rebuildGattSummary(for: peripheral)
        }
    }
    
    /// 特征值更新回调
    /// 当特征值发生变化时被调用
    /// - Parameters:
    ///   - peripheral: 蓝牙外设
    ///   - characteristic: 值发生变化的特征
    ///   - error: 值更新过程中的错误
    func bleManagerUpdateValue(forCharacteristic peripheral: CBPeripheral!, characteristic: CBCharacteristic!, error: (any Error)!) {
        DispatchQueue.main.async {
                guard error == nil,
                      let characteristic = characteristic,
                      let value = characteristic.value else {
                    if let error = error {
                        print("[BLE] ❌ 特征值更新错误: \(error.localizedDescription)")
                    }
                    return
                }

                let hexStr = BLEProtocolParser.shared.bytesToHexString(value)

                self.latestValueByCharacteristic[characteristic.uuid] = value
                self.valueLogByCharacteristic[characteristic.uuid, default: []].append(value)

                if characteristic.uuid == self.notifyCharUUID {
                    self.ffe4HexText = hexStr

                    let frame = BLEProtocolParser.shared.parse(value)

                    if !frame.isValid {
                        print("[BLE] ⚠️ 帧校验失败: \(hexStr)")
                        return
                    }

                    // 电量数据不打印日志（每5秒轮询一次，会刷屏）
                    let isBatteryData = frame.type == .responseFrame && frame.cmd == 0x04
                    
                    if !isBatteryData {
                        print("[BLE] 📥 收到 \(characteristic.uuid.uuidString): \(hexStr)")
                    }

                    switch frame.type {
                    case .responseFrame:
                        if !isBatteryData {
                            print("[BLE] 📋 返回帧 CMD=0x\(String(format: "%02X", frame.cmd)) 数据=\(BLEProtocolParser.shared.bytesToHexString(Data(frame.data)))")
                        }
                        self.handleResponseFrame(frame)
                    case .ackFrame:
                        print("[BLE] ✅ ACK帧 原CMD=0x\(String(format: "%02X", frame.originalCmd ?? 0)) 状态=\(frame.status == 0x01 ? "成功" : "失败")")
                        self.handleAckFrame(frame)
                    case .otaAck:
                        print("[BLE] 🔄 OTA ACK帧 CMD=0x\(String(format: "%02X", frame.cmd))")
                        // 转发给OTA服务处理
                        if frame.isValid && frame.data.count >= 6 {
                            self.otaService?.handleOTAAck(
                                cmd: frame.data[0],
                                status: frame.data[1],
                                seqHigh: frame.data[2],
                                seqLow: frame.data[3],
                                progress: frame.data[4],
                                errorCode: frame.data[5]
                            )
                        }
                        break
                    case .unknown:
                        print("[BLE] ❓ 未知帧类型: \(hexStr)")
                        break
                    }
                }
            }
    }

    // MARK: - 新协议数据处理

    private func handleResponseFrame(_ frame: ParsedFrame) {
        switch frame.cmd {
        case 0x01:
            self.heartRate = BLEProtocolParser.shared.parseHeartRateResponse(frame)
            print("[BLE] 💓 心率: \(self.heartRate ?? 0) bpm")
        case 0x02:
            self.bloodOxygen = BLEProtocolParser.shared.parseBloodOxygenResponse(frame)
            print("[BLE] 🩸 血氧: \(self.bloodOxygen ?? 0)%")
        case 0x03:
            self.stepCount = BLEProtocolParser.shared.parseStepCountResponse(frame)
            print("[BLE] 🚶 步数: \(self.stepCount ?? 0) 步")
        case 0x04:
            self.batteryVoltage = BLEProtocolParser.shared.parseBatteryLevelResponse(frame)
        case 0x05:
            self.firmwareVersion = BLEProtocolParser.shared.parseFirmwareVersionResponse(frame)
            let v = self.firmwareVersion ?? 0
            print("[BLE] 📦 固件版本: v\(v / 10).\(v % 10)")
        case 0x06:
            self.serialNumber = BLEProtocolParser.shared.parseSerialNumberResponse(frame)
            print("[BLE] 🔢 序列号: \(self.serialNumber ?? "无")")
        case 0x07:
            handleHeartRateHistoryFrame(frame)
        case 0x08:
            handleBloodOxygenHistoryFrame(frame)
        case 0x09:
            handleStepCountHistoryFrame(frame)
        case 0x0A:
            self.healthThresholds = BLEProtocolParser.shared.parseHealthAnomalyThresholdsResponse(frame)
            if let t = self.healthThresholds {
                print("[BLE] ⚙️ 健康阈值: 心率[\(t.heartRateLow)-\(t.heartRateHigh)] 血氧[\(t.bloodOxygenLow)]")
            }
        case 0x0B:
            self.productModel = BLEProtocolParser.shared.parseProductModelResponse(frame)
            print("[BLE] 🏷️ 产品型号: \(self.productModel ?? 0)")
        case 0x30:
            handleLightParamsResponse(frame)
        case 0x80:
            handleAlarm(frame)
        default:
            print("[BLE] ❓ 未处理的返回帧 CMD=0x\(String(format: "%02X", frame.cmd))")
            break
        }
    }

    private func handleHeartRateHistoryFrame(_ frame: ParsedFrame) {
        // 保存原始数据
        let rawDataHex = BLEProtocolParser.shared.bytesToHexString(Data(frame.data))
        self.heartRateHistoryRawData.append(rawDataHex)
        
        if let result = BLEProtocolParser.shared.parseHeartRateHistoryResponse(frame) {
            for dayData in result {
                let dayHistory = DayHistoryData(
                    date: dayData.date,
                    hourlyValues: dayData.hourlyData.map { $0.value }
                )
                self.heartRateHistory.append(dayHistory)
                
                // 打印有数据的小时
                let nonZeroHours = dayData.hourlyData.filter { $0.value > 0 }
                if !nonZeroHours.isEmpty {
                    let hoursStr = nonZeroHours.map { "\($0.hour)时:\($0.value)bpm" }.joined(separator: ", ")
                    print("[BLE] 📊 心率历史 \(dayData.date): \(hoursStr)")
                } else {
                    print("[BLE] 📊 心率历史 \(dayData.date): 全天无数据")
                }
            }
            print("[BLE] 📊 心率历史共\(self.heartRateHistory.count)天")
        }
    }

    private func handleBloodOxygenHistoryFrame(_ frame: ParsedFrame) {
        // 保存原始数据
        let rawDataHex = BLEProtocolParser.shared.bytesToHexString(Data(frame.data))
        self.bloodOxygenHistoryRawData.append(rawDataHex)
        
        if let result = BLEProtocolParser.shared.parseBloodOxygenHistoryResponse(frame) {
            for dayData in result {
                let dayHistory = DayHistoryData(
                    date: dayData.date,
                    hourlyValues: dayData.hourlyData.map { $0.value }
                )
                self.bloodOxygenHistory.append(dayHistory)
                
                // 打印有数据的小时
                let nonZeroHours = dayData.hourlyData.filter { $0.value > 0 }
                if !nonZeroHours.isEmpty {
                    let hoursStr = nonZeroHours.map { "\($0.hour)时:\($0.value)%" }.joined(separator: ", ")
                    print("[BLE] 📊 血氧历史 \(dayData.date): \(hoursStr)")
                } else {
                    print("[BLE] 📊 血氧历史 \(dayData.date): 全天无数据")
                }
            }
            print("[BLE] 📊 血氧历史共\(self.bloodOxygenHistory.count)天")
        }
    }

    private func handleStepCountHistoryFrame(_ frame: ParsedFrame) {
        // 保存原始数据
        let rawDataHex = BLEProtocolParser.shared.bytesToHexString(Data(frame.data))
        self.stepCountHistoryRawData.append(rawDataHex)
        
        if let result = BLEProtocolParser.shared.parseStepCountHistoryResponse(frame) {
            let record = HistoryRecord(
                year: Int(result.time.year), month: Int(result.time.month), day: Int(result.time.day),
                hour: Int(result.time.hour), minute: Int(result.time.minute),
                value: result.steps
            )
            self.stepCountHistory.append(record)
            print("[BLE] 📊 步数历史: \(result.time.dateString) = \(result.steps) 步 (共\(self.stepCountHistory.count)条)")
        }
    }

    private func handleLightParamsResponse(_ frame: ParsedFrame) {
        if let lightParams = BLEProtocolParser.shared.parseLightParamsResponse(frame) {
            self.lightSlot = lightParams.slot
            self.lightRed = lightParams.r
            self.lightGreen = lightParams.g
            self.lightBlue = lightParams.b
            self.lightCurrentSlot = lightParams.currentSlot
            self.lightBrightness = lightParams.brightness
            self.lightBreathing = lightParams.breathing

            // 更新对应灯光槽的RGB值和亮度
            switch lightParams.slot {
            case 0:
                self.slot0R = lightParams.r
                self.slot0G = lightParams.g
                self.slot0B = lightParams.b
                self.slot0Brightness = lightParams.brightness
            case 1:
                self.slot1R = lightParams.r
                self.slot1G = lightParams.g
                self.slot1B = lightParams.b
                self.slot1Brightness = lightParams.brightness
            case 2:
                self.slot2R = lightParams.r
                self.slot2G = lightParams.g
                self.slot2B = lightParams.b
                self.slot2Brightness = lightParams.brightness
            default: break
            }

            print("[BLE] 💡 灯光参数: 槽=\(lightParams.slot) 当前槽=\(lightParams.currentSlot) RGB=(\(lightParams.r),\(lightParams.g),\(lightParams.b)) 亮度=\(lightParams.brightness) 呼吸=\(lightParams.breathing)")
        }
    }

    /// 请求所有灯光槽参数
    func requestAllLightSlotParams() {
        requestLightParams(slot: 0x00)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.requestLightParams(slot: 0x01) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.requestLightParams(slot: 0x02) }
    }

    private func handleAckFrame(_ frame: ParsedFrame) {
        self.lastAckCmd = frame.originalCmd
        self.lastAckStatus = frame.status
        let cmdName = cmdNameForLog(frame.originalCmd ?? 0)
        let statusStr = frame.status == 0x01 ? "✅成功" : "❌失败"
        print("[BLE] 📤 ACK: \(cmdName) \(statusStr)")
    }

    private func cmdNameForLog(_ cmd: UInt8) -> String {
        switch cmd {
        case 0x11: return "读取心率"
        case 0x12: return "读取血氧"
        case 0x13: return "读取步数"
        case 0x14: return "读取电量"
        case 0x15: return "读取固件版本"
        case 0x16: return "读取序列号"
        case 0x17: return "读取心率历史"
        case 0x18: return "读取血氧历史"
        case 0x19: return "读取步数历史"
        case 0x1B: return "读取产品型号"
        case 0x21: return "设置灯光颜色"
        case 0x22: return "设置灯光亮度"
        case 0x23: return "设置呼吸灯"
        case 0x24: return "切换灯光槽"
        case 0x25: return "设置心率低阈值"
        case 0x26: return "设置心率高阈值"
        case 0x27: return "设置血氧低阈值"
        case 0x28: return "读取健康阈值"
        case 0x30: return "读取灯光参数"
        case 0x40: return "进入OTA模式"
        case 0x90: return "OTA开始"
        case 0x91: return "OTA数据包"
        case 0x92: return "OTA结束"
        default: return "CMD=0x\(String(format: "%02X", cmd))"
        }
    }

    // MARK: - 告警处理

    private func handleAlarm(_ frame: ParsedFrame) {
        guard let alarm = BLEProtocolParser.shared.parseAlarmResponse(frame) else { return }
        self.currentAlarm = alarm

        switch alarm.alarmCode {
        case 0x02:
            self.alarmMessage = "设备电量低：\(alarm.paramA)%"
        case 0x11:
            // 心率过低告警，使用app中存储的阈值
            if let thresholds = self.healthThresholds {
                self.alarmMessage = "心率过低：\(alarm.paramA) bpm（阈值：\(thresholds.heartRateLow) bpm）"
            } else {
                self.alarmMessage = "心率过低：\(alarm.paramA) bpm"
            }
        case 0x12:
            // 心率过高告警，使用app中存储的阈值
            if let thresholds = self.healthThresholds {
                self.alarmMessage = "心率过高：\(alarm.paramA) bpm（阈值：\(thresholds.heartRateHigh) bpm）"
            } else {
                self.alarmMessage = "心率过高：\(alarm.paramA) bpm"
            }
        case 0x21:
            // 血氧过低告警，使用app中存储的阈值
            if let thresholds = self.healthThresholds {
                self.alarmMessage = "血氧过低：\(alarm.paramA)%（阈值：\(thresholds.bloodOxygenLow)%）"
            } else {
                self.alarmMessage = "血氧过低：\(alarm.paramA)%"
            }
        case 0x22:
            self.alarmMessage = "血氧无效：\(alarm.paramA)%（超过100%）"
        default:
            self.alarmMessage = "设备告警：代码=\(alarm.alarmCode)"
        }
        print("[BLE] 🚨 告警: \(self.alarmMessage ?? "未知")")
        self.showAlarm = true
    }

    // MARK: - 向 FFE3 写入数据包

    /// 向 FFE3 写入数据包
    /// - Parameters:
    ///   - data: 要写入的原始字节
    ///   - preferWithoutResponse: 若特征支持无应答写，是否优先使用（默认 true）
    func writeToFFE3(_ data: Data, preferWithoutResponse: Bool = true) {
        DispatchQueue.main.async {
               // 1. 取一个已连接的设备（假设你只关心第一个）
               guard let p = self.connectedDevices.first?.peripheral,
                     let c = self.writeChar else {
                   print("写入失败：没有已连接设备或未找到 FFE3 特征")
                   return
               }

               // 2. 判断写入类型
               var writeType: CBCharacteristicWriteType = .withResponse
               if preferWithoutResponse && c.properties.contains(.writeWithoutResponse) {
                   writeType = .withoutResponse
               } else if c.properties.contains(.write) {
                   writeType = .withResponse
               } else if c.properties.contains(.writeWithoutResponse) {
                   writeType = .withoutResponse
               } else {
                   print("FFE3 特征不支持写入")
                   return
               }

               // 3. 真正写入
               p.writeValue(data, for: c, type: writeType)

               // 可选：调试打印
               let hex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
               print("FFE3 <= \(hex)  [\(writeType == .withResponse ? "WR" : "WOR")]")
           }
    }

    // MARK: - 新协议命令发送方法 (v2.0 CMD模式)

    /// 通用命令发送方法
    /// - Parameters:
    ///   - cmd: 命令码
    ///   - data: 数据区字节数组
    func sendCommand(_ cmd: UInt8, data: [UInt8] = []) {
        let frame = BLECommandBuilder.buildWriteFrame(cmd: cmd, data: data)
        // 电量命令不打印日志（因为每5秒轮询一次，会刷屏）
        if cmd != 0x14 {
            let cmdName = cmdNameForLog(cmd)
            print("[BLE] 📤 发送: \(cmdName)")
        }
        writeToFFE3(frame)
    }

    // MARK: - 数据读取命令

    func requestHeartRate()       { sendCommand(0x11) }
    func requestBloodOxygen()      { sendCommand(0x12) }
    func requestStepCount()        { sendCommand(0x13) }
    func requestBatteryLevel()     { sendCommand(0x14) }
    func requestFirmwareVersion()  { sendCommand(0x15) }
    func requestSerialNumber()     { sendCommand(0x16) }

    func requestHeartRateHistory()    { heartRateHistory = []; heartRateHistoryRawData = []; sendCommand(0x17) }
    func requestBloodOxygenHistory()  { bloodOxygenHistory = []; bloodOxygenHistoryRawData = []; sendCommand(0x18) }
    func requestStepCountHistory()    { stepCountHistory = []; stepCountHistoryRawData = []; sendCommand(0x19) }

    // MARK: - 灯光控制命令

    func setLightColor(slot: UInt8, r: UInt8, g: UInt8, b: UInt8) {
        sendCommand(0x21, data: [slot, r, g, b])
    }

    func setLightBrightness(slot: UInt8, brightness: UInt16) {
        let brH = UInt8(brightness >> 8)
        let brL = UInt8(brightness & 0xFF)
        sendCommand(0x22, data: [slot, brH, brL])
    }

    func setBreathingLight(enabled: Bool) {
        sendCommand(0x23, data: [enabled ? 0x01 : 0x00])
    }

    func switchLightSlot(slot: UInt8) {
        sendCommand(0x24, data: [slot])
        // 立即更新当前灯光槽（用于按钮高亮显示）
        lightCurrentSlot = slot
        // 切换灯光槽后，延迟获取对应灯光槽的参数
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.requestLightParams(slot: slot)
        }
    }

    func requestLightParams(slot: UInt8 = 0xFF) {
        sendCommand(0x30, data: [slot])
    }

    // MARK: - 产品信息命令

    func requestProductModel() { sendCommand(0x1B) }

    // MARK: - 健康阈值命令

    func requestHealthAnomalyThresholds() { sendCommand(0x28) }

    func setHeartRateLowThreshold(_ threshold: UInt8) {
        sendCommand(0x25, data: [threshold, 0x00, 0x00, 0x00, 0x00])
    }

    func setHeartRateHighThreshold(_ threshold: UInt8) {
        sendCommand(0x26, data: [threshold, 0x00, 0x00, 0x00, 0x00])
    }

    func setBloodOxygenLowThreshold(_ threshold: UInt8) {
        sendCommand(0x27, data: [threshold, 0x00, 0x00, 0x00, 0x00])
    }

    // MARK: - 批量读取

    func requestAllData() {
        requestHeartRate()
        requestBloodOxygen()
        requestStepCount()
        requestBatteryLevel()
        requestFirmwareVersion()
        requestLightParams()
    }

    /// 延迟批量读取（避免命令堆积）
    /// 连接时只获取设备信息，不获取心率血氧步数（需要用户手动触发）
    private func requestAllDataWithDelay() {
        requestBatteryLevel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.requestFirmwareVersion() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.requestLightParams() }
        // 请求三个灯光槽的颜色参数
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.requestAllLightSlotParams() }
        // 请求健康阈值
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { self.requestHealthAnomalyThresholds() }
    }

    // MARK: - 旧接口兼容

    /// 向 FFE3 写入RGB控制数据包 (兼容旧接口，内部转为新协议)
    /// - Parameters:
    ///   - red: 红色分量 (0-255)
    ///   - green: 绿色分量 (0-255)
    ///   - blue: 蓝色分量 (0-255)
    ///   - mode: 模式选择 (0-255)
    ///   - preferWithoutResponse: 若特征支持无应答写，是否优先使用（默认 true）
    func writeRGBControlToFFE3(red: UInt8, green: UInt8, blue: UInt8, mode: UInt8, brightness: UInt16, preferWithoutResponse: Bool = true) {
        let breathing = (mode == 2)
        setBreathingLight(enabled: breathing)
        setLightColor(slot: 0xFF, r: red, g: green, b: blue)
        setLightBrightness(slot: 0xFF, brightness: brightness)
        
        // 设置颜色后，延迟读取当前灯光槽参数（用于更新按钮颜色）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.requestLightParams(slot: 0xFF)
        }
    }

    // MARK: - 自动轮询定时器

    private func startPolling() {
        stopPolling()
        // 连接时先请求一次全量数据（带延迟避免命令堆积）
        requestAllDataWithDelay()
        // 启动轮询
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // 根据独立开关控制是否轮询
            if self.isHeartRatePolling {
                self.requestHeartRate()
            }
            if self.isBloodOxygenPolling {
                self.requestBloodOxygen()
            }
            if self.isStepCountPolling {
                self.requestStepCount()
            }
            // 电量一直轮询
            self.requestBatteryLevel()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - 轮询控制方法

    /// 切换心率轮询状态
    func toggleHeartRatePolling() {
        isHeartRatePolling.toggle()
        if isHeartRatePolling {
            requestHeartRate()
        }
    }

    /// 切换血氧轮询状态
    func toggleBloodOxygenPolling() {
        isBloodOxygenPolling.toggle()
        if isBloodOxygenPolling {
            requestBloodOxygen()
        }
    }

    /// 切换步数轮询状态
    func toggleStepCountPolling() {
        isStepCountPolling.toggle()
        if isStepCountPolling {
            requestStepCount()
        }
    }

    // MARK: - 健康数据存储方法

    /// 获取指定日期的健康数据
    /// - Parameter date: 查询日期
    /// - Returns: 该日期的健康数据列表
    func getHealthData(for date: Date) -> [BodyhealthData] {
        return healthDataStorage.getHealthData(for: date)
    }
    
    /// 获取指定日期的最新健康数据
    /// - Parameter date: 查询日期
    /// - Returns: 该日期最新的健康数据
    func getLatestHealthData(for date: Date) -> BodyhealthData? {
        return healthDataStorage.getLatestHealthData(for: date)
    }
    
    /// 获取最近几天的健康数据概要
    /// - Parameter days: 天数
    /// - Returns: 健康数据概要字典
    func getRecentHealthDataSummary(days: Int = 7) -> [String: BodyhealthData] {
        return healthDataStorage.getRecentHealthDataSummary(days: days)
    }
    
    /// 删除超过指定天数的旧健康数据
    /// - Parameter days: 保留天数
    func cleanupOldHealthData(keepDays days: Int = 30) {
        DispatchQueue.global(qos: .utility).async {
            let deletedCount = self.healthDataStorage.deleteOldHealthData(olderThan: days)
            if deletedCount > 0 {
                DispatchQueue.main.async {
                    print("已清理 \(deletedCount) 条旧健康数据")
                }
            }
        }
    }
    
    // MARK: - 存储策略管理
    
    /// 设置健康数据存储策略
    /// - Parameter strategy: 存储策略
    func setHealthDataStorageStrategy(_ strategy: HealthDataStorage.StorageStrategy) {
        healthDataStorage.setStorageStrategy(strategy)
    }
    
    /// 获取当前存储策略
    func getCurrentStorageStrategy() -> HealthDataStorage.StorageStrategy {
        return healthDataStorage.getCurrentStrategy()
    }
    
    /// 重置存储缓存（新设备连接时调用）
    func resetStorageCache() {
        healthDataStorage.resetCache()
        print("已重置健康数据存储缓存")
    }
}

// MARK: - 系统 CBCentralManagerDelegate
extension BLEViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // 这个回调在系统蓝牙状态真正就绪时会触发
        DispatchQueue.main.async {
            self.bluetoothState = central.state
            switch central.state {
            case .poweredOn:
                print("系统蓝牙已开启（来自 delegate 回调）")
            case .poweredOff:
                print("系统蓝牙已关闭")
            case .unauthorized:
                print("蓝牙权限未授权（检查 Info.plist 的 NSBluetoothAlwaysUsageDescription）")
            case .unsupported:
                print("此设备不支持蓝牙（模拟器/某些 Mac 环境会这样）")
            case .resetting:
                print("蓝牙正在重置")
            case .unknown:
                fallthrough
            @unknown default:
                print("蓝牙状态未知")
            }
        }
    }
}
