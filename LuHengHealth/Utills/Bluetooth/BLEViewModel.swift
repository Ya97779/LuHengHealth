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
import WCHBLELibrary




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
                // 这里不立即写，提供公开方法供 UI/业务调用
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
        print("特征值更新: \(characteristic.uuid.uuidString)")
        DispatchQueue.main.async {
                guard error == nil,
                      let characteristic = characteristic,
                      let value = characteristic.value else { return }

                // 你的通用存档逻辑
                self.latestValueByCharacteristic[characteristic.uuid] = value
                self.valueLogByCharacteristic[characteristic.uuid, default: []].append(value)

                // 如果是我们关心的 FEE4：使用协议解析器解析数据
                if characteristic.uuid == self.notifyCharUUID {
                    // 使用协议解析器解析数据
                    let healthData = BLEProtocolParser.shared.parseFFE4Data(value)

                    // 更新UI显示数据
                    self.ffe4HexText = healthData.hexString.isEmpty ? "--" : healthData.hexString
                    self.heartRate = healthData.heartRate
                    self.bloodOxygen = healthData.bloodOxygen
                    self.batteryVoltage = healthData.batteryVoltage
                    self.stepCount = healthData.stepCount  // v1.2新增
                    self.firmwareVersion = healthData.firmwareVersion  // v1.2新增

                    // 打印调试信息
                    if healthData.isValid {
                        print("FFE4 解析成功: 心率=\(healthData.heartRate ?? 0), 血氧=\(healthData.bloodOxygen ?? 0), 电池电压=\(healthData.batteryVoltage ?? 0)%, 步数=\(healthData.stepCount ?? 0), 固件版本=\(healthData.firmwareVersion ?? 0)")
                        
                        // 保存有效的健康数据到数据库
                        self.saveHealthDataToDatabase(healthData)
                    }
                }
            }
    }
    
    /// 向 FFE3 写入RGB控制数据包
    /// - Parameters:
    ///   - red: 红色分量 (0-255)
    ///   - green: 绿色分量 (0-255)
    ///   - blue: 蓝色分量 (0-255)
    ///   - mode: 模式选择 (0-255)
    ///   - preferWithoutResponse: 若特征支持无应答写，是否优先使用（默认 true）
    func writeRGBControlToFFE3(red: UInt8, green: UInt8, blue: UInt8, mode: UInt8, brightness: UInt16 ,preferWithoutResponse: Bool = true) {
        // 构建数据包: 帧头0xAA 命令码0x0F 红色字节 绿色字节 蓝色字节 模式选择 亮度高8位 亮度低8位 帧尾0x55
        let brightnessHigh = UInt8(brightness >> 8)    // 亮度高8位
        let brightnessLow = UInt8(brightness & 0xFF)  // 亮度低8位
        let data = Data([0xAA, 0x0F, red, green, blue, mode, brightnessHigh, brightnessLow, 0x55])
        writeToFFE3(data, preferWithoutResponse: preferWithoutResponse)
    }
    
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
    
    // MARK: - 健康数据存储方法
    
    /// 将BLE读取的健康数据保存到数据库
    /// - Parameter healthData: 解析后的健康数据
    private func saveHealthDataToDatabase(_ healthData: BLEHealthData) {
        // 确保在后台线程进行数据库操作，避免阻塞UI
        DispatchQueue.global(qos: .utility).async {
            // 使用智能存储策略，避免频繁保存相似数据
            let success = self.healthDataStorage.saveHealthData(
                heartRate: healthData.heartRate,
                bloodOxygen: healthData.bloodOxygen,
                timestamp: Date(),
                strategy: .smart // 使用智能策略
            )
            
            if success {
                DispatchQueue.main.async {
                    print("健康数据已保存到数据库（智能策略）")
                    // 可以在这里发送通知给UI更新
                    NotificationCenter.default.post(
                        name: NSNotification.Name("HealthDataSaved"),
                        object: healthData
                    )
                }
            }
        }
    }
    
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
