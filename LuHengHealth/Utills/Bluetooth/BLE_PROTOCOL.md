# 蓝牙通信协议文档

> 本文档详细描述 LuHengHealth 应用与 BLE 传感器设备之间的通信协议。
> 版本: 1.0
> 更新日期: 2025-09-10

---

## 目录

1. [协议概述](#1-协议概述)
2. [BLE 服务与特征定义](#2-ble-服务与特征定义)
3. [接收数据协议（设备→手机）](#3-接收数据协议设备手机)
4. [发送控制协议（手机→设备）](#4-发送控制协议手机设备)
5. [协议帧格式详解](#5-协议帧格式详解)
6. [数据示例](#6-数据示例)
7. [错误处理](#7-错误处理)
8. [修改记录](#8-修改记录)

---

## 1. 协议概述

### 1.1 通信模式

| 方向 | 特征 | 通信类型 | 说明 |
|------|------|----------|------|
| 设备 → 手机 | FFE4 | Notify (通知) | 传感器数据上报 |
| 手机 → 设备 | FFE3 | Write (写入) | 控制命令下发 |

### 1.2 数据流图

```
┌─────────────┐         BLE 广播             ┌─────────────┐
│   传感器     │ ──────────────────────────► │    手机     │
│   设备       │                             │   App       │
└─────────────┘                             └──────┬──────┘
                                                   │
                    ┌──────────────────────────────┴──────────────────────────────┐
                    │                                                              │
              ┌─────▼─────┐                                                ┌──────▼─────┐
              │   FFE4    │  订阅通知                                       │    FFE3    │
              │  (接收)    │ ◄─────────────────────── 数据包 ──────────── ── │   (发送)   │
              └───────────┘  AA 55 心率 血氧 电池 55 AA                      └────────────┘
```

---

## 2. BLE 服务与特征定义

### 2.1 服务 (Service)

| 属性 | 值 |
|------|-----|
| 服务 UUID | `FFE0` |

### 2.2 特征 (Characteristics)

| 特征名称 | UUID | 属性 | 说明 |
|----------|------|------|------|
| 通知特征 | `FFE4` | Notify | 设备主动上报传感器数据 |
| 写入特征 | `FFE3` | Write / WriteWithoutResponse | App 下发控制命令 |

### 2.3 UUID 完整格式

在代码中的定义 ([BLEViewModel.swift](file:///Users/macios/gzy文件/LuHengHealth/LuHengHealth/Utills/Bluetooth/BLEViewModel.swift#L99-L101)):

```swift
private let targetServiceUUID = CBUUID(string: "FFE0")  // 服务
private let notifyCharUUID    = CBUUID(string: "FFE4")  // 订阅通知
private let writeCharUUID     = CBUUID(string: "FFE3")  // 写入数据
```

---

## 3. 接收数据协议（设备→手机）v1.2

### 3.1 数据包结构

传感器设备通过 **FFE4** 特征主动上报健康数据。

| 字段 | 索引 | 长度 | 数据类型 | 说明 |
|------|------|------|----------|------|
| 帧头1 | Byte 0 | 1 byte | UInt8 | 固定值 `0xAA` |
| 帧头2 | Byte 1 | 1 byte | UInt8 | 固定值 `0x55` |
| 心率 | Byte 2 | 1 byte | UInt8 | 心率值 (40-200 bpm) |
| 血氧 | Byte 3 | 1 byte | UInt8 | 血氧饱和度 (0-100%) |
| 电池电压高8位 | Byte 4 | 1 byte | UInt8 | 电池电压高字节 |
| 电池电压低8位 | Byte 5 | 1 byte | UInt8 | 电池电压低字节 |
| 步数高8位 | Byte 6 | 1 byte | UInt8 | 步数高字节 (v1.2新增) |
| 步数低8位 | Byte 7 | 1 byte | UInt8 | 步数低字节 (v1.2新增) |
| 固件版本号 | Byte 8 | 1 byte | UInt8 | 版本号，如12代表1.2 (v1.2新增) |
| 预留位 | Byte 9-14 | 6 bytes | UInt8 | 预留以后备用 |
| 帧尾1 | Byte 15 | 1 byte | UInt8 | 固定值 `0x55` |
| 帧尾2 | Byte 16 | 1 byte | UInt8 | 固定值 `0xAA` |

**数据包总长度**: 17 bytes

### 3.2 帧头帧尾定义

| 常量 | 值 | 说明 |
|------|-----|------|
| `frameHeader1` | `0xAA` | 第一帧头字节 |
| `frameHeader2` | `0x55` | 第二帧头字节 |
| `frameFooter1` | `0x55` | 第一帧尾字节 (v1.2变更: Byte 6 → Byte 15) |
| `frameFooter2` | `0xAA` | 第二帧尾字节 (v1.2变更: Byte 7 → Byte 16) |

### 3.3 数据解析规则

#### 心率值 (Heart Rate)
```swift
let heartRate = Int(data[2])  // 直接取值
```

#### 血氧值 (Blood Oxygen)
```swift
let bloodOxygen = Int(data[3])  // 直接取值
```

#### 电池电压 (Battery Voltage)

电池电压需要进行线性转换：

```swift
let batteryHigh = Int(data[4])
let batteryLow = Int(data[5])
let batteryVoltage = ((batteryHigh << 8) + batteryLow - 2925) * 100 / 1171
```

**转换公式解释**:
- `(high << 8) + low` - 将高字节和低字节组合成原始电压值
- `- 2925` - 减去零点偏移
- `* 100 / 1171` - 线性缩放到百分比 (0-100%)

#### 步数 (Step Count) - v1.2新增
```swift
let stepCountHigh = Int(data[6])
let stepCountLow = Int(data[7])
let stepCount = (stepCountHigh << 8) + stepCountLow
```

#### 固件版本号 (Firmware Version) - v1.2新增
```swift
let firmwareVersion = Int(data[8])  // 如12代表1.2，24代表2.4
```

### 3.4 数据有效性验证

协议解析器 ([BLEProtocolParser.swift](file:///Users/macios/gzy文件/LuHengHealth/LuHengHealth/Utills/Bluetooth/BLEProtocolParser.swift)) 执行以下验证:

1. **长度检查**: 数据长度必须 >= 17 bytes (v1.2)
2. **帧头检查**: `data[0] == 0xAA && data[1] == 0x55`
3. **帧尾检查**: `data[15] == 0x55 && data[16] == 0xAA` (v1.2变更)

---

## 4. 发送控制协议（手机→设备）

### 4.1 RGB 控制命令

App 通过 **FFE3** 特征向设备发送控制命令。

| 字段 | 索引 | 长度 | 数据类型 | 说明 |
|------|------|------|----------|------|
| 帧头 | Byte 0 | 1 byte | UInt8 | 固定值 `0xAA` |
| 命令码 | Byte 1 | 1 byte | UInt8 | 固定值 `0x0F` (RGB控制) |
| 红色分量 | Byte 2 | 1 byte | UInt8 | R 值 (0-255) |
| 绿色分量 | Byte 3 | 1 byte | UInt8 | G 值 (0-255) |
| 蓝色分量 | Byte 4 | 1 byte | UInt8 | B 值 (0-255) |
| 模式 | Byte 5 | 1 byte | UInt8 | 模式选择 (0-255) |
| 亮度高8位 | Byte 6 | 1 byte | UInt8 | 亮度高字节 |
| 亮度低8位 | Byte 7 | 1 byte | UInt8 | 亮度低字节 |
| 帧尾 | Byte 8 | 1 byte | UInt8 | 固定值 `0x55` |

**数据包总长度**: 9 bytes

### 4.2 命令码定义

| 命令码 | 功能 | 说明 |
|--------|------|------|
| `0x0F` | RGB LED 控制 | 控制设备RGB颜色和亮度 |

### 4.3 亮度值组合

亮度为 16 位值 (0-65535)，拆分为高低两个字节：

```swift
let brightnessHigh = UInt8(brightness >> 8)    // 高8位
let brightnessLow = UInt8(brightness & 0xFF) // 低8位
```

**组合公式**:
```swift
let brightness = (UInt16(brightnessHigh) << 8) + UInt16(brightnessLow)
```

### 4.4 数据发送方法

代码实现 ([BLEViewModel.swift](file:///Users/macios/gzy文件/LuHengHealth/LuHengHealth/Utills/Bluetooth/BLEViewModel.swift#L703-L709)):

```swift
func writeRGBControlToFFE3(red: UInt8, green: UInt8, blue: UInt8, mode: UInt8, brightness: UInt16) {
    let brightnessHigh = UInt8(brightness >> 8)
    let brightnessLow = UInt8(brightness & 0xFF)
    let data = Data([0xAA, 0x0F, red, green, blue, mode, brightnessHigh, brightnessLow, 0x55])
    writeToFFE3(data)
}
```

### 4.5 写入类型

FFE3 特征支持两种写入类型：

| 类型 | 说明 | 使用场景 |
|------|------|----------|
| `.withResponse` | 写入后等待设备确认 | 需要确认的命令 |
| `.withoutResponse` | 写入后不等待响应 | 频繁发送的实时控制 |

---

## 5. 协议帧格式详解

### 5.1 接收数据帧格式（设备→手机）v1.2

```
┌───────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   数据帧 v1.2 (17 bytes)                                     │
├─────────┬─────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────┬────────────┤
│ Byte 0 │ Byte 1  │ Byte 2 │ Byte 3 │ Byte 4 │ Byte 5 │ Byte 6 │ Byte 7 │ Byte 8 │ Byte 9-14  │
├─────────┼─────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────────┤
│  0xAA  │  0x55   │ 心率   │ 血氧   │ 电池高 │ 电池低 │ 步数高 │ 步数低 │ 版本号 │   预留    │
│ 帧头1  │ 帧头2   │ HR     │ SpO2   │ VBAT_H │ VBAT_L │ STEPS_H│ STEPS_L│  VER   │  RESERVED │
└─────────┴─────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────────┘
         │                                                                                     │
         │                                    ┌────────────────────────────────────────┐
         └──────────────────────────────────►│ Byte 15  │         Byte 16             │◄─┘
                                            │   0x55   │          0xAA               │
                                            │   帧尾1   │          帧尾2              │
                                            └──────────┴─────────────────────────────┘
```

### 5.2 发送控制帧格式（手机→设备）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              控制帧 (9 bytes)                                │
├─────────┬─────────┬────────┬────────┬────────┬────────┬────────┬────────┬─────┤
│ Byte 0 │ Byte 1  │ Byte 2 │ Byte 3 │ Byte 4 │ Byte 5 │ Byte 6 │ Byte 7 │  8  │
├─────────┼─────────┼────────┼────────┼────────┼────────┼────────┼────────┼─────┤
│  0xAA  │  0x0F   │ 红色R  │ 绿色G  │ 蓝色B  │  模式  │ 亮度高 │ 亮度低 │ 0x55│
│ 帧头   │ 命令码  │ (0-255)│ (0-255)│ (0-255)│ (0-255)│ (0-255)│ (0-255)│ 帧尾│
└─────────┴─────────┴────────┴────────┴────────┴────────┴────────┴────────┴─────┘
```

---

## 6. 数据示例

### 6.1 接收数据示例 (v1.2)

假设设备发送的原始字节数据为:
```
AA 55 72 98 0B B4 00 C8 0C 00 00 00 00 00 00 55 AA
```

解析结果:

| 字段 | 原始值 | 解析后值 | 说明 |
|------|--------|----------|------|
| 帧头 | `AA 55` | ✓ | 正确 |
| 心率 | `72` (hex) | 114 bpm | 正常心率 |
| 血氧 | `98` (hex) | 152 | 异常值(应为0-100) |
| 电池电压 | `0B B4` = 2996 | 4.0% | ((2996-2925)*100/1171) |
| 步数 | `00 C8` = 200 | 200 步 | (0<<8)+200=200 |
| 固件版本 | `0C` = 12 | 1.2 | 代表固件版本1.2 |
| 预留位 | `00 00 00 00 00 00` | - | 预留备用 |
| 帧尾 | `55 AA` | ✓ | 正确 |

### 6.2 发送控制数据示例

发送 RGB 颜色控制命令:
```
AA 0F FF 00 00 01 03 E8 55
```

解析结果:

| 字段 | 原始值 | 说明 |
|------|--------|------|
| 帧头 | `AA` | 固定帧头 |
| 命令码 | `0F` | RGB控制命令 |
| 红色 | `FF` (255) | 最大红色 |
| 绿色 | `00` | 无绿色 |
| 蓝色 | `00` | 无蓝色 |
| 模式 | `01` | 模式1 |
| 亮度高 | `03` | 3 << 8 = 768 |
| 亮度低 | `E8` (232) | 232 |
| 亮度总值 | 1000 | (768+232) = 1000 |
| 帧尾 | `55` | 固定帧尾 |

### 6.3 控制台日志示例

```
FFE4 解析成功: 心率=72, 血氧=98, 电池电压=4mV
```

---

## 7. 错误处理

### 7.1 数据验证失败

当接收数据不符合协议格式时，协议解析器返回 `isValid = false`:

```swift
struct BLEHealthData {
    let heartRate: Int?        // nil
    let bloodOxygen: Int?      // nil
    let batteryVoltage: Int?   // nil
    let isValid: Bool          // false
    // ...
}
```

### 7.2 数据范围校验

在应用层应进行数据范围校验:

| 数据项 | 正常范围 | 异常处理 |
|--------|----------|----------|
| 心率 | 40-200 bpm | 丢弃异常值 |
| 血氧 | 90-100% | 丢弃异常值 |
| 电池电压 | 0-100% | 限制在范围内 |

---

## 8. 修改记录

| 版本 | 日期 | 作者 | 修改内容 |
|------|------|------|----------|
| 1.0 | 2025-09-10 | macios | 初始版本，定义FFE0/FFE3/FFE4协议 |

---

## 附录: 相关代码文件

| 文件 | 路径 | 说明 |
|------|------|------|
| BLEViewModel.swift | `LuHengHealth/Utills/Bluetooth/` | 蓝牙ViewModel，定义UUID和通信逻辑 |
| BLEProtocolParser.swift | `LuHengHealth/Utills/Bluetooth/` | 协议解析器，解析接收数据 |
| BLEContentView.swift | `LuHengHealth/Pages/Device/` | 蓝牙设备列表UI |
| HealthDataStorage.swift | `LuHengHealth/Utills/Health/` | 健康数据存储 |
