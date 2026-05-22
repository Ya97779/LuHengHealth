# 蓝牙通信协议升级实施计划

> 从 v1.2（固定17字节推送）升级到最新协议（CMD请求-响应 + ACK模式）

---

## 一、新旧协议核心差异

### 1.1 帧格式对比

| 项目 | 旧协议 (v1.2) | 新协议 |
|------|--------------|--------|
| 帧格式 | 固定 17 字节 | 可变长度，带 LEN / CMD / CHECK |
| 数据获取方式 | 设备一次性推送所有数据 | 手机主动发命令 → 设备返回对应数据 |
| 帧头区分 | 统一 `AA 55 ... 55 AA` | 写入 `AA 55` / 返回 `AA 56` / ACK `AA 57` |
| 校验和 | 无 | 有（帧头到数据区累加和取低8位） |
| 写入格式 | `AA 0F RR GG BB MODE BH BL 55` | `AA 55 LEN CMD DATA[LEN] CHECK 55 AA` |

### 1.2 帧类型定义

```
写入帧 (手机→设备):  AA 55  LEN  CMD  DATA[LEN]  CHECK  55 AA
返回帧 (设备→手机):  AA 56  LEN  CMD  DATA[LEN]  CHECK  56 AA
ACK帧  (设备→手机):  AA 57  05   7F   原CMD STATUS 00 00 00  CHECK  57 AA
```

### 1.3 功能模块对比

| 功能模块 | 旧协议 | 新协议 | 变更说明 |
|---------|--------|--------|---------|
| 心率 | ✅ 一帧包含 | ✅ CMD 0x11 请求 → 0x01 返回 | 改为请求-响应 |
| 血氧 | ✅ 一帧包含 | ✅ CMD 0x12 请求 → 0x02 返回 | 改为请求-响应 |
| 步数 | ✅ 一帧包含 | ✅ CMD 0x13 请求 → 0x03 返回 | 改为请求-响应 |
| 电量 | ✅ 一帧包含 | ✅ CMD 0x14 请求 → 0x04 返回 | 改为请求-响应 |
| 固件版本 | ✅ 一帧包含 | ✅ CMD 0x15 请求 → 0x05 返回 | 改为请求-响应 |
| 灯光控制 | ❌ 旧格式 `AA 0F...` | ✅ CMD 0x21/0x22/0x23/0x24 | 完全重写 |
| 灯光参数回读 | ❌ 无 | ✅ CMD 0x30 请求 → 0x30/0x31 返回 | 新增 |
| 告警系统 | ❌ 无 | ✅ CMD 0x80 设备主动上报 | 新增 |
| 序列号 | ❌ 无 | ✅ CMD 0x16 请求 → 0x06 返回 | 新增 |
| 历史数据 | ❌ 无 | ✅ CMD 0x17/0x18/0x19 | 新增 |
| OTA升级 | ❌ 无 | ✅ CMD 0x40/0x90/0x91/0x92 | 新增 |

---

## 二、受影响文件清单

| 文件 | 影响程度 | 改动范围 |
|------|---------|---------|
| `BLEProtocolParser.swift` | 🔴 完全重写 | 帧解析逻辑、校验和、CMD分发 |
| `BLEViewModel.swift` | 🔴 大幅修改 | 命令发送、数据接收分发、告警处理、灯光控制 |
| `BLEContentView.swift` | 🟡 中等修改 | 设备详情页：添加告警提示、序列号显示 |
| `DevicePage.swift` | 🟡 中等修改 | 设备信息卡片：适配新数据字段 |
| `HomePage.swift` | 🟡 中等修改 | 灯光控制：适配新写入格式 |
| `BLE_PROTOCOL.md` | 🔴 完全重写 | 协议文档更新 |
| 新增 `BLECommandBuilder.swift` | 🟢 新建 | 命令构建工具类 |
| 新增 `LightControlView.swift` | 🟢 新建 | 灯光控制独立页面（可选） |

---

## 三、分步实施计划

### 阶段一：协议解析层重写

#### 步骤 1.1：新建 `BLECommandBuilder.swift` — 命令构建工具

**文件**: `/LuHengHealth/Utills/Bluetooth/BLECommandBuilder.swift`

**职责**: 封装所有"手机→设备"的写入命令构建

**核心内容**:
```
class BLECommandBuilder {
    // 校验和计算: 帧头到数据区所有字节累加和取低8位
    static func calculateChecksum(_ bytes: [UInt8]) -> UInt8

    // 通用写入帧构建: AA 55 LEN CMD DATA[LEN] CHECK 55 AA
    static func buildWriteFrame(cmd: UInt8, data: [UInt8]) -> Data

    // --- 心率/血氧/步数/电量/版本/序列号 读取命令 ---
    static func readHeartRate() -> Data          // CMD 0x11
    static func readBloodOxygen() -> Data        // CMD 0x12
    static func readStepCount() -> Data          // CMD 0x13
    static func readBatteryLevel() -> Data       // CMD 0x14
    static func readFirmwareVersion() -> Data    // CMD 0x15
    static func readSerialNumber() -> Data       // CMD 0x16

    // --- 灯光控制命令 ---
    static func setLightSlotColor(slot: UInt8, r: UInt8, g: UInt8, b: UInt8) -> Data  // CMD 0x21
    static func setLightSlotBrightness(slot: UInt8, brightness: UInt16) -> Data       // CMD 0x22
    static func setBreathingLight(enabled: Bool) -> Data                              // CMD 0x23
    static func switchLightSlot(slot: UInt8) -> Data                                  // CMD 0x24

    // --- 灯光参数读取 ---
    static func readLightParams(slot: UInt8) -> Data  // CMD 0x30

    // --- 历史数据读取 ---
    static func readHeartRateHistory() -> Data    // CMD 0x17
    static func readBloodOxygenHistory() -> Data  // CMD 0x18
    static func readStepCountHistory() -> Data    // CMD 0x19

    // --- 测试命令 ---
    static func writeFakeHistoryData() -> Data    // CMD 0x1A

    // --- OTA 命令 ---
    static func enterOTAMode() -> Data            // CMD 0x40
    static func buildOTAStartFrame(firmwareSize: UInt32, checksum: UInt16) -> Data  // CMD 0x90
    static func buildOTADataPacket(seq: UInt16, data: Data) -> Data                // CMD 0x91
    static func buildOTAEndFrame(firmwareSize: UInt32, checksum: UInt16) -> Data   // CMD 0x92
}
```

**验证方式**: 单元测试对比每个命令输出的字节序列是否与协议文档一致

---

#### 步骤 1.2：重写 `BLEProtocolParser.swift` — 帧解析器

**文件**: `/LuHengHealth/Utills/Bluetooth/BLEProtocolParser.swift`

**改动要点**:

1. **删除旧的固定位置索引解析逻辑**（heartRateIndex, bloodOxygenIndex 等全部删除）

2. **新增三种帧类型识别**:
   - 返回帧: `AA 56 LEN CMD DATA[LEN] CHECK 56 AA`
   - ACK帧: `AA 57 05 7F 原CMD STATUS 00 00 00 CHECK 57 AA`
   - OTA ACK: `A5 CMD STATUS SEQ_H SEQ_L PROGRESS ERR 5A`（独立帧格式）

3. **新增数据结构**:
   ```swift
   enum FrameType {
       case responseFrame    // AA 56 返回帧
       case ackFrame         // AA 57 ACK帧
       case otaAck           // A5 OTA应答
       case unknown
   }

   struct ParsedFrame {
       let type: FrameType
       let cmd: UInt8
       let data: [UInt8]
       let isValid: Bool
       let originalCmd: UInt8?   // ACK帧中: 被应答的原CMD
       let status: UInt8?        // ACK帧中: 01成功/02失败
   }

   // 告警数据
   struct AlarmData {
       let alarmCode: UInt8
       let paramA: UInt8
       let paramB: UInt8
       let paramC: UInt8
   }

   // 历史记录
   struct HistoryTimeFrame {
       let year: UInt8, month: UInt8, day: UInt8, hour: UInt8, minute: UInt8
   }

   struct LightColorFrame {
       let slot: UInt8, r: UInt8, g: UInt8, b: UInt8, currentSlot: UInt8
   }

   struct LightBrightnessFrame {
       let slot: UInt8, brightness: UInt16, breathing: Bool, direction: UInt8
   }
   ```

4. **核心解析方法**:
   ```swift
   func parse(_ data: Data) -> ParsedFrame
   private func validateChecksum(_ data: Data, footerIndex: Int) -> Bool
   private func identifyFrameType(_ data: Data) -> FrameType
   ```

5. **CMD 分发解析方法**:
   ```swift
   // 解析返回帧数据区
   func parseHeartRateResponse(_ frame: ParsedFrame) -> Int?
   func parseBloodOxygenResponse(_ frame: ParsedFrame) -> Int?
   func parseStepCountResponse(_ frame: ParsedFrame) -> Int?
   func parseBatteryLevelResponse(_ frame: ParsedFrame) -> Int?
   func parseFirmwareVersionResponse(_ frame: ParsedFrame) -> Int?
   func parseSerialNumberResponse(frames: [ParsedFrame]) -> String?
   func parseAlarmResponse(_ frame: ParsedFrame) -> AlarmData?
   func parseLightColorResponse(_ frame: ParsedFrame) -> LightColorFrame?
   func parseLightBrightnessResponse(_ frame: ParsedFrame) -> LightBrightnessFrame?
   func parseHistoryTimeResponse(_ frame: ParsedFrame) -> HistoryTimeFrame?
   func parseHistoryDataResponse(_ frame: ParsedFrame, cmd: UInt8) -> (min: Int, max: Int)?
   ```

**验证方式**: 准备各CMD的示例字节数据，验证解析结果正确

---

### 阶段二：ViewModel 核心逻辑升级

#### 步骤 2.1：修改 `BLEViewModel.swift` — 发布属性

**新增 @Published 属性**:
```swift
// 序列号
@Published var serialNumber: String? = nil

// 告警
@Published var currentAlarm: AlarmData? = nil
@Published var alarmMessage: String? = nil
@Published var showAlarm: Bool = false

// 灯光参数回读
@Published var lightSlot: UInt8 = 0              // 当前灯光槽 (0/1/2)
@Published var lightRed: UInt8 = 0
@Published var lightGreen: UInt8 = 0
@Published var lightBlue: UInt8 = 0
@Published var lightBrightness: UInt16 = 0
@Published var lightBreathing: Bool = false

// 历史数据
@Published var heartRateHistory: HistoryRecord?
@Published var bloodOxygenHistory: HistoryRecord?
@Published var stepCountHistory: HistoryRecord?

// ACK状态
@Published var lastAckCmd: UInt8? = nil
@Published var lastAckStatus: UInt8? = nil
```

**新增辅助结构体**:
```swift
struct HistoryRecord {
    let year: Int, month: Int, day: Int, hour: Int, minute: Int
    let minValue: Int, maxValue: Int
}
```

---

#### 步骤 2.2：修改 `BLEViewModel.swift` — 命令发送方法

**改造写入方法**:

旧代码 (`writeRGBControlToFFE3`) 使用旧格式 `AA 0F RR GG BB MODE BH BL 55`，需要替换为新协议格式。

```swift
// 读取命令（通过 FFE3 写入到设备）
func sendCommand(_ cmd: UInt8, data: [UInt8] = []) {
    let frame = BLECommandBuilder.buildWriteFrame(cmd: cmd, data: data)
    writeToFFE3(frame)
}

// 快捷方法
func requestHeartRate()    { sendCommand(0x11) }
func requestBloodOxygen()  { sendCommand(0x12) }
func requestStepCount()    { sendCommand(0x13) }
func requestBatteryLevel() { sendCommand(0x14) }
func requestFirmwareVersion() { sendCommand(0x15) }
func requestSerialNumber() { sendCommand(0x16) }
func requestLightParams(slot: UInt8 = 0xFF) { sendCommand(0x30, data: [slot]) }

// 灯光控制（新格式）
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
}

// 批量读取所有数据（连接后调用）
func requestAllData() {
    requestHeartRate()
    requestBloodOxygen()
    requestStepCount()
    requestBatteryLevel()
    requestFirmwareVersion()
    requestLightParams()
}
```

**重要**: 旧的 `writeRGBControlToFFE3` 方法需要保留并改为转发到新格式，或者标记为废弃。HomePage.swift 中调用了此方法。

---

#### 步骤 2.3：修改 `BLEViewModel.swift` — 数据接收分发

**改造 `bleManagerUpdateValue` 方法**:

旧逻辑：直接从固定位置提取心率/血氧/步数等。
新逻辑：先识别帧类型，再根据 CMD 分发到对应解析方法。

```swift
func bleManagerUpdateValue(...) {
    guard error == nil, let characteristic = characteristic, let value = characteristic.value else { return }

    // 通用缓存
    self.latestValueByCharacteristic[characteristic.uuid] = value
    self.valueLogByCharacteristic[characteristic.uuid, default: []].append(value)

    // FFE4 通知数据
    if characteristic.uuid == self.notifyCharUUID {
        let frame = BLEProtocolParser.shared.parse(value)
        self.ffe4HexText = BLEProtocolParser.shared.bytesToHexString(value)

        guard frame.isValid else { return }

        switch frame.type {
        case .responseFrame:
            handleResponseFrame(frame)
        case .ackFrame:
            handleAckFrame(frame)
        case .otaAck:
            handleOtaAck(frame)
        case .unknown:
            break
        }
    }
}

private func handleResponseFrame(_ frame: ParsedFrame) {
    switch frame.cmd {
    case 0x01:  // 心率
        self.heartRate = BLEProtocolParser.shared.parseHeartRateResponse(frame)
    case 0x02:  // 血氧
        self.bloodOxygen = BLEProtocolParser.shared.parseBloodOxygenResponse(frame)
    case 0x03:  // 步数
        self.stepCount = BLEProtocolParser.shared.parseStepCountResponse(frame)
    case 0x04:  // 电量百分比
        self.batteryVoltage = BLEProtocolParser.shared.parseBatteryLevelResponse(frame)
    case 0x05:  // 固件版本
        self.firmwareVersion = BLEProtocolParser.shared.parseFirmwareVersionResponse(frame)
    case 0x06:  // 序列号（两帧）
        handleSerialNumberFrame(frame)
    case 0x07:  // 心率历史（两帧）
        handleHeartRateHistoryFrame(frame)
    case 0x08:  // 血氧历史（两帧）
        handleBloodOxygenHistoryFrame(frame)
    case 0x09:  // 步数历史（两帧）
        handleStepCountHistoryFrame(frame)
    case 0x30:  // 灯光颜色参数
        handleLightColorResponse(frame)
    case 0x31:  // 灯光亮度参数
        handleLightBrightnessResponse(frame)
    case 0x80:  // 异常告警
        handleAlarm(frame)
    default:
        break
    }
}

private func handleAckFrame(_ frame: ParsedFrame) {
    self.lastAckCmd = frame.originalCmd
    self.lastAckStatus = frame.status
    // 可根据 ACK 状态弹出提示
}
```

---

#### 步骤 2.4：修改 `BLEViewModel.swift` — 自动轮询定时器

新协议下设备不会主动推送数据，需要手机定时请求。添加定时轮询机制：

```swift
private var pollingTimer: Timer?
private let pollingInterval: TimeInterval = 3.0  // 每3秒轮询一次

private func startPolling() {
    stopPolling()
    pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
        self?.requestHeartRate()
        self?.requestBloodOxygen()
        self?.requestStepCount()
        self?.requestBatteryLevel()
    }
    // 立即请求一次
    requestAllData()
}

private func stopPolling() {
    pollingTimer?.invalidate()
    pollingTimer = nil
}
```

**调用时机**:
- 连接成功 + 发现特征后 → `startPolling()`
- 断开连接时 → `stopPolling()`

---

#### 步骤 2.5：修改 `BLEViewModel.swift` — 告警处理

```swift
private func handleAlarm(_ frame: ParsedFrame) {
    guard let alarm = BLEProtocolParser.shared.parseAlarmResponse(frame) else { return }
    self.currentAlarm = alarm

    switch alarm.alarmCode {
    case 0x02:  // 低电量
        self.alarmMessage = "设备电量低：\(alarm.paramA)%"
    case 0x11:  // 心率过低
        self.alarmMessage = "心率过低：\(alarm.paramA) bpm（低于 \(alarm.paramB)）"
    case 0x12:  // 心率过高
        self.alarmMessage = "心率过高：\(alarm.paramA) bpm（高于 \(alarm.paramB)）"
    case 0x21:  // 血氧过低
        self.alarmMessage = "血氧过低：\(alarm.paramA)%（低于 \(alarm.paramB)%）"
    case 0x22:  // 血氧无效
        self.alarmMessage = "血氧无效：\(alarm.paramA)%（超过100%）"
    default:
        self.alarmMessage = "设备告警：代码=\(alarm.alarmCode)"
    }
    self.showAlarm = true
}
```

---

### 阶段三：写入格式适配

#### 步骤 3.1：修改 `HomePage.swift` — 灯光控制适配

**当前代码** (约 line 351):
```swift
viewModel.writeRGBControlToFFE3(
    red: rgb.red, green: rgb.green, blue: rgb.blue,
    mode: snap.mode, brightness: brightnessUInt16
)
```

**需要改为**:
```swift
// 根据 mode 决定是否呼吸
if snap.mode == 2 {
    viewModel.setBreathingLight(enabled: true)
}
// 设置颜色到当前灯光槽 (0xFF = 当前槽)
viewModel.setLightColor(slot: 0xFF, r: rgb.red, g: rgb.green, b: rgb.blue)
// 设置亮度
viewModel.setLightBrightness(slot: 0xFF, brightness: brightnessUInt16)
```

**注意**: 需要根据实际产品交互设计决定是分两条命令发送还是合并。新协议中颜色和亮度是分开的命令（CMD 0x21 和 CMD 0x22），不像旧协议一帧包含所有。

**两种方案**:
- **方案A**: 拆成两条命令依次发送（颜色 + 亮度），简单但增加通信次数
- **方案B**: 维持旧的 `writeRGBControlToFFE3` 方法但内部转为两条命令，对外接口不变

**建议**: 采用方案B，保持 HomePage 调用代码改动最小化。

---

#### 步骤 3.2：修改 `BLEViewModel.swift` — 旧灯光控制方法兼容

```swift
// 保留旧方法签名，内部改为新协议格式
func writeRGBControlToFFE3(red: UInt8, green: UInt8, blue: UInt8,
                            mode: UInt8, brightness: UInt16,
                            preferWithoutResponse: Bool = true) {
    // 呼吸灯控制
    let breathing = (mode == 2)
    setBreathingLight(enabled: breathing)
    // 设置颜色 (0xFF = 当前灯光槽)
    setLightColor(slot: 0xFF, r: red, g: green, b: blue)
    // 设置亮度
    setLightBrightness(slot: 0xFF, brightness: brightness)
}
```

---

### 阶段四：前端页面适配

#### 步骤 4.1：修改 `BLEContentView.swift` — 设备详情页

**新增 Section**:

```swift
// 序列号
Section("序列号") {
    if let sn = viewModel.serialNumber {
        Text(sn).font(.system(.body, design: .monospaced))
    } else {
        Button("读取序列号") { viewModel.requestSerialNumber() }
    }
}

// 告警信息
if viewModel.showAlarm, let msg = viewModel.alarmMessage {
    Section("⚠️ 告警") {
        Text(msg).foregroundColor(.red)
        Button("关闭") { viewModel.showAlarm = false }
    }
}

// 灯光参数回读
Section("灯光参数") {
    HStack {
        Circle().fill(Color(red: Double(viewModel.lightRed)/255,
                            green: Double(viewModel.lightGreen)/255,
                            blue: Double(viewModel.lightBlue)/255))
            .frame(width: 30, height: 30)
        Text("R:\(viewModel.lightRed) G:\(viewModel.lightGreen) B:\(viewModel.lightBlue)")
        Spacer()
        Text("亮度:\(viewModel.lightBrightness)")
    }
    Button("刷新灯光参数") { viewModel.requestLightParams() }
}
```

---

#### 步骤 4.2：修改 `BLEContentView.swift` — 连接后自动请求数据

在设备详情页的 `onAppear` 中触发数据请求：

```swift
.onAppear {
    viewModel.requestAllData()
}
```

---

#### 步骤 4.3：修改 `DevicePage.swift` — 设备信息卡片

适配新字段显示（序列号等）。电量显示逻辑可能需要调整：
- 旧：`batteryVoltage` 是百分比（由原始电压转换）
- 新：设备直接返回百分比（0~100），无需转换

---

#### 步骤 4.4：修改 `HomePage.swift` — 灯光控制适配

见步骤 3.1，核心改动在 `sendSnapshotImmediately` 方法。

---

### 阶段五：文档更新

#### 步骤 5.1：更新 `BLE_PROTOCOL.md`

完全重写，覆盖新协议的全部内容：
- 三种帧格式说明
- 所有 CMD 速查表
- 灯光控制命令详解
- 告警码说明
- OTA 升级流程
- 代码示例

---

#### 步骤 5.2：更新 `README.md`

更新项目说明中的协议版本和功能列表。

---

### 阶段六（可选）：OTA 升级功能

#### 步骤 6.1：新建 `BLEOTAService.swift`

**文件**: `/LuHengHealth/Utills/Bluetooth/BLEOTAService.swift`

**职责**: 封装 OTA 升级流程

**核心内容**:
```swift
class BLEOTAService {
    enum OTAState {
        case idle, requesting, transferring, verifying, complete, failed
    }

    @Published var state: OTAState = .idle
    @Published var progress: Int = 0  // 0~100

    func startOTA(firmwareData: Data, writeHandler: (Data) -> Void)
    // 内部流程:
    // 1. 发送 CMD 0x40 进入OTA模式
    // 2. 发送 CMD 0x90 开始帧（含固件长度和校验和）
    // 3. 分 64 字节一包发送 CMD 0x91 数据包
    // 4. 发送 CMD 0x92 结束帧
    // 5. 等待 ACK 确认
}
```

---

### 阶段七（可选）：历史数据功能

#### 步骤 7.1：新建 `HistoryDataView.swift`

**文件**: `/LuHengHealth/Pages/Health/HistoryDataView.swift`

**职责**: 展示心率/血氧/步数的历史数据

---

## 四、执行顺序与依赖关系

```
阶段一 (协议层)          阶段二 (ViewModel)         阶段三 (写入适配)       阶段四 (UI)
─────────────────      ──────────────────       ──────────────────    ──────────────
步骤 1.1 命令构建   ──→ 步骤 2.1 发布属性    ──→ 步骤 3.1 HomePage ──→ 步骤 4.1 详情页
步骤 1.2 帧解析器   ──→ 步骤 2.2 命令发送    ──→ 步骤 3.2 旧方法兼容  步骤 4.2 自动请求
                      ──→ 步骤 2.3 接收分发                        ──→ 步骤 4.3 设备页
                      ──→ 步骤 2.4 轮询定时器                      ──→ 步骤 4.4 灯光控制
                      ──→ 步骤 2.5 告警处理

阶段五 (文档)
─────────────
步骤 5.1 协议文档
步骤 5.2 README

阶段六 (可选: OTA)      阶段七 (可选: 历史)
─────────────────      ──────────────────
步骤 6.1 OTA服务        步骤 7.1 历史页面
```

---

## 五、风险点与注意事项

### 5.1 BLE 数据包分片问题
BLE 单次传输最大约 20 字节（MTU 限制）。新协议部分命令超过 20 字节（如 OTA 数据包 72 字节）。需要确认：
- 设备是否支持 MTU 协商
- WCHBLELibrary 是否自动处理分片
- 如果不支持，需要在应用层实现分片/重组

### 5.2 多帧返回的处理
序列号（CMD 0x06）和历史数据（CMD 0x07/0x08/0x09）返回两帧。需要注意：
- 两帧可能在同一次 `didUpdateValue` 中到达（拼包），也可能分两次到达
- 需要维护一个临时缓冲区来收集多帧数据
- 或者使用帧头中的标记位（如 0x80）区分第一帧/第二帧

### 5.3 ACK 帧与返回帧的区分
设备可能同时发送返回帧（AA 56）和 ACK 帧（AA 57），解析器需要正确区分。

### 5.4 向后兼容
- 旧的 `writeRGBControlToFFE3` 方法被 HomePage 调用，需要保持签名兼容
- 旧的 `BLEHealthData` 结构体被 `HealthDataStorage` 使用，需要确认是否需要保留

### 5.5 轮询频率
- 每 3 秒轮询一次心率/血氧/步数/电量，可能过于频繁
- 建议：心率/血氧 3 秒，电量 30 秒，步数 10 秒
- 或者利用设备的自动上报机制（协议中提到"变化自动上报帧"）

### 5.6 校验和计算
新协议要求计算校验和（帧头到数据区累加和取低8位），需要确保计算正确：
```
例: AA 55 00 11 → CHECK = (0xAA + 0x55 + 0x00 + 0x11) & 0xFF = 0x10
完整帧: AA 55 00 11 10 55 AA
```

---

## 六、验证检查清单

- [ ] 校验和计算: 对比协议文档中的示例帧
- [ ] 写入帧构建: 验证每个 CMD 的完整字节序列
- [ ] 返回帧解析: 准备模拟数据，验证心率/血氧/步数/电量/版本解析
- [ ] ACK帧解析: 验证成功(01)和失败(02)状态识别
- [ ] 告警帧解析: 验证 5 种告警类型
- [ ] 灯光控制: 实机测试颜色/亮度/呼吸灯/槽切换
- [ ] 灯光参数回读: 验证回读数据与设置一致
- [ ] 轮询机制: 验证连接后自动请求数据
- [ ] 多帧数据: 验证序列号和历史数据的两帧组装
- [ ] 断开重连: 验证断开后清理状态、重连后重新请求
- [ ] UI 显示: 所有数据字段正确显示
- [ ] HomePage 灯光控制: 颜色/亮度/呼吸模式正常工作
