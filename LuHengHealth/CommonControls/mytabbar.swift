//
//  ContentView.swift
//  CustomTabBar2
//
//
//

import SwiftUI
// MARK: - 枚举定义所有 Tab 类型，对应系统图标名称macbook.and.ipad
enum Tab: String, CaseIterable {
    case Home = "house.fill"
    case Health = "bolt.heart"
    case Device = "ipad.and.iphone"
    case Sport = "figure.run"
    case Account = "person.crop.circle"
}

func tabName(for tab: Tab) -> String {
    switch tab {
    case .Home: return "首页"
    case .Health: return "健康"
    case .Device: return "设备"
    case .Sport: return "运动"
    case .Account: return "我的"
    }
}

struct mytabbaar: View {
    //当前选中标签页
    @State var currentTab : Tab = .Home
    
    //用于动画匹配效果的命名空间
    @Namespace var animation
    
    //当前按钮的 x 坐标，用于控制曲线位置
    @State var currentXValue: CGFloat = 0
    //导航栏顶部突出高度
    @State private var centerCurveHeight: CGFloat = 20
    //控制按钮：弹出窗口
    @State private var showControlSheet = false
    //记录点击窗口
    @State private var previousTab: Tab = .Home
    // 初始化：隐藏原生 TabBar
    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        // 主视图区域：根据 currentTab 显示对应页面
        TabView(selection: $currentTab) {
            NavigationStack {
                HomeView()
            }
            .tag(Tab.Home)
            
            NavigationStack {
                HealthView()
            }
            .tag(Tab.Health)
            NavigationStack {
                DeviceView()
            }
            .tag(Tab.Device)
            
            NavigationStack {
                SportView()
            }
            .tag(Tab.Sport)
            
            NavigationStack {
                AccountView()
            }
            .tag(Tab.Account)
        }
        // 覆盖添加自定义底部导航栏
        .overlay(
            HStack(spacing: 0) {
                // 遍历每个 tab，绘制按钮
                ForEach(Tab.allCases, id: \.rawValue) { tab in
                    TabButton(tab: tab)
                }
            }
                .padding(.vertical)
            //preview wont show sagearea...
                .padding(.bottom, getSafeArea().bottom == 0 ? 10 : (getSafeArea().bottom - 10))
                .background(

                    BottomCurveShape(
                           currentXValue: currentXValue,
                           hideCenterCurve: currentTab == .Device,
                           centerCurveHeight: centerCurveHeight
                       )
                       .fill(Color.white) // 填充为纯白色
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: -2) // 阴影
                    
                )
            
            ,alignment: .bottom
        )

        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            UITabBar.appearance().isHidden = true
        }
        .onDisappear {
            UITabBar.appearance().isHidden = false
        }

        .onChange(of: currentTab) { newTab in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                updateXValue(for: newTab)
            }
        }
        
    }
    // MARK: - 根据当前 Tab 计算中间曲线位置
    func updateXValue(for tab: Tab) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }

        let tabCount = CGFloat(Tab.allCases.count)
        let index = CGFloat(Tab.allCases.firstIndex(of: tab) ?? 0)
        let buttonWidth = window.bounds.width / tabCount
        let midX = buttonWidth * index + buttonWidth / 2

        withAnimation(.spring()) {
            currentXValue = midX
        }
    }
    
    // MARK: - 自定义 Tab 按钮
    @ViewBuilder
    func TabButton(tab: Tab) -> some View {
        //sine we need xaxis value for curve
        GeometryReader {proxy in
            Button {
                // 点击切换 tab，并更新曲线位置
                withAnimation(.spring()) {
                    currentTab = tab
                    previousTab = currentTab
                    currentXValue = proxy.frame(in: .global).midX
                    centerCurveHeight = (tab == .Device) ? 0 : 20  //
                }
                
                // 弹窗逻辑：如果点击的是“控制”，就弹窗
//                if tab == .Device {
//                    withAnimation {
//                        showControlSheet = true
//                        previousTab = .Home
//                    }
//                }
            }
            label: {
                //moving button up for  current tab...
                VStack {
                    Image(systemName: tab.rawValue)
                    //since we need perfect value for curve..
                        .resizable()
                        .aspectRatio( contentMode: .fit)
                        .frame(width: 25, height: 25)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(currentTab == tab ? Color.yellow : Color.black)
                        .padding(currentTab == tab ? 15 : 0)
                        .background(
                            ZStack {
                                if currentTab == tab {
                                    // 当前选中按钮高亮圆形背景 + 动画匹配
                                    Circle()
                                        .fill(Color.white.opacity(1)) // 背景色和透明度
                                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3) // 阴影
                                        .matchedGeometryEffect(id: "CustomTabBar2", in: animation)
                                }
                            }
                        )
                    // 中间图片上浮
//                        .offset(y: currentTab == tab ? -50 : (tab == .Device ? -20 : 0))
                        .offset(y: currentTab == tab ? -50 : 0)
                    // 添加文本标签
                    Text(tabName(for: tab))
                        .font(.caption2)
                        .foregroundColor(currentTab == tab ? Color.yellow : Color.black)
                        .opacity(currentTab == tab ? 1 : 0.8)
//                        .offset(y: currentTab == tab ? -20 : (tab == .Device ? -20 : 0)) //中间文本上浮
                        .offset(y: currentTab == tab ? -20 : 0)
                }
                .contentShape(Rectangle())
            }
            // 初始设置曲线位置（首次加载）
            .onAppear{
                if tab == .Home && currentXValue == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        currentXValue = proxy.frame(in: .global).midX
                    }
                }
            }
        }
        .frame(height: 30)
        //maxsize...
        
    }
    
}

// MARK: - 毛玻璃封装视图
struct BlurEffect: UIViewRepresentable {
    
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        
    }
}

// MARK: - 获取设备安全区域
func getSafeArea() -> UIEdgeInsets {
    let safeArea = getWindow().safeAreaInsets
    return safeArea
}

// MARK: - 统一底部栏预留高度（供各页面使用）
func tabBarReservedHeight() -> CGFloat {
    // 与自定义底部栏高度保持一致：栏体高度 + 安全区
    // 当前各页历史使用 getSafeArea().bottom + 200，这里集中计算
    return getSafeArea().bottom + 200
}

// MARK: - 统一顶部导航/标题预留间距
func topBarReservedPadding(_ extra: CGFloat = 10) -> CGFloat {
    return getSafeArea().top + extra
}

// MARK: - 获取当前窗口
func getWindow() -> UIWindow {
    guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        return .init()
    }
    guard let window = screen.windows.first else {
        return .init()
    }
    return window
}

// MARK: - 自定义底部曲线路径 Shape
struct BottomCurveShape: Shape {
    var currentXValue: CGFloat// 当前按钮中心位置
    var hideCenterCurve: Bool = false
    var centerCurveHeight: CGFloat = 20  // 新增
    // 允许动画驱动变化
    // 添加动画支持（多个变量）
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(currentXValue, centerCurveHeight) }
        set {
            currentXValue = newValue.first
            centerCurveHeight = newValue.second
        }
    }
    func path(in rect: CGRect) -> Path {
        return Path { path in
            // 整个矩形框路径
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            
            // 顶部中间曲线（凹槽）起点
            let mid = currentXValue
            path.move(to: CGPoint(x: mid - 50, y: 0))
            // 第一段贝塞尔曲线（左半）
            let to1 = CGPoint(x: mid, y: 35)
            let control1 = CGPoint(x: mid - 25, y: 0)
            let control2 = CGPoint(x: mid - 25, y: 35)
            path.addCurve(to: to1, control1: control1, control2: control2)
            
            // 第二段贝塞尔曲线（右半）
            let to2 = CGPoint(x: mid + 50, y: 0)
            let control3 = CGPoint(x: mid + 25, y: 35)
            let control4 = CGPoint(x: mid + 25, y: 0)
            path.addCurve(to: to2, control1: control3, control2: control4)
            

        }
    }
}



#Preview {
    mytabbaar()
}

