import SwiftUI

enum ResponsiveFillMode {
    case fit   // 等比缩放，完整显示，可能留边
    case fill  // 分别按宽/高缩放，铺满屏幕，可能轻微形变
}

// 设备类型枚举
enum DeviceType {
    case iPhone
    case iPad
    case mac
    
    static var current: DeviceType {
        #if targetEnvironment(macCatalyst)
        return .mac
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        } else {
            return .iPhone
        }
        #endif
    }
}

// 响应式布局配置
struct ResponsiveConfig {
    let isCompact: Bool
    let isRegular: Bool
    let horizontalSizeClass: UserInterfaceSizeClass
    let verticalSizeClass: UserInterfaceSizeClass
    
    init(horizontal: UserInterfaceSizeClass, vertical: UserInterfaceSizeClass) {
        self.horizontalSizeClass = horizontal
        self.verticalSizeClass = vertical
        self.isCompact = horizontal == .compact || vertical == .compact
        self.isRegular = horizontal == .regular && vertical == .regular
    }
}

// 通用自适应容器：小屏缩放以完整显示，大屏适度放大
struct ResponsiveContainer<Content: View>: View {
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private let baseSize: CGSize
    private let baseCandidates: [CGSize]
    private let fillMode: ResponsiveFillMode
    private let content: () -> Content
    private let adaptiveLayout: Bool
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 1.0,
        baseSize: CGSize = CGSize(width: 390, height: 844),
        baseCandidates: [CGSize] = [
            CGSize(width: 375, height: 812),  // iPhone X/11 Pro
            CGSize(width: 390, height: 844),  // 12/13/14/15 普通
            CGSize(width: 393, height: 852),  // 14 Pro
            CGSize(width: 402, height: 874),  // 16/16 Pro
            CGSize(width: 414, height: 896),  // 11/11 Pro Max/Plus 系列
            CGSize(width: 428, height: 926),  // 12/13/14 Pro Max
            CGSize(width: 430, height: 932),  // 15/16 Pro Max
            CGSize(width: 768, height: 1024), // iPad 9.7"
            CGSize(width: 810, height: 1080), // iPad Air
            CGSize(width: 834, height: 1112), // iPad Pro 10.5"
            CGSize(width: 834, height: 1194), // iPad Pro 11"
            CGSize(width: 1024, height: 1366) // iPad Pro 12.9"
        ],
        fillMode: ResponsiveFillMode = .fit,
        adaptiveLayout: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.baseSize = baseSize
        self.baseCandidates = baseCandidates
        self.fillMode = fillMode
        self.adaptiveLayout = adaptiveLayout
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
            
            // 选择与当前设备最接近纵横比的基线
            let deviceRatio = geo.size.width / max(geo.size.height, 1)
            let chosenBase = baseCandidates.min(by: { a, b in
                let ra = a.width / a.height
                let rb = b.width / b.height
                return abs(deviceRatio - ra) < abs(deviceRatio - rb)
            }) ?? baseSize

            let widthScaleRaw = geo.size.width / chosenBase.width
            let heightScaleRaw = geo.size.height / chosenBase.height
            let widthScale = min(max(widthScaleRaw, minScale), maxScale)
            let heightScale = min(max(heightScaleRaw, minScale), maxScale)
            let uniform = min(max(min(widthScaleRaw, heightScaleRaw), minScale), maxScale)

            Group {
                if adaptiveLayout && DeviceType.current == .iPad {
                    // iPad 自适应布局
                    iPadAdaptiveLayout(config: config, geo: geo) {
                        content()
                    }
                } else {
                    // iPhone 或传统缩放布局
                    switch fillMode {
                    case .fit:
                        content()
                            .scaleEffect(uniform, anchor: .top)
                    case .fill:
                        content()
                            .scaleEffect(x: widthScale, y: heightScale, anchor: .top)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
    
    @ViewBuilder
    private func iPadAdaptiveLayout<C: View>(config: ResponsiveConfig, geo: GeometryProxy, @ViewBuilder content: @escaping () -> C) -> some View {
        if config.isRegular {
            // iPad 横屏或大屏：使用更宽松的布局
            content()
                .scaleEffect(1.0) // 不缩放，保持原始大小
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // iPad 竖屏或紧凑模式：适度缩放
            content()
                .scaleEffect(0.9, anchor: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// 响应式网格布局
struct ResponsiveGrid<Content: View>: View {
    private let columns: [GridItem]
    private let content: () -> Content
    private let adaptiveColumns: Bool
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    init(
        columns: [GridItem]? = nil,
        adaptiveColumns: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.columns = columns ?? [GridItem(.adaptive(minimum: 150))]
        self.adaptiveColumns = adaptiveColumns
        self.content = content
    }
    
    var body: some View {
        let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
        
        LazyVGrid(columns: adaptiveColumns ? adaptiveGridColumns(for: config) : columns, spacing: 16) {
            content()
        }
    }
    
    private func adaptiveGridColumns(for config: ResponsiveConfig) -> [GridItem] {
        switch DeviceType.current {
        case .iPad:
            if config.isRegular {
                // iPad 横屏：更多列
                return [
                    GridItem(.adaptive(minimum: 200, maximum: 300)),
                    GridItem(.adaptive(minimum: 200, maximum: 300)),
                    GridItem(.adaptive(minimum: 200, maximum: 300))
                ]
            } else {
                // iPad 竖屏：较少列
                return [
                    GridItem(.adaptive(minimum: 180, maximum: 250)),
                    GridItem(.adaptive(minimum: 180, maximum: 250))
                ]
            }
        case .iPhone:
            if config.isCompact {
                // iPhone 竖屏：单列
                return [GridItem(.flexible())]
            } else {
                // iPhone 横屏：双列
                return [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
            }
        case .mac:
            return [
                GridItem(.adaptive(minimum: 250, maximum: 400)),
                GridItem(.adaptive(minimum: 250, maximum: 400)),
                GridItem(.adaptive(minimum: 250, maximum: 400)),
                GridItem(.adaptive(minimum: 250, maximum: 400))
            ]
        }
    }
}

// 响应式间距
struct ResponsiveSpacing {
    static func horizontal(_ config: ResponsiveConfig) -> CGFloat {
        switch DeviceType.current {
        case .iPad:
            return config.isRegular ? 40 : 30
        case .iPhone:
            return config.isCompact ? 20 : 30
        case .mac:
            return 50
        }
    }
    
    static func vertical(_ config: ResponsiveConfig) -> CGFloat {
        switch DeviceType.current {
        case .iPad:
            return config.isRegular ? 30 : 25
        case .iPhone:
            return config.isCompact ? 20 : 25
        case .mac:
            return 40
        }
    }
}

// 响应式字体大小
struct ResponsiveFont {
    static func title(_ config: ResponsiveConfig) -> Font {
        switch DeviceType.current {
        case .iPad:
            return config.isRegular ? .system(size: 32, weight: .bold) : .system(size: 28, weight: .bold)
        case .iPhone:
            return config.isCompact ? .system(size: 24, weight: .bold) : .system(size: 28, weight: .bold)
        case .mac:
            return .system(size: 36, weight: .bold)
        }
    }
    
    static func body(_ config: ResponsiveConfig) -> Font {
        switch DeviceType.current {
        case .iPad:
            return config.isRegular ? .system(size: 18) : .system(size: 16)
        case .iPhone:
            return config.isCompact ? .system(size: 14) : .system(size: 16)
        case .mac:
            return .system(size: 20)
        }
    }
}



