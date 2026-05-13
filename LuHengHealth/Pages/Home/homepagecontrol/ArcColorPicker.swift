import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ArcColorPicker
// 可拖拽的半圆彩虹色环选择器，含指针与迷你色环
public struct ArcColorPicker: View {
    // 0...1 表示从左端(红)到右端(红)的进度
    @Binding public var value: Double

    // 外观可调参数
    public var ringLineWidth: CGFloat
    public var showsMiniDial: Bool
    public var backgroundGradient: LinearGradient
    public var needleColor: Color

    // 回调：颜色变化
    public var onChange: (Color) -> Void

    @State private var isDragging: Bool = false
    @State private var startedOnRing: Bool = false

    // 可选的双绑定：拖拽时更新 preview，结束时写入 selected
    private var previewColorBinding: Binding<Color>? = nil
    private var selectedColorBinding: Binding<Color>? = nil
    private var previewRGBBinding: Binding<RGB>? = nil
    private var selectedRGBBinding: Binding<RGB>? = nil

    // 角度定义：半圆从 180°(左) 到 360°/0°(右)
    private let startAngle: Angle = .degrees(180)
    private let endAngle: Angle = .degrees(0)

    public init(
        value: Binding<Double>,
        ringLineWidth: CGFloat = 28,
        showsMiniDial: Bool = true,
        backgroundGradient: LinearGradient = LinearGradient(
            colors: [.clear, .clear],
            startPoint: .top,
            endPoint: .bottom
        ),
        needleColor: Color = Color(.sRGB, red: 0.85, green: 0.76, blue: 0.62, opacity: 1.0),
        onChange: @escaping (Color) -> Void = { _ in }
    ) {
        self._value = value
        self.ringLineWidth = ringLineWidth
        self.showsMiniDial = showsMiniDial
        self.backgroundGradient = backgroundGradient
        self.needleColor = needleColor
        self.onChange = onChange
    }

    // 以 Color 绑定驱动：外部读写为 Color，内部转换为色相进度 0...1
    public init(
        color: Binding<Color>,
        ringLineWidth: CGFloat = 28,
        showsMiniDial: Bool = true,
        backgroundGradient: LinearGradient = LinearGradient(
            colors: [.clear, .clear],
            startPoint: .top,
            endPoint: .bottom
        ),
        needleColor: Color = Color(.sRGB, red: 0.85, green: 0.76, blue: 0.62, opacity: 1.0),
        onChange: @escaping (Color) -> Void = { _ in }
    ) {
        self.ringLineWidth = ringLineWidth
        self.showsMiniDial = showsMiniDial
        self.backgroundGradient = backgroundGradient
        self.needleColor = needleColor
        self.onChange = onChange

        // 颜色 <-> 进度 的桥接绑定
        self._value = Binding<Double>(
            get: {
                color.wrappedValue.hueComponent ?? 0
            },
            set: { newHue in
                let newColor = Color(hue: newHue.clamped(to: 0...1), saturation: 1.0, brightness: 1.0)
                color.wrappedValue = newColor
                onChange(newColor)
            }
        )
    }

    // NewColourWheel 风格：预览与最终颜色双绑定
    public init(
        previewColor: Binding<Color>,
        selectedColor: Binding<Color>,
        ringLineWidth: CGFloat = 28,
        showsMiniDial: Bool = true,
        backgroundGradient: LinearGradient = LinearGradient(
            colors: [.clear, .clear],
            startPoint: .top,
            endPoint: .bottom
        ),
        needleColor: Color = Color(.sRGB, red: 0.85, green: 0.76, blue: 0.62, opacity: 1.0),
        onChange: @escaping (Color) -> Void = { _ in }
    ) {
        self.ringLineWidth = ringLineWidth
        self.showsMiniDial = showsMiniDial
        self.backgroundGradient = backgroundGradient
        self.needleColor = needleColor
        self.onChange = onChange
        self.previewColorBinding = previewColor
        self.selectedColorBinding = selectedColor

        // 以预览颜色的色相驱动进度
        self._value = Binding<Double>(
            get: {
                previewColor.wrappedValue.hueComponent ?? 0
            },
            set: { newHue in
                let newColor = Color(hue: newHue.clamped(to: 0...1), saturation: 1.0, brightness: 1.0)
                previewColor.wrappedValue = newColor
                onChange(newColor)
            }
        )
    }

    // NewColourWheel 风格（RGB 版）：预览与最终颜色双绑定，输出为 RGB(r:g:b)
    init(
        previewRGB: Binding<RGB>,
        selectedRGB: Binding<RGB>,
        ringLineWidth: CGFloat = 28,
        showsMiniDial: Bool = true,
        backgroundGradient: LinearGradient = LinearGradient(
            colors: [.clear, .clear],
            startPoint: .top,
            endPoint: .bottom
        ),
        needleColor: Color = Color(.sRGB, red: 0.85, green: 0.76, blue: 0.62, opacity: 1.0),
        onChange: @escaping (Color) -> Void = { _ in }
    ) {
        self.ringLineWidth = ringLineWidth
        self.showsMiniDial = showsMiniDial
        self.backgroundGradient = backgroundGradient
        self.needleColor = needleColor
        self.onChange = onChange
        self.previewRGBBinding = previewRGB
        self.selectedRGBBinding = selectedRGB

        // 以预览 RGB 的色相驱动进度
        self._value = Binding<Double>(
            get: {
                Double(previewRGB.wrappedValue.hsv.h / 360.0)
            },
            set: { newHue in
                let hsv = HSV(h: CGFloat(newHue.clamped(to: 0...1) * 360.0), s: 1, v: 1)
                let rgb = hsv.rgb
                previewRGB.wrappedValue = rgb
                onChange(Color(red: rgb.r, green: rgb.g, blue: rgb.b))
            }
        )
    }

    // 当前选中颜色（HSV：色相=进度）
    private var selectedColor: Color {
        Color(hue: value.clamped(to: 0...1), saturation: 1.0, brightness: 1.0)
    }

    // 彩虹渐变（首尾同色收口）
    private var rainbowGradient: AngularGradient {
        let stops: [Gradient.Stop] = stride(from: 0.0, through: 1.0, by: 0.1).map { t in
            Gradient.Stop(color: Color(hue: t, saturation: 1.0, brightness: 1.0), location: t)
        }
        // 关键：让角向渐变从 360°(右端，红) 走到 180°(左端，红)。
        // 这样位置角度映射 f = (360 - θ)/180 与 value 完全一致，指针颜色与色环颜色一一对应。
        return AngularGradient(gradient: Gradient(stops: stops), center: .center, startAngle: .degrees(360), endAngle: .degrees(180))
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            // 大半圆：以底边中点为圆心
            let radius = max(0, min(size.width / 2.0, size.height - ringLineWidth * 1.5))
            let ringCenter = CGPoint(x: size.width / 2.0, y: radius + ringLineWidth)
            let ringDiameter = radius * 2.0
            let bigFrameHeight = radius + ringLineWidth

            ZStack {
                backgroundGradient

                // 大色环
                // 用整圆渐变 + 半圆描边遮罩，确保角向渐变以真正圆心为基准
                Circle()
                    .stroke(rainbowGradient, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                    .frame(width: ringDiameter, height: ringDiameter)
                    .position(ringCenter)
                    .mask(
                        SemiCircularArc()
                            .stroke(style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                            .frame(width: ringDiameter, height: bigFrameHeight)
                            .position(x: ringCenter.x, y: ringCenter.y - bigFrameHeight / 2.0)
                    )

                // 中心指针
                let thumbDiameter = max(22, ringLineWidth * 0.9)
                NeedleView(center: ringCenter,
                           radius: radius,
                           angle: angleForValue(value),
                           color: needleColor,
                           thickness: max(4, ringLineWidth * 0.18),
                           showsHead: true,
                           headScale: 2.4,
                           extraRetreat: max(6, thumbDiameter * 0.3))

                // 拇指圆点
                ThumbView(point: pointOnCircle(center: ringCenter, radius: radius, angle: angleForValue(value)),
                          fill: selectedColor,
                          strokeColor: .white,
                          diameter: max(22, ringLineWidth * 0.9),
                          strokeWidth: 3)

                // 迷你色环 + 小指针
                if showsMiniDial {
                    let miniRadius = radius * 0.28
                    let miniCenter = ringCenter // 与大色环同圆心
                    let miniDiameter = miniRadius * 2.0
                    let miniFrameHeight = miniRadius + ringLineWidth

                    Circle()
                        .stroke(rainbowGradient, style: StrokeStyle(lineWidth: ringLineWidth * 0.5, lineCap: .round))
                        .frame(width: miniDiameter, height: miniDiameter)
                        .position(miniCenter)
                        .mask(
                            SemiCircularArc()
                                .stroke(style: StrokeStyle(lineWidth: ringLineWidth * 0.5, lineCap: .round))
                                .frame(width: miniDiameter, height: miniFrameHeight)
                                .position(x: miniCenter.x, y: miniCenter.y - miniFrameHeight / 2.0)
                        )

                    ThumbView(point: pointOnCircle(center: miniCenter,
                                                    radius: miniRadius,
                                                    angle: angleForValue(value)),
                              fill: selectedColor,
                              strokeColor: .white,
                              diameter: max(14, ringLineWidth * 0.55),
                              strokeWidth: 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        // 第一次触发时判断是否从色环区域开始
                        if !isDragging {
                            let onRing: Bool
                            if showsMiniDial {
                                let miniRadius = radius * 0.28
                                let miniWidth = ringLineWidth * 0.5
                                onRing = isPointInAnyRingArea(gesture.location,
                                                              center: ringCenter,
                                                              bigRadius: radius,
                                                              bigLineWidth: ringLineWidth,
                                                              miniRadius: miniRadius,
                                                              miniLineWidth: miniWidth,
                                                              tolerance: 10)
                            } else {
                                onRing = isPointInRingArea(gesture.location,
                                                           center: ringCenter,
                                                           radius: radius,
                                                           lineWidth: ringLineWidth,
                                                           tolerance: 10)
                            }
                            startedOnRing = onRing
                        }
                        isDragging = true

                        guard startedOnRing else { return }

                        let newValue = valueForLocation(gesture.location, center: ringCenter)
                        if newValue != value {
                            value = newValue
                            // 实时预览
                            if let previewBinding = previewColorBinding {
                                previewBinding.wrappedValue = selectedColor
                            }
                            if let previewRGB = previewRGBBinding {
                                let rgb = HSV(h: CGFloat(value.clamped(to: 0...1) * 360.0), s: 1, v: 1).rgb
                                previewRGB.wrappedValue = rgb
                            }
                            onChange(selectedColor)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        startedOnRing = false
                        // 拖拽结束，确认颜色
                        if let selectedBinding = selectedColorBinding {
                            if let previewBinding = previewColorBinding {
                                selectedBinding.wrappedValue = previewBinding.wrappedValue
                            } else {
                                selectedBinding.wrappedValue = selectedColor
                            }
                        }
                        if let selectedRGB = selectedRGBBinding {
                            if let previewRGB = previewRGBBinding {
                                selectedRGB.wrappedValue = previewRGB.wrappedValue
                            } else {
                                let rgb = HSV(h: CGFloat(value.clamped(to: 0...1) * 360.0), s: 1, v: 1).rgb
                                selectedRGB.wrappedValue = rgb
                            }
                        }
                    }
            )
            // 与外部按钮联动：当外部“最终颜色”变化时，自动同步到预览颜色，从而驱动指针位置
            .background(
                Group {
                    if let selectedBinding = selectedColorBinding, let previewBinding = previewColorBinding {
                        Color.clear
                            .onChange(of: selectedBinding.wrappedValue) { newColor in
                                // 拖拽中不覆盖用户手势；非拖拽时与外部保持同步
                                if !isDragging {
                                    previewBinding.wrappedValue = newColor
                                }
                            }
                    }
                    if let selectedRGB = selectedRGBBinding, let previewRGB = previewRGBBinding {
                        Color.clear
                            .onChange(of: selectedRGB.wrappedValue) { newRGB in
                                if !isDragging {
                                    previewRGB.wrappedValue = newRGB
                                }
                            }
                    }
                }
            )
        }
    }

    // MARK: - 角度/点位计算
    private func angleForValue(_ t: Double) -> Angle {
        // t: 0(右) -> 1(左)，映射到 360° -> 180°
        let deg = 360.0 - (t.clamped(to: 0...1) * 180.0)
        return .degrees(deg)
    }

    private func valueForLocation(_ location: CGPoint, center: CGPoint) -> Double {
        // 将触点转换为从 +X 轴起的 0...360° 角度
        let dx = location.x - center.x
        let dy = location.y - center.y
        var deg = atan2(dy, dx) * 180.0 / .pi
        if deg < 0 { deg += 360.0 }

        // 只允许上半圆(180...360)，其他区域就就近吸附
        if deg < 180.0 {
            // wrap 容差：在右端(0°/360°)附近时应吸附到 360°，避免跳到 180°
            let wrapTolerance: Double = 4.0
            if deg <= wrapTolerance { deg = 360.0 } else { deg = 180.0 }
        }
        if deg > 360.0 { deg = 360.0 }

        // 进度 0...1：右端为 0，左端为 1
        let t = (360.0 - deg) / 180.0
        return t.clamped(to: 0...1)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let rad = CGFloat(angle.radians)
        let x = center.x + radius * cos(rad)
        let y = center.y + radius * sin(rad)
        return CGPoint(x: x, y: y)
    }

    private func isPointInRingArea(_ point: CGPoint,
                                   center: CGPoint,
                                   radius: CGFloat,
                                   lineWidth: CGFloat,
                                   tolerance: CGFloat) -> Bool {
        let dx = point.x - center.x
        let dy = point.y - center.y
        var deg = atan2(dy, dx) * 180.0 / .pi
        if deg < 0 { deg += 360.0 }
        // 仅上半圆
        guard deg >= 180.0 && deg <= 360.0 else { return false }

        let distance = sqrt(dx * dx + dy * dy)
        let inner = radius - lineWidth / 2.0 - tolerance
        let outer = radius + lineWidth / 2.0 + tolerance
        return distance >= inner && distance <= outer
    }

    private func isPointInAnyRingArea(_ point: CGPoint,
                                      center: CGPoint,
                                      bigRadius: CGFloat,
                                      bigLineWidth: CGFloat,
                                      miniRadius: CGFloat,
                                      miniLineWidth: CGFloat,
                                      tolerance: CGFloat) -> Bool {
        return isPointInRingArea(point, center: center, radius: bigRadius, lineWidth: bigLineWidth, tolerance: tolerance)
        || isPointInRingArea(point, center: center, radius: miniRadius, lineWidth: miniLineWidth, tolerance: tolerance)
    }
}

// MARK: - 形状与小部件

// 上半圆 InsettableShape，圆心位于容器底部中心
fileprivate struct SemiCircularArc: InsettableShape {
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height * 2.0) / 2.0 - insetAmount
        var p = Path()
        p.addArc(center: center,
                 radius: max(0, radius),
                 startAngle: .degrees(180),
                 endAngle: .degrees(0),
                 clockwise: false)
        return p
    }
}

fileprivate struct ThumbView: View {
    var point: CGPoint
    var fill: Color
    var strokeColor: Color
    var diameter: CGFloat
    var strokeWidth: CGFloat

    var body: some View {
        Circle()
            .fill(fill)
            .overlay(
                Circle().stroke(strokeColor, lineWidth: strokeWidth)
            )
            .frame(width: diameter, height: diameter)
            .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
            .position(point)
    }
}

fileprivate struct NeedleView: View {
    var center: CGPoint
    var radius: CGFloat
    var angle: Angle
    var color: Color
    var thickness: CGFloat
    var showsHead: Bool = false
    var headScale: CGFloat = 1.0
    var extraRetreat: CGFloat = 0

    var body: some View {
        let r = CGFloat(angle.radians)
        let ux = cos(r)
        let uy = sin(r)
        let tip = CGPoint(
            x: center.x + radius * ux,
            y: center.y + radius * uy
        )
        let headSize = max(10, thickness * 1.6 * headScale)
        // 用线段到 tip 的长度恰好等于箭头底边中心到尖端的距离，避免角度变化产生视差
        let headCenter = CGPoint(
            x: tip.x - (headSize * 0.5 + extraRetreat) * ux,
            y: tip.y - (headSize * 0.5 + extraRetreat) * uy
        )

        return ZStack {
            Path { p in
                p.move(to: center)
                // 线段终点与箭头底部对齐，避免箭头覆盖过长
                p.addLine(to: headCenter)
            }
            .stroke(color.opacity(0.9), style: StrokeStyle(lineWidth: thickness, lineCap: .round))

            if showsHead {
                ArrowHead()
                    .fill(color.opacity(0.95))
                    .frame(width: headSize, height: headSize)
                    .rotationEffect(angle, anchor: .center)
                    .position(headCenter)
            }
        }
    }
}

fileprivate struct ArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 默认朝向：指向 +X（右）
        // 顶点：右侧中点；底边：左上 & 左下
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - 工具扩展
fileprivate extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

fileprivate extension Color {
    // 从 Color 提取色相(0...1)，若无法解析则返回 nil
    var hueComponent: Double? {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return Double(h)
        #else
        return nil
        #endif
    }
}

// MARK: - 预览
struct ArcColorPicker_Previews: PreviewProvider {
    struct Demo: View {
        @State private var t: Double = 0.78
        var body: some View {
            VStack(spacing: 24) {
                ArcColorPicker(value: $t) { _ in }
                    .frame(height: 240)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hue: t, saturation: 1, brightness: 1))
                    .frame(height: 44)
                    .overlay(Text("当前色相: \(String(format: "%.0f°", t * 360))").foregroundColor(.white).bold())
                    .padding(.horizontal, 24)
            }
            .padding()
        }
    }

    static var previews: some View {
        Demo()
            .previewLayout(.sizeThatFits)
            .frame(width: 340, height: 320)
    }
}


