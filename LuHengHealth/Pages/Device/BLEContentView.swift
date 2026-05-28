//
//  BLEContentView.swift
//  LuHengHeath
//
//  Created by macios on 2025/9/4.
//
import SwiftUI
import CoreBluetooth

// MARK: - 蓝牙设备内容视图
struct BLEContentView: View {
    
    @EnvironmentObject var viewModel: BLEViewModel
    var body: some View {
        NavigationStack { // 提供导航能力（用于弹出详情页等）
            VStack(spacing: 0) { // 垂直布局，顶部放状态栏，中间放列表，底部放按钮
                // 1) 蓝牙状态栏
                StatusBar(state: viewModel.bluetoothState) // 传入当前蓝牙状态，内部决定展示的图标与文字

                // 2) 设备列表
                List {
                    // 已连接设备分区
                    if !viewModel.connectedDevices.isEmpty { // 若存在已连接设备，显示一个分组
                        Section("已连接") { // 分组标题"已连接"
                            ForEach(viewModel.connectedDevices) { dev in // 遍历所有已连接设备
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) { // 左侧名称与状态垂直排列
                                        Text(dev.name) // 设备名
                                            .font(.headline) // 标题样式
                                        Text("已连接") // 状态文字
                                            .font(.caption) // 小字
                                            .foregroundColor(.green) // 绿色强调已连接
                                    }
                                    Spacer() // 推动右侧按钮靠右
                                    Button("详情") { // 查看详情按钮
                                        viewModel.selectedDeviceForDetail = dev // 赋值触发 .sheet 弹出详情页
                                    }
                                    .buttonStyle(.bordered) // 边框按钮
                                    Button("断开") { // 断开按钮
                                        viewModel.disconnect(from: dev) // 调用断开逻辑
                                    }
                                    .buttonStyle(.borderedProminent) // 实心强调按钮
                                    .tint(.red) // 红色强调危险操作
                                }
                            }
                        }
                    }

                    // 附近设备分区（仅显示Jewel开头的设备）
                    Section("附近设备") {
                        if viewModel.jewelDevices.isEmpty { // 若暂无Jewel设备
                            HStack {
                                if viewModel.isScanning { // 扫描中显示菊花与提示
                                    ProgressView() // 小菊花
                                    Text("正在扫描Jewel设备…") // 扫描提示
                                        .foregroundColor(.secondary) // 次要颜色
                                } else {
                                    Text("暂无Jewel设备") // 静态空态提示
                                        .foregroundColor(.secondary) // 次要颜色
                                }
                                Spacer() // 占位让文本靠左
                            }
                        } else {
                            ForEach(viewModel.jewelDevices) { dev in // 仅遍历Jewel开头的设备
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) { // 左侧展示名与信号
                                        Text(dev.name) // 设备名
                                            .font(.headline) // 标题样式
                                        Text("RSSI: \(dev.rssi.intValue) dBm") // 信号强度数字
                                            .font(.caption) // 小字
                                            .foregroundColor(.secondary) // 次要颜色
                                    }
                                    Spacer() // 推右侧按钮
                                    // 根据设备的连接状态，动态切换按钮
                                    let isConnected = dev.connectionState == .connected
                                    if isConnected {
                                        Button("详情") {
                                            viewModel.selectedDeviceForDetail = dev
                                        }
                                        .buttonStyle(.bordered)
                                        Button("断开连接") {
                                            viewModel.disconnect(from: dev)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.red)
                                    } else {
                                        Button("连接") {
                                            viewModel.connect(to: dev)
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped) // iOS 风格的分组列表外观

                // 3) 底部扫描按钮
                Button {
                    if viewModel.isScanning { // 根据当前扫描状态切换行为
                        viewModel.stopScan() // 已在扫 → 停止
                    } else {
                        viewModel.startScan() // 未在扫 → 开始
                    }
                } label: {
                    HStack {
                        if viewModel.isScanning { // 扫描中样式
                            ProgressView() // 小菊花
                                .tint(.white) // 白色转圈
                            Text("停止扫描") // 文案
                        } else {
                            Image(systemName: "magnifyingglass") // 放大镜图标
                            Text("开始扫描") // 文案
                        }
                    }
                    .frame(maxWidth: .infinity) // 宽度铺满
                    .padding() // 内边距
                    .background(viewModel.isScanning ? .red : .blue) // 扫描中红色，未扫描蓝色
                    .foregroundColor(.white) // 文字白色
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // 圆角矩形外观
                    .padding(.horizontal) // 两侧留白
                    .padding(.bottom , 100) // 底部留白
                }
            }
            .navigationTitle("蓝牙设备") // 顶部导航标题
        }
        // 4) 详情页：展示 GATT 概览 & 最新十六进制数据
        .sheet(item: $viewModel.selectedDeviceForDetail) { dev in // 当 selectedDeviceForDetail 有值时弹出
            DeviceDetailViewMini(device: dev) // 传入设备与 VM
        }
    }
}

// MARK: - 顶部状态条
struct StatusBar: View {
    let state: CBManagerState // 接收外部传入的蓝牙状态

    var body: some View {
        HStack(spacing: 12) { // 横向排布图标与文字
            Image(systemName: icon) // 系统图标
                .foregroundColor(color) // 图标颜色与状态一致
                .font(.title2) // 图标大小
            VStack(alignment: .leading, spacing: 2) { // 竖向显示标题 + 副标题
                Text("蓝牙状态") // 标题
                    .font(.headline) // 标题样式
                Text(text) // 根据状态生成的说明文案
                    .font(.caption) // 小字
                    .foregroundColor(.secondary) // 次要颜色
            }
            Spacer() // 推到左侧
            Circle() // 右侧一个小圆点指示灯
                .fill(color) // 用状态色填充
                .frame(width: 10, height: 10) // 大小
        }
        .padding() // 内边距
        .background(Color(.systemGray6)) // 浅灰背景
    }

    // 根据状态映射图标
    private var icon: String {
        switch state {
        case .poweredOn: return "antenna.radiowaves.left.and.right" // 已开启，改用更通用图标避免报错
        case .poweredOff: return "bluetooth.slash" // 已关闭
        case .unauthorized: return "exclamationmark.triangle" // 权限问题
        case .unsupported: return "xmark.circle" // 不支持
        default: return "questionmark.circle" // 未知/初始化中
        }
    }
    // 根据状态映射颜色
    private var color: Color {
        switch state {
        case .poweredOn: return .blue // 开启→蓝色
        case .poweredOff: return .gray // 关闭→灰色
        case .unauthorized: return .orange // 权限→橙色
        case .unsupported: return .red // 不支持→红色
        default: return .gray // 其他→灰色
        }
    }
    // 根据状态映射说明文字
    private var text: String {
        switch state {
        case .poweredOn: return "已开启" // 说明
        case .poweredOff: return "已关闭" // 说明
        case .unauthorized: return "需要权限" // 说明
        case .unsupported: return "不支持" // 说明
        default: return "未知状态" // 说明
        }
    }
}

// MARK: - 详情页（极简版，显示 GATT 概览 & FFE4 十六进制）
struct DeviceDetailViewMini: View {
    let device: BluetoothDevice // 当前查看的设备
    @EnvironmentObject var viewModel: BLEViewModel
    
    // RGB控制相关状态
    @State private var red: UInt8 = 255
    @State private var green: UInt8 = 0
    @State private var blue: UInt8 = 0
    @State private var mode: UInt8 = 1 // 默认常亮模式
    @State private var brightness: UInt16 = 400 // 默认常亮模式
    
    var body: some View {
        NavigationStack { // 为详情页提供导航栏标题
            List {
                // 设备基本信息分区
                Section("设备") {
                    HStack {
                        Text("名称") // 左列标题
                        Spacer() // 推右侧
                        Text(device.name) // 设备名
                            .foregroundColor(.secondary) // 次要颜色
                    }
                    HStack {
                        Text("标识符") // 左列标题
                        Spacer() // 推右侧
                        Text(device.identifier.uuidString) // UUID 字符串
                            .foregroundColor(.secondary) // 次要颜色
                            .lineLimit(1) // 单行
                            .truncationMode(.middle) // 中间截断，便于观察前后缀
                    }
                }

                // GATT 概览分区（服务/特征/属性）
                Section("GATT 概览") {
                    ScrollView { // 避免文本太长撑高
                        Text(viewModel.gattSummaryText) // 直接显示由 ViewModel 生成的概览文本
                            .font(.system(.body, design: .monospaced)) // 等宽字体，阅读更整齐
                            .frame(maxWidth: .infinity, alignment: .leading) // 左对齐铺满
                            .textSelection(.enabled) // 支持长按复制
                    }
                    .frame(minHeight: 120) // 给一个最小高度
                }

                // FFE4 最新十六进制数据分区
                Section("FFE4 最新十六进制数据") {
                    Text(viewModel.ffe4HexText) // 直接显示 ViewModel 中的十六进制字符串
                        .font(.system(.body, design: .monospaced)) // 等宽显示更适合字节对齐
                        .frame(maxWidth: .infinity, alignment: .leading) // 左对齐
                        .textSelection(.enabled) // 允许复制
                }
                

                
                // 心率数据分区
                Section("心率数据") {
                    if let heartRate = viewModel.heartRate {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            Text("\(heartRate)")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.red)
                            Text("次/分钟")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("暂无心率数据")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // 血氧数据分区
                Section("血氧数据") {
                    if let bloodOxygen = viewModel.bloodOxygen {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                            Text("\(bloodOxygen)")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.blue)
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("暂无血氧数据")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // 电池电压分区
                Section("电池电压") {
                    if let batteryVoltage = viewModel.batteryVoltage {
                        HStack {
                            Image(systemName: "battery.100")
                                .foregroundColor(.green)
                                .font(.title)
                            Text("\(batteryVoltage)")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.green)
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("暂无电池电压数据")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 步数分区 (v1.2新增)
                Section("步数") {
                    if let stepCount = viewModel.stepCount {
                        HStack {
                            Image(systemName: "figure.walk")
                                .foregroundColor(.orange)
                                .font(.title)
                            Text("\(stepCount)")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.orange)
                            Text("步")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("暂无步数数据")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 固件版本号分区 (v1.2新增)
                Section("固件版本") {
                    if let firmwareVersion = viewModel.firmwareVersion {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title)
                            Text("\(firmwareVersion / 10).\(firmwareVersion % 10)")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.purple)
                            Text("v")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("暂无固件版本数据")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 序列号分区
                Section("序列号") {
                    if let sn = viewModel.serialNumber {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.teal)
                                .font(.title3)
                            Text(sn)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    } else {
                        Button("读取序列号") {
                            viewModel.requestSerialNumber()
                        }
                    }
                }

                // 灯光参数分区
                Section("灯光参数") {
                    HStack {
                        Circle()
                            .fill(Color(
                                red: Double(viewModel.lightRed) / 255,
                                green: Double(viewModel.lightGreen) / 255,
                                blue: Double(viewModel.lightBlue) / 255
                            ))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        Text("R:\(viewModel.lightRed) G:\(viewModel.lightGreen) B:\(viewModel.lightBlue)")
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        Text("亮度:\(viewModel.lightBrightness)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("呼吸灯")
                            .font(.subheadline)
                        Spacer()
                        Text(viewModel.lightBreathing ? "开启" : "关闭")
                            .font(.subheadline)
                            .foregroundColor(viewModel.lightBreathing ? .green : .secondary)
                    }
                    Button("刷新灯光参数") {
                        viewModel.requestLightParams()
                    }
                }
            }
            .navigationTitle("设备详情") // 导航标题
            .navigationBarTitleDisplayMode(.inline) // 标题紧凑显示
        }
        .onAppear {
            viewModel.requestAllData()
        }
        .alert("设备告警", isPresented: $viewModel.showAlarm) {
            Button("确认", role: .cancel) { }
        } message: {
            Text(viewModel.alarmMessage ?? "未知告警")
        }
    }
}
