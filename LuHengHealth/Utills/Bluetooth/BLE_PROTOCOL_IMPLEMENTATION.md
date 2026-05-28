# 蓝牙协议层实现文档

> 记录阶段一~三完成的蓝牙协议层重构（从旧协议固定17字节推送升级到新协议CMD请求-响应+ACK模式）

---

## 一、完成概述

阶段一完成了蓝牙协议层的重构，从旧协议（固定17字节推送）升级到新协议（CMD请求-响应 + ACK模式）。

---

## 二、文件清单

| 文件 | 类型 | 说明 |
|------|------|------|
| `BLECommandBuilder.swift` | 新建 | 蓝牙命令构建工具类 |
| `BLEProtocolParser.swift` | 重写 | 蓝牙帧解析器 |

---

## 三、BLECommandBuilder.swift

### 3.1 职责

封装所有「手机→设备」的写入命令构建。

### 3.2 核心方法

#### 校验和计算
```swift
static func calculateChecksum(_ bytes: [UInt8]) -> UInt8
```
帧头到数据区所有字节累加和取低8位。

#### 通用写入帧构建
```swift
static func buildWriteFrame(cmd: UInt8, data: [UInt8] = []) -> Data
```
构建格式: `AA 55 LEN CMD DATA[LEN] CHECK 55 AA`

#### 数据读取命令

| 方法 | CMD | 说明 |
|------|-----|------|
| `readHeartRate()` | 0x11 | 读取心率 |
| `readBloodOxygen()` | 0x12 | 读取血氧 |
| `readStepCount()` | 0x13 | 读取步数 |
| `readBatteryLevel()` | 0x14 | 读取电量 |
| `readFirmwareVersion()` | 0x15 | 读取固件版本 |
| `readSerialNumber()` | 0x16 | 读取序列号 |

#### 历史数据读取命令

| 方法 | CMD | 说明 |
|------|-----|------|
| `readHeartRateHistory()` | 0x17 | 读取心率历史 |
| `readBloodOxygenHistory()` | 0x18 | 读取血氧历史 |
| `readStepCountHistory()` | 0x19 | 读取步数历史 |

#### 灯光控制命令

| 方法 | CMD | 说明 |
|------|-----|------|
| `setLightSlotColor(slot:r:g:b:)` | 0x21 | 设置灯光槽颜色 |
| `setLightSlotBrightness(slot:brightness:)` | 0x22 | 设置灯光槽亮度 |
| `setBreathingLight(enabled:)` | 0x23 | 设置呼吸灯开关 |
| `switchLightSlot(slot:)` | 0x24 | 切换当前灯光槽 |
| `readLightParams(slot:)` | 0x30 | 读取灯光参数 |

#### OTA 升级命令

| 方法 | CMD | 说明 |
|------|-----|------|
| `enterOTAMode()` | 0x40 | 请求进入 OTA 模式 |
| `buildOTAStartFrame(firmwareSize:checksum:)` | 0x90 | OTA 开始升级帧 |
| `buildOTADataPacket(sequence:data:)` | 0x91 | OTA 固件数据包 |
| `buildOTAEndFrame(firmwareSize:checksum:)` | 0x92 | OTA 结束升级帧 |

---

## 四、BLEProtocolParser.swift

### 4.1 职责

解析蓝牙设备传输的数据协议，支持 CMD 请求-响应模式 + ACK模式。

### 4.2 支持的帧类型

| 帧类型 | 格式 | 标识 |
|--------|------|------|
| 返回帧 | `AA 56 LEN CMD DATA[LEN] CHECK 56 AA` | 手机请求后设备响应 |
| ACK帧 | `AA 57 05 7F 原CMD STATUS 00 00 00 CHECK 57 AA` | 命令执行状态确认 |
| OTA ACK帧 | `A5 CMD STATUS SEQ_H SEQ_L PROGRESS ERR 5A` | OTA 升级进度反馈 |

### 4.3 核心结构体

#### ParsedFrame
```swift
struct ParsedFrame {
    let type: FrameType           // 帧类型
    let cmd: UInt8                // 命令码
    let data: [UInt8]             // 数据区
    let isValid: Bool             // 校验是否通过
    let originalCmd: UInt8?       // ACK帧中: 被应答的原CMD
    let status: UInt8?            // ACK帧中: 01成功/02失败
}
```

#### AlarmData
```swift
struct AlarmData {
    let alarmCode: UInt8          // 告警码
    let paramA: UInt8             // 参数A
    let paramB: UInt8             // 参数B
    let paramC: UInt8             // 参数C
}
```

#### 其他数据结构

| 结构体 | 说明 |
|--------|------|
| `HistoryTimeFrame` | 历史记录时间（年/月/日/时/分） |
| `HistoryDataFrame` | 历史记录数据（最小值/最大值） |
| `LightColorFrame` | 灯光颜色参数（槽/红/绿/蓝/当前槽） |
| `LightBrightnessFrame` | 灯光亮度参数（槽/亮度/呼吸/方向） |
| `SerialNumberFrame` | 序列号帧（第一帧/第二帧标识 + 4字节数据） |

### 4.4 核心解析方法

#### 帧解析入口
```swift
func parse(_ data: Data) -> ParsedFrame
```

#### CMD 分发解析

| 方法 | 对应返回 CMD | 说明 |
|------|-------------|------|
| `parseHeartRateResponse(_:)` | 0x01 | 解析心率返回帧 |
| `parseBloodOxygenResponse(_:)` | 0x02 | 解析血氧返回帧 |
| `parseStepCountResponse(_:)` | 0x03 | 解析步数返回帧 |
| `parseBatteryLevelResponse(_:)` | 0x04 | 解析电量返回帧 |
| `parseFirmwareVersionResponse(_:)` | 0x05 | 解析固件版本返回帧 |
| `parseAlarmResponse(_:)` | 0x80 | 解析告警返回帧 |
| `parseLightColorResponse(_:)` | 0x30 | 解析灯光颜色参数返回帧 |
| `parseLightBrightnessResponse(_:)` | 0x31 | 解析灯光亮度参数返回帧 |
| `parseHistoryTimeResponse(_:)` | 0x07/0x08/0x09 | 解析历史记录时间帧 |
| `parseHistoryDataResponse(_:)` | 0x07/0x08/0x09 | 解析历史记录数据帧 |

#### 序列号解析
```swift
func parseSerialNumberResponse(_:) -> SerialNumberFrame?
func combineSerialNumber(frames:) -> String?
```
序列号需要两帧组合：第一帧（索引0x00）+ 第二帧（索引0x01）= 8字节序列号。

---

## 五、使用示例

### 5.1 构建读取心率命令
```swift
let heartRateCommand = BLECommandBuilder.readHeartRate()
// 输出: AA 55 00 11 10 55 AA
```

### 5.2 解析设备返回的心率数据
```swift
let receivedData = Data([0xAA, 0x56, 0x05, 0x01, 0x64, 0x00, 0x00, 0x00, 0x00, 0x6A, 0x56, 0xAA])
let frame = BLEProtocolParser.shared.parse(receivedData)
if frame.isValid {
    let heartRate = BLEProtocolParser.shared.parseHeartRateResponse(frame)
    print("心率: \(heartRate ?? 0) bpm")
}
```

### 5.3 解析告警数据
```swift
if let alarm = BLEProtocolParser.shared.parseAlarmResponse(frame) {
    print(alarm.description)
}
```

---

## 六、下一步计划

阶段二将修改 `BLEViewModel.swift`，实现：
- 发布属性新增（序列号、告警、灯光参数、历史数据）
- 命令发送方法改造
- 数据接收分发逻辑改造
- 自动轮询定时器
- 告警处理逻辑

详见: [../../docs/protocol-upgrade-plan.md](../../docs/protocol-upgrade-plan.md)

---

## 七、阶段二完成内容 (BLEViewModel.swift)

### 7.1 新增 @Published 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `serialNumber` | `String?` | 设备序列号 |
| `currentAlarm` | `AlarmData?` | 当前告警数据 |
| `alarmMessage` | `String?` | 告警消息文本 |
| `showAlarm` | `Bool` | 是否显示告警弹窗 |
| `lightSlot` | `UInt8` | 当前灯光槽编号 |
| `lightRed/Green/Blue` | `UInt8` | 灯光RGB分量 |
| `lightBrightness` | `UInt16` | 灯光亮度值 |
| `lightBreathing` | `Bool` | 呼吸灯是否开启 |
| `heartRateHistory` | `HistoryRecord?` | 心率历史记录 |
| `bloodOxygenHistory` | `HistoryRecord?` | 血氧历史记录 |
| `stepCountHistory` | `HistoryRecord?` | 步数历史记录 |
| `lastAckCmd` | `UInt8?` | 最近ACK命令码 |
| `lastAckStatus` | `UInt8?` | 最近ACK状态 |

### 7.2 新增命令发送方法

```swift
// 通用命令发送
func sendCommand(_ cmd: UInt8, data: [UInt8] = [])

// 数据读取
func requestHeartRate()       // CMD 0x11
func requestBloodOxygen()    // CMD 0x12
func requestStepCount()       // CMD 0x13
func requestBatteryLevel()   // CMD 0x14
func requestFirmwareVersion() // CMD 0x15
func requestSerialNumber()    // CMD 0x16

// 历史数据读取
func requestHeartRateHistory()    // CMD 0x17
func requestBloodOxygenHistory()  // CMD 0x18
func requestStepCountHistory()     // CMD 0x19

// 灯光控制
func setLightColor(slot:r:g:b:)       // CMD 0x21
func setLightBrightness(slot:brightness:) // CMD 0x22
func setBreathingLight(enabled:)       // CMD 0x23
func switchLightSlot(slot:)            // CMD 0x24
func requestLightParams(slot:)         // CMD 0x30

// 批量读取
func requestAllData()
```

### 7.3 数据接收分发

`bleManagerUpdateValue` 方法重构，使用 `BLEProtocolParser.shared.parse()` 按帧类型分发：
- `.responseFrame` → `handleResponseFrame()` 按 CMD 解析
- `.ackFrame` → `handleAckFrame()` 更新 ACK 状态
- `.otaAck` → 保留扩展

### 7.4 自动轮询定时器

```swift
private var pollingTimer: Timer?
private let pollingInterval: TimeInterval = 3.0  // 每3秒轮询

private func startPolling()
private func stopPolling()
```

**调用时机：**
- 连接成功 + 发现 FFE3 特征后 → `startPolling()`
- 断开连接时 → `stopPolling()`

### 7.5 告警处理

`handleAlarm()` 解析告警帧并更新 UI：
- 0x02: 低电量告警
- 0x11: 心率过低告警
- 0x12: 心率过高告警
- 0x21: 血氧过低告警
- 0x22: 血氧无效告警

---

## 八、阶段三完成内容 (写入格式适配)

### 8.1 概述

阶段三验证了 HomePage.swift 灯光控制调用与新协议的兼容性，确认**无需修改**任何前端代码。

### 8.2 兼容性分析

| 调用方 | 调用方法 | 兼容方式 |
|--------|---------|---------|
| `HomePage.swift` | `writeRGBControlToFFE3(red:green:blue:mode:brightness:)` | ✅ 已在阶段二内部转为新协议 |

### 8.3 writeRGBControlToFFE3 兼容实现

```swift
func writeRGBControlToFFE3(red: UInt8, green: UInt8, blue: UInt8,
                            mode: UInt8, brightness: UInt16,
                            preferWithoutResponse: Bool = true) {
    let breathing = (mode == 2)
    setBreathingLight(enabled: breathing)      // CMD 0x23
    setLightColor(slot: 0xFF, r: red, g: green, b: blue)      // CMD 0x21
    setLightBrightness(slot: 0xFF, brightness: brightness)    // CMD 0x22
}
```

**结论：** HomePage.swift 保持原样调用即可正常工作，无需任何修改。

---

## 九、Git 提交记录

```
38360fa docs: 更新蓝牙协议实现文档
08c8a53 feat(ble): 阶段二完成 - ViewModel核心逻辑升级
f3a86ff feat(ble): 重构蓝牙协议层支持新CMD协议
```

---

*最后更新: 2026-05-26*
