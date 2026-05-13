# LuHengHealth

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-15.0-blue.svg)
![Xcode](https://img.shields.io/badge/Xcode-15.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%7CiPadOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg)](CONTRIBUTING.md)

一款基于蓝牙BLE通信的智能健康监测与设备控制iOS应用，配套传感器硬件实现心率、血氧等健康数据的实时采集与可视化展示。

## 📱 应用简介

路恒健康是一款集 **健康数据监测**、**蓝牙设备控制**、**运动记录** 于一体的智能健康应用。通过蓝牙低功耗（BLE）技术连接专用传感器设备，实现：

- ❤️ **心率实时监测** - 传感器采集，秒级更新
- 💧 **血氧饱和度检测** - 持续追踪血氧变化
- 🔋 **设备电量监控** - 实时掌握设备状态
- 🎨 **智能设备控制** - RGB颜色、亮度、模式调节
- 📊 **健康数据管理** - 历史记录、日历视图、数据趋势

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────────┐
│                      LuHengHealthApp                     │
│                         (入口)                           │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────┴───────────────────────────────┐
│                         MainPage                          │
│                   (TabBar 底部导航)                        │
├───────────┬───────────┬───────────┬───────────┬─────────┤
│  HomePage │HealthPage │DevicePage │SportPage  │Account  │
│   (首页)   │  (健康)   │  (设备)   │  (运动)   │  (我的) │
└─────┬─────┴─────┬─────┴─────┬─────┴───────────┴─────────┘
      │           │           │
      └───────────┴───────────┘
                  │
      ┌───────────┴───────────┐
      │      BLEViewModel      │
      │    (蓝牙核心ViewModel)   │
      └───────────┬───────────┘
                  │
      ┌───────────┴───────────┐
      │   BLEProtocolParser   │
      │     (协议解析器)        │
      └───────────┬───────────┘
                  │
      ┌───────────┴───────────┐
      │  HealthDataStorage   │
      │   (Core Data存储)     │
      └───────────────────────┘
```

**设计模式**: MVVM + SwiftUI响应式编程

**核心框架**:
- SwiftUI (界面层)
- CoreBluetooth (蓝牙通信)
- WCHBLELibrary (第三方BLE管理器)
- Core Data (数据持久化)
- AVFoundation (二维码扫描)

## 📁 项目结构

```
LuHengHealth/
├── LuHengHealth/                          # 主应用目录
│   ├── Assets.xcassets/                   # 图片资源
│   │   ├── AccentColor.colorset/          # 主题色
│   │   ├── AppIcon.appiconset/            # 应用图标
│   │   └── Image/                         # 功能图片（BMI、跑步、饮食等）
│   │
│   ├── CommonControls/                    # 通用UI组件
│   │   ├── 3DModel/                        # 3D模型资源（项链、灯光）
│   │   ├── Responsive/                     # 响应式布局组件
│   │   │   ├── ResponsiveContainer.swift  # 自适应容器（支持iPad/iPhone）
│   │   │   └── VisualEffectBlur.swift     # 模糊效果组件
│   │   └── mytabbar.swift                 # 自定义底部导航栏
│   │
│   ├── Pages/                             # 页面模块
│   │   ├── Account/                       # 账户页面
│   │   │   ├── AccountPage.swift          # 我的主页
│   │   │   └── LoginView.swift            # 登录视图
│   │   │
│   │   ├── Device/                        # 设备页面
│   │   │   ├── BLEContentView.swift       # 蓝牙设备列表与连接
│   │   │   ├── DevicePage.swift           # 设备控制主页
│   │   │   └── QRCodeScannerView.swift    # 二维码扫描
│   │   │
│   │   ├── Health/                        # 健康数据页面
│   │   │   ├── CircularProgressChart.swift # 环形进度图表
│   │   │   ├── HealthCalendarView.swift    # 健康日历视图
│   │   │   ├── HealthDataDetailPage.swift  # 数据详情页
│   │   │   ├── HealthDataStorageSettingsView.swift # 存储设置
│   │   │   └── HealthPage.swift            # 健康主页
│   │   │
│   │   ├── Home/                          # 首页（设备控制）
│   │   │   ├── HomePage.swift             # 首页主视图
│   │   │   ├── InspirationLibraryPage.swift # 灵感库页面
│   │   │   ├── QuickAdjustMorePage.swift   # 快捷调节更多页面
│   │   │   └── homepagecontrol/            # 首页组件
│   │   │       ├── ArcColorPicker.swift    # 弧形颜色选择器
│   │   │       ├── BrightnessSlider.swift  # 亮度滑块
│   │   │       ├── ColorCircularPicker.swift # 圆形颜色选择器
│   │   │       ├── ColorControlPanel.swift # 颜色控制面板
│   │   │       ├── HalfCircleColorWheel.swift # 半圆颜色轮
│   │   │       ├── Helper.swift            # 辅助函数
│   │   │       ├── Model3DView.swift       # 3D模型视图
│   │   │       ├── NewColourWheel.swift    # 新颜色轮
│   │   │       ├── ProductDisplayView.swift # 产品展示视图
│   │   │       └── SmartRecommendation.swift # 智能推荐
│   │   │
│   │   ├── Splash/                         # 启动页
│   │   │   └── SplashPage.swift
│   │   │
│   │   └── Sport/                          # 运动页面
│   │       ├── CourseComponents.swift      # 课程组件
│   │       ├── FriendsCircleComponents.swift # 朋友圈组件
│   │       ├── PlanAndChallengeComponents.swift # 计划挑战组件
│   │       ├── SportPage.swift            # 运动主页
│   │       └── SubSportPage.swift          # 子运动页面
│   │
│   ├── Utills/                             # 工具类
│   │   ├── AppConfig/                      # 应用配置
│   │   │   └── AppConfigManager.swift      # 配置管理器
│   │   │
│   │   ├── Bluetooth/                      # 蓝牙模块
│   │   │   ├── BLEProtocolParser.swift     # 蓝牙协议解析器
│   │   │   └── BLEViewModel.swift          # 蓝牙视图模型
│   │   │
│   │   ├── DateUtills/                     # 日期工具
│   │   │   └── SuperDateUtill.swift
│   │   │
│   │   ├── Health/                         # 健康数据
│   │   │   ├── HealthDataService.swift     # 健康数据服务
│   │   │   ├── HealthDataStorage.swift      # 数据存储（Core Data）
│   │   │   └── HealthDataTestTool.swift    # 测试工具
│   │   │
│   │   ├── UIFormat/                        # UI格式
│   │   │   └── AppColors.swift             # 应用颜色定义
│   │   │
│   │   ├── User/                           # 用户相关
│   │   │   ├── MockRemoteUsers.swift       # 模拟用户数据
│   │   │   └── UserSession.swift           # 用户会话管理
│   │   │
│   │   └── UserInfo/                       # 用户信息
│   │       └── UserInfoStorage.swift        # 用户信息存储
│   │
│   ├── LuHengHealth.xcdatamodeld/         # Core Data模型
│   │   └── LuHengHealth.xcdatamodel/
│   │       └── contents                     # 数据模型定义
│   │
│   ├── DeviceState.swift                   # 设备状态（横竖屏、Pad/Phone）
│   ├── LuHengHealthApp.swift              # App入口
│   ├── MainPage.swift                      # 主页面框架
│   └── Persistence.swift                   # Core Data持久化控制器
│
├── LuHengHealth.xcodeproj/                # Xcode项目文件
├── LuHengHealthTests/                     # 单元测试
└── LuHengHealthUITests/                   # UI测试
```

## 🔑 核心模块详解

### 1. 蓝牙通信模块

#### BLEViewModel - 蓝牙核心管理器

负责蓝牙设备的所有操作，是整个应用与硬件通信的枢纽。

**主要功能**:
| 功能 | 说明 |
|------|------|
| `startScan()` | 开始扫描附近BLE设备 |
| `stopScan()` | 停止扫描 |
| `connect(to:)` | 连接指定设备 |
| `disconnect(from:)` | 断开设备连接 |
| `writeData(_:to:)` | 向设备写入数据 |

**状态管理**:
```swift
@Published var discoveredDevices: [BluetoothDevice]    // 发现的设备列表
@Published var connectedDevices: [BluetoothDevice]     // 已连接设备
@Published var isScanning: Bool                        // 扫描状态
@Published var bluetoothState: CBManagerState          // 蓝牙系统状态
```

**发布数据**:
```swift
@Published var heartRate: Int?        // 心率值 (bpm)
@Published var bloodOxygen: Int?      // 血氧值 (%)
@Published var batteryVoltage: Int?   // 电池电压 (mV)
```

#### BLEProtocolParser - 协议解析器

解析蓝牙设备传输的原始字节数据，提取心率、血氧、电池电压等信息。

**数据帧格式**:
```
┌─────────┬─────────┬────────┬────────┬────────┬────────┬────────┬────────┐
│  Byte0  │  Byte1  │ Byte2  │ Byte3  │ Byte4  │ Byte5  │ Byte6  │ Byte7  │
├─────────┼─────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│  0xAA   │  0x55   │ 心率   │ 血氧   │ 电池高 │ 电池低 │  0x55  │  0xAA  │
└─────────┴─────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```

**解析逻辑**:
```swift
let heartRate = Int(data[2])
let bloodOxygen = Int(data[3])
let batteryVoltage = ((data[4] << 8) + data[5] - 2925) * 100 / 1171
```

#### 服务与特征UUID

| 类型 | UUID | 说明 |
|------|------|------|
| 服务 | FFE0 | 健康监测设备服务 |
| 通知特征 | FFE4 | 订阅此特征接收传感器数据 |
| 写入特征 | FFE3 | 向设备发送控制命令 |

### 2. 健康数据模块

#### HealthDataStorage - 数据存储服务

基于Core Data的健康数据持久化管理，支持智能存储策略。

**Core Data实体**:

**BodyhealthData** - 健康数据记录
| 属性 | 类型 | 说明 |
|------|------|------|
| heartrate | Int16 | 心率值 (bpm) |
| bloodoxygen | Int16 | 血氧值 (%) |
| timestamp | Date | 记录时间 |

**UserInfo** - 用户信息
| 属性 | 类型 | 说明 |
|------|------|------|
| username | String | 用户名 |
| gender | String | 性别 |
| height | Int16 | 身高 |
| weight | Int16 | 体重 |

**智能存储策略**:
```swift
enum StorageStrategy {
    case immediate          // 立即保存
    case significantChange // 显著变化时保存（心率变化>5bpm，血氧变化>2%）
    case timeInterval      // 定时保存（间隔60秒）
    case smart             // 智能策略（推荐）
}
```

#### HealthDataService - 数据服务

封装数据读取逻辑，提供多种数据获取方式：

```swift
enum HealthDataRetrievalType {
    case latest      // 最新数据
    case average     // 平均数据
    case statistics  // 统计数据
}
```

### 3. 设备控制模块 (HomePage)

首页实现对连接设备的智能控制，包括：

| 功能 | 组件 | 说明 |
|------|------|------|
| RGB颜色控制 | ColorControlPanel, ColorCircularPicker | 调节设备LED颜色 |
| 亮度调节 | BrightnessSlider | 0-100%亮度控制 |
| 呼吸灯模式 | 内置于HomePage | 渐变呼吸效果 |
| 3D模型展示 | Model3DView | 使用SceneKit渲染 |

**控制命令发送流程**:
```
用户拖动颜色选择器
    ↓
颜色值变化 (Color)
    ↓
节流器 throttleTimer (100ms间隔)
    ↓
pendingSnapshot 暂存最新值
    ↓
writeData() 发送到设备 FFE3 特征
```

### 4. 页面导航结构

```
MainPage (TabBar)
├── HomeView → HomePage              (首页/设备控制)
├── HealthView → HealthPage          (健康数据)
├── DeviceView → DevicePage          (设备管理)
│              └── BLEContentView    (蓝牙连接)
├── SportView → SportPage            (运动)
│              ├── SubSportPage      (实时运动)
│              ├── FriendsCircle     (朋友圈)
│              ├── PlanAndChallenge  (计划挑战)
│              └── Course           (课程)
└── AccountView → AccountPage/LoginView (我的/登录)
```

## 📊 数据流向图

### 蓝牙数据接收流程

```
传感器设备
    │
    │ BLE广播
    ▼
BLEViewModel.startScan()
    │
    │ 发现设备 peripheral
    ▼
用户点击"连接"
    │
    │ connect(to: peripheral)
    ▼
WCHBLEManager delegate
    │
    │ didDiscoverServices
    ▼
发现服务 FFE0
    │
    │ 发现特征 FFE4 (通知)
    ▼
订阅通知 setNotifyValue(true)
    │
    │ 设备发送数据
    ▼
didUpdateValueFor characteristic (FFE4)
    │
    │ 原始 Data
    ▼
BLEProtocolParser.parseFFE4Data()
    │
    │ 解析出心率/血氧/电池
    ▼
@Published heartRate/bloodOxygen/batteryVoltage
    │
    │ SwiftUI @Published 自动发布
    ▼
UI 自动更新 (HomePage, HealthPage)
    │
    │ 可选：保存数据
    ▼
HealthDataStorage.saveHealthData()
    │
    │ Core Data
    ▼
持久化存储
```

## 🛠️ 开发指南

### 环境要求

- **Xcode**: 15.0+
- **iOS**: 15.0+
- **Swift**: 5.9+
- **macOS**: Sonoma 14.0+ (用于开发)

### 第三方依赖

本项目使用 **WCHBLELibrary** 第三方库进行蓝牙管理，需要在项目中集成：

```
LuHengHealth/
└── WCHBLELibrary.framework    # 需单独配置
```

> ⚠️ **注意**: WCHBLELibrary.framework 需要从第三方渠道获取并手动添加到项目中。

### 配置蓝牙权限

在 `Info.plist` 中添加：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>路恒健康需要蓝牙权限来连接传感器设备并读取健康数据</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>路恒健康需要蓝牙权限来连接传感器设备</string>
<key>NSCameraUsageDescription</key>
<string>路恒健康需要相机权限来扫描设备二维码</string>
```

### 运行项目

1. 克隆项目到本地
2. 打开 `LuHengHealth.xcodeproj`
3. 配置 WCHBLELibrary.framework 路径
4. 选择目标设备（iPhone/iPad）
5. 按 Cmd+R 运行

### iPad/iPhone 自适应

项目使用自定义响应式布局组件 `ResponsiveContainer` 实现跨设备适配：

```swift
ResponsiveContainer(fillMode: .fit) {
    // 内容
}
```

自动检测设备类型和屏幕方向，适配字体大小、间距等。

## 📐 设计规范

### 颜色系统 (AppColors)

| 颜色名 | 用途 |
|--------|------|
| maincolor | 主题色 |
| background | 背景色 |
| accent | 强调色 |

### 响应式字体

```swift
ResponsiveFont.title(config)    // 标题
ResponsiveFont.headline(config) // 副标题
ResponsiveFont.body(config)    // 正文
ResponsiveFont.caption(config) // 注释
```

## 🔧 调试建议

### 蓝牙调试

1. 使用 LightBlue 或 nRF Connect 应用验证 BLE 设备
2. 检查设备广播的 UUID 是否为 FFE0
3. 确认 FFE4 特征支持通知 (Notify)
4. 观察数据帧是否符合 AA55...55AA 格式

### 数据存储调试

1. 使用 Xcode Core Data 调试器查看存储数据
2. HealthDataStorage 使用智能策略，可能不会每次都保存
3. 观察控制台输出 "根据存储策略跳过保存"

## 📄 文件清单

| 目录/文件 | 文件数 | 说明 |
|-----------|--------|------|
| LuHengHealth/ | - | 主应用目录 |
| Pages/ | 15 | 页面文件 |
| CommonControls/ | 5 | 通用组件 |
| Utills/ | 12 | 工具类 |
| Assets.xcassets/ | 50+ | 图片资源 |
| **总计** | **52** | Swift源文件 |

## 📌 注意事项

1. **蓝牙权限**: iOS 13+ 需要申请蓝牙权限并获得用户授权
2. **WCHBLELibrary**: 本项目依赖此第三方库，需单独配置
3. **设备兼容性**: 仅支持广播 UUID 为 FFE0 的 BLE 设备
4. **数据有效性**: 心率正常范围 40-200 bpm，血氧正常范围 90-100%

## 🔮 后续优化方向

- [ ] 添加 Apple HealthKit 集成
- [ ] 支持更多类型的 BLE 设备
- [ ] 添加数据导出功能 (CSV/PDF)
- [ ] 实现云端同步
- [ ] 添加运动轨迹记录 (GPS)
- [ ] 支持 Apple Watch 数据同步

---

**开发者**: macios
**创建日期**: 2025-07-11
**最后更新**: 2025-09-10
