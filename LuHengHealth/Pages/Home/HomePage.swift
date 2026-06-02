import SwiftUI
import UIKit

// 扩展Color，添加转换为RGB值的方法
extension Color {
    // 将Color转换为RGB值(0-255范围)
    func toRGB() -> (red: UInt8, green: UInt8, blue: UInt8) {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let red = UInt8(min(max(components[0], 0), 1) * 255.0)
        let green = UInt8(min(max(components.count > 1 ? components[1] : 0, 0), 1) * 255.0)
        let blue = UInt8(min(max(components.count > 2 ? components[2] : 0, 0), 1) * 255.0)
        return (red, green, blue)
    }
}

struct HomePage: View {
    @State private var previewColor: Color = .clear
    @State private var selectedColor: Color = .orange
    @State private var brightnessValue: Double = 1.0
    @State private var ModelColor: Color = .white
    @State var ModelBackground : Color = .clear
    @State private var showProductDisplay: Bool = false
    @State private var isBreathingMode: Bool = false
    @State private var breathingTimer: Timer?
    @State private var originalBrightness: Double = 1.0
    @State private var mode: UInt8 = 1
    
    // 用于限频（节流）的定时器：最多每 100ms 发送一次
    @State private var throttleTimer: DispatchSourceTimer?
    private let throttleInterval: TimeInterval = 0.1 // 100ms节流间隔
    // 待发送的最新快照（拖动频繁变化时只保留最新一份）
    @State private var pendingSnapshot: (color: Color, brightness: Double, mode: UInt8)?
    // 最近一次真正发送的时间，用于实现 leading 立即发送
    @State private var lastSendTime: Date? = nil
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject var viewModel: BLEViewModel //环境中获取BLEViewModel
    
    var body: some View {
        GeometryReader { geo in
            let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
            let bottomPadding: CGFloat = DeviceType.current == .iPad ? 400 : 100
            ZStack(alignment: .top) {
                Image("3DModelbackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: ResponsiveSpacing.vertical(config)) {
                        // MARK:  - 产品展示
                        VStack(spacing: ResponsiveSpacing.vertical(config)) {
                            // 产品展示标题
                            HStack {
                                Text("产品展示")
                                    .font(ResponsiveFont.title(config))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding(.horizontal, ResponsiveSpacing.horizontal(config))
                            
                            //电量和状态信息
                            HStack(spacing: DeviceType.current == .iPad ? 12 : 8) {
                                Text(viewModel.connectedDevices.first?.name != nil ? "设备已连接" : "设备未连接")
                                    .font(ResponsiveFont.body(config))
                                    .foregroundColor(.black)
                                Text("电量")
                                    .font(ResponsiveFont.body(config))
                                    .foregroundColor(.black)
                                RoundedRectangle(cornerRadius: DeviceType.current == .iPad ? 6 : 4)
                                    .stroke(Color.orange, lineWidth: DeviceType.current == .iPad ? 2 : 1.5)
                                    .frame(width: DeviceType.current == .iPad ? 80 : 60, height: DeviceType.current == .iPad ? 28 : 20)
                                    .overlay(
                                        Text("\(viewModel.connectedDevices.first != nil ? (viewModel.batteryVoltage ?? 0) : 0)%")
                                            .font(.system(size: DeviceType.current == .iPad ? 16 : 14, weight: .bold))
                                            .foregroundColor(.black)
                                    )
                                
                                Spacer()
                                // 右侧AR和链接按钮
                                HStack(spacing: DeviceType.current == .iPad ? 40 : 30) {
                                    VStack(spacing: DeviceType.current == .iPad ? 6 : 4) {
                                        Image(systemName: "arkit")
                                            .font(.system(size: DeviceType.current == .iPad ? 28 : 20))
                                            .foregroundColor(.gray)
                                        Text("AR")
                                            .font(.system(size: DeviceType.current == .iPad ? 16 : 12))
                                            .foregroundColor(.gray)
                                    }
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            showProductDisplay = true
                                        }
                                    }) {
                                        VStack(spacing: DeviceType.current == .iPad ? 6 : 4) {
                                            Image(systemName: "link")
                                                .font(.system(size: DeviceType.current == .iPad ? 28 : 20))
                                                .foregroundColor(.gray)
                                            Text("链接")
                                                .font(.system(size: DeviceType.current == .iPad ? 16 : 12))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, ResponsiveSpacing.horizontal(config))
                            
                            Model3DView(ModelColor: $ModelColor, brightness: $brightnessValue)
                                .frame(height: DeviceType.current == .iPad ? geo.size.height * 0.4 : geo.size.height * 0.3)
                            
                        }
                        
                        // MARK:  - 快速调节
                        VStack(spacing: ResponsiveSpacing.vertical(config)) {
                            HStack {
                                Text("快速调节")
                                    .font(ResponsiveFont.title(config))
                                    .foregroundColor(.black)
                                Spacer()
                                ZStack {
                                    Text("更多颜色 >")
                                        .font(ResponsiveFont.body(config))
                                        .foregroundColor(.gray)
                                        .frame(width: DeviceType.current == .iPad ? 120 : 80, height: DeviceType.current == .iPad ? 50 : 40)
                                        .allowsHitTesting(false) // 让文字不接收点击
                                    
                                    ColorPicker("", selection: $ModelColor)
                                        .frame(width: 80, height: 40)
                                        .scaleEffect(2)
                                        .labelsHidden()
                                        .opacity(0.010001)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            HStack(alignment: .center, spacing: 20) {
                                // 颜色轮区域
                                VStack {
                                    ColorControlPanel(
                                        brightness: $brightnessValue,
                                        selectedColor: $ModelColor,
                                        slot0R: $viewModel.slot0R,
                                        slot0G: $viewModel.slot0G,
                                        slot0B: $viewModel.slot0B,
                                        slot1R: $viewModel.slot1R,
                                        slot1G: $viewModel.slot1G,
                                        slot1B: $viewModel.slot1B,
                                        slot2R: $viewModel.slot2R,
                                        slot2G: $viewModel.slot2G,
                                        slot2B: $viewModel.slot2B,
                                        currentSlot: $viewModel.lightCurrentSlot,
                                        onSlotTapped: { slotIndex in
                                            // 点击灯光槽按钮时，切换到对应灯光槽
                                            viewModel.switchLightSlot(slot: slotIndex)
                                        }
                                    )
                                    .offset(x:0 ,y:0)
                                    .frame(width: geo.size.width * 0.6)
                                    // 颜色或亮度任意变化，都发送当前值
                                    .onChange(of: ModelColor) { _ in
                                        sendCurrentColorWithBrightness()
                                    }
                                    .onChange(of: brightnessValue) { _ in
                                        sendCurrentColorWithBrightness()
                                    }
                                }
                                
                                // 右侧模式选择
                                VStack(spacing: 15) {
                                    // 呼吸模式
                                    VStack(spacing: 8) {
                                        Button(action: { BreathMode()
                                            
                                        }) {
                                            Image("wave")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 90)
                                                .offset(x:-12,y:0)
                                                .overlay(
                                                    Circle()
                                                        .stroke(isBreathingMode ? Color.cyan : Color.cyan.opacity(0.3), lineWidth: 2) // 呼吸模式时高亮
                                                )
                                        }
                                        .buttonStyle(.plain) // 去掉系统默认的高亮样式
                                        
                                        Text("呼吸模式")
                                            .font(.system(size: 12))
                                            .foregroundColor(isBreathingMode ? .cyan : .black)
                                    }
                                    
                                    // 场景切换
                                    VStack(spacing: 8) {
                                        
                                        // 模拟风景图片
                                        Image("cir11")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 5) // 外圈描边
                                            )
                                        
                                        
                                        HStack {
                                            Image(systemName: "chevron.left")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            Text("场景切换")
                                                .font(.system(size: 12))
                                                .foregroundColor(.black)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .offset(x: geo.size.width * 0.05 )
                            }
                            .padding(.horizontal, 20)
                        }
                        // MARK:  - 智能推荐
                        VStack(spacing: ResponsiveSpacing.vertical(config)) {
                            HStack {
                                Text("智能推荐")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                                NavigationLink(destination: InspirationLibraryPage()) {
                                    Text("灵感库 >")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 25)
                            
                            //卡片页面
                            SmartRecommendationView(modelColor: $ModelColor)
                                .frame(height: 150)
        
                        }
                        // 底部缓冲，防止横屏/安全区导致滚不到底
                        Spacer()
                    }
                    .background(Color.clear)
                    .frame(maxWidth: .infinity)
                }

                .safeAreaInset(edge: .bottom) {
                    // 为底部自定义 mytabbar 预留空间，避免内容被遮挡
                    Color.clear.frame(height: tabBarReservedHeight() + bottomPadding)
                }
                .overlay(
                    Group {
                        if showProductDisplay {
                            VisualEffectBlur(style: .systemUltraThinMaterialDark)
                                
                                .transition(.opacity)
                        }
                    }
                )
                .allowsHitTesting(!showProductDisplay)
                
                // 朦胧模糊层（仅在弹出时显示）- 放在内容之后以便模糊生效
                if showProductDisplay {
                    VisualEffectBlur(style: .systemUltraThinMaterialDark)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                    Color.clear.opacity(0.1)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)
                }
                // 悬浮的 ProductDisplayView（不使用 sheet）
                if showProductDisplay {
                    ProductDisplayView(modelBackground: $ModelBackground, modelColor: $ModelColor, onClose: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showProductDisplay = false
                        }
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.top, 80)
                    .zIndex(2)
                }
            }
            
        }
        .onDisappear {
            // 视图消失时停止呼吸模式
            stopBreathingMode()
            // 停止节流定时器
            stopThrottleTimer()
        }
        
    }
    
    func BreathMode()
    {
        if isBreathingMode {
            // 如果已经在呼吸模式，则停止
            stopBreathingMode()
        } else {
            // 开始呼吸模式
            startBreathingMode()
        }
    }
    
    private func startBreathingMode() {
        isBreathingMode = true
        mode = 2
                // 在呼吸模式下，使用模式值2表示呼吸效果
        sendCurrentColorWithBrightness()
            
        
    }
    
    private func stopBreathingMode() {
        isBreathingMode = false
        // 关闭呼吸模式，使用模式值1表示普通效果
        mode = 1
        sendCurrentColorWithBrightness()
    }
    
    // 兼容旧调用名：实际走节流
    private func sendCurrentColorWithBrightness() {
        enqueueCurrentSnapshotForThrottle()
    }
    // 将当前颜色/亮度/模式入队（节流发送）
    private func enqueueCurrentSnapshotForThrottle() {
        let snap = (color: ModelColor, brightness: brightnessValue, mode: mode)
        let now = Date()
        // 若上次发送时间为空或已超过节流间隔，则立即发送（leading）
        if let last = lastSendTime, now.timeIntervalSince(last) < throttleInterval {
            // 仍在节流窗口内：只更新待发快照，等待 trailing 定时器发送
            pendingSnapshot = snap
            ensureThrottleTimer()
            return
        }
        // 立即发送当前快照，并记录发送时间
        sendSnapshotImmediately(snap)
        lastSendTime = now
        // 确保有定时器存在用于处理窗口内的 trailing 快照
        ensureThrottleTimer()
    }

    // 确保有一个重复触发的定时器在跑（最多每 throttleInterval 触发一次发送）
    private func ensureThrottleTimer() {
        guard throttleTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: throttleInterval)
        timer.setEventHandler {
            // 定时尝试把最新一份快照发出去
            flushPendingSnapshot()
        }
        throttleTimer = timer
        timer.resume()
    }

    // 立即发送一帧（用于 leading 触发，不清空 pendingSnapshot）
    private func sendSnapshotImmediately(_ snap: (color: Color, brightness: Double, mode: UInt8)) {
        let rgb = snap.color.toRGB()
        let brightnessUInt16 = UInt16(snap.brightness * 400)
        viewModel.writeRGBControlToFFE3(
            red: rgb.red,
            green: rgb.green,
            blue: rgb.blue,
            mode: snap.mode,
            brightness: brightnessUInt16
        )
    }

    // 主动停止定时器（退出页面时调用）
    private func stopThrottleTimer() {
        throttleTimer?.cancel()
        throttleTimer = nil
        pendingSnapshot = nil
        lastSendTime = nil
    }

    // 执行一次实际发送：仅在节流窗口结束时（trailing）发送并清空
    private func flushPendingSnapshot() {
        guard let snap = pendingSnapshot else { return }
        let now = Date()
        // 仅当距离上次发送已超过节流间隔时才发送 trailing
        if let last = lastSendTime, now.timeIntervalSince(last) < throttleInterval {
            return
        }
        sendSnapshotImmediately(snap)
        lastSendTime = now
        pendingSnapshot = nil
    }


}




// 预览代码
#Preview {
    HomePage()
        .environmentObject(DeviceState())
}

