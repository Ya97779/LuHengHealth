//
//  AccountPage.swift
//  LuHengHeath
//  我的页面
//  Created by macios on 2025/7/16.
//

import SwiftUI

struct AccountPage: View {
    @EnvironmentObject var userSession: UserSession
    @State private var navOpacity: Double = 0
    var body: some View {
        let bottomPadding: CGFloat = DeviceType.current == .iPad ? 100 : 100
        GeometryReader{geo in
            ZStack(alignment: .top) {
                Image("Appbackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 捕获滚动偏移用于控制导航栏透明度
                        Color.clear
                            .frame(height: 0)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear
                                        .preference(key: ScrollOffsetKey.self, value: proxy.frame(in: .named("AccountScroll")).minY)
                                }
                            )
                        
                        VStack(spacing: 0) {
                            // 用户信息（基于登录用户动态展示）
                            UserProfileSection(profile: userSession.profile)
                                .padding(.top, topBarReservedPadding(6))
                                .padding(.horizontal, 20)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Menu {
                                            Button("切换账号") { userSession.logout() }
                                            Button("退出登录") { userSession.logout() }
                                        } label: {
                                            Image(systemName: "line.3.horizontal")
                                        }
                                    }
                                }
                            
                        }
                        
                        
                        // 白色背景内容区域
                        VStack(spacing: 0) {
                            // SVIP会员卡片
                            SVIPMemberCard()
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            
                            // 功能图标区域
                            FunctionIconsSection()
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            
                            // 商品推荐卡片（轮播）
                            ProductRecommendationCarousel()
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            
                            // 链接区域
                            LinksSection()
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }
                        .padding(.bottom, 400) // 为底部导航栏留空间
                        
                    }
                }
                .coordinateSpace(name: "AccountScroll")
                .onPreferenceChange(ScrollOffsetKey.self) { y in
                    // y 从 0 到负数，向下滚动变为负
                    let progress = max(0, min(1, Double((-y) / 120.0)))
                    navOpacity = progress
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: tabBarReservedHeight() + bottomPadding)
                }
                .background(Color.clear)
                
            }
        }
    }
}


// MARK:  - 组件
// 用户资料区域
private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct UserProfileSection: View {
    let profile: UserProfile?
    @State private var isWalking = true
    
    var body: some View {
        VStack(spacing: 0) {
            // 我的标题和人物插图
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text("我的")
                        .font(.system(size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    // 用户头像
                    ZStack {
                        Circle()
                            .fill(Color.brown.opacity(0.6))
                            .frame(width: 50, height: 50)
                        if let sys = profile?.avatarSystemName {
                            Image(systemName: sys)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 用户昵称和ID
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile?.displayName ?? "未登录")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        
                        HStack(spacing: 4) {
                            Text("ID：\(profile?.userId ?? "-")")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 粉丝和关注
                    HStack(spacing: 20) {
                        Text("粉丝：\(profile?.fansCount ?? 0)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("关注：\(profile?.followingCount ?? 0)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 右侧人物插图
                ZStack {
                    // 彩色背景形状
                    ZStack {
                        
                        
                        Image("dot2")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(0.8)
                            .offset(x: 30, y: -80)
                        Image("dot3")
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(0.8)
                            .offset(x: 20, y: 50)
                        Image("dot1")
                            .resizable()
                            .scaledToFit()
                            .offset(x: -60, y: -40)
                    }
                    
                    // 人物形象（用简单图形代替）
                    Image(isWalking ? "walk" : "run")
                        .resizable()
                        .scaledToFit()
                 
                    
                }
                .frame(width:200 )
            }
            
            // 切换人物状态按钮
            HStack {
                Spacer()
                
                Button(action: {
                    isWalking.toggle()
                }) {
                    HStack(spacing: 4) {
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("切换人物状态")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// SVIP会员卡片
struct SVIPMemberCard: View {
    var body: some View {
        HStack(spacing: 12) {
            // 左侧皇冠图标
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                    .shadow(radius: 2)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
            }
            
            // 中间文字信息
            VStack(alignment: .leading, spacing: 4) {
                Text("SVIP会员")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
                
                Text("开通会员获取更多专享权益")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右侧抢购按钮
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text("点击抢购")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.yellow]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.yellow.opacity(0.2)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(15)
    }
}

// 功能图标区域
struct FunctionIconsSection: View {
    var body: some View {
        HStack(spacing: 0) {
            FunctionIcon(
                icon: "cart.fill",
                title: "商城",
                subtitle: "商品购买入口"
            )
            
            FunctionIcon(
                icon: "doc.text.fill",
                title: "订单",
                subtitle: "我的订单"
            )
            
            FunctionIcon(
                icon: "cube.fill",
                title: "收藏",
                subtitle: "点击查看"
            )
            
            FunctionIcon(
                icon: "star.fill",
                title: "动态",
                subtitle: "查看他人动态"
            )
            
            FunctionIcon(
                icon: "stethoscope",
                title: "问诊",
                subtitle: "AI问诊"
            )
        }
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
    }
}

// 单个功能图标
struct FunctionIcon: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.black)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// 商品推荐卡片
struct ProductRecommendationCard: View {
    let item: ProductItem
    let index: Int
    let currentIndex: Int
    let totalCount: Int
    var body: some View {
        ZStack {
            // 背景风景图片（用渐变代替）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.yellow.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 120)
            .cornerRadius(15)
            
            HStack {
                // 左侧点击购买按钮
                VStack {
                    HStack {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                
                                Image(systemName: "hand.point.right.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // 底部指示器（与轮播联动）
                    HStack(spacing: 8) {
                        ForEach(0..<totalCount, id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex ? Color.orange : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                
                Spacer()
                
                // 右侧商品图片
                RoundedRectangle(cornerRadius: 10)
                    .fill(item.color)
                    .frame(width: 60, height: 60)
            }
            .padding(16)
        }
    }
}

// 商品推荐轮播
struct ProductRecommendationCarousel: View {
    private let items: [ProductItem] = [
        ProductItem(title: "点击购买此商品1 >>", color: Color(red: 0.94, green: 0.78, blue: 0.4)),
        ProductItem(title: "点击购买此商品2 >>", color: Color(red: 0.74, green: 0.68, blue: 0.9)),
        ProductItem(title: "点击购买此商品3 >>", color: Color(red: 0.56, green: 0.82, blue: 0.65))
    ]
    @State private var selection = 0
    
    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $selection) {
                ForEach(items.indices, id: \.self) { idx in
                    ProductRecommendationCard(
                        item: items[idx],
                        index: idx,
                        currentIndex: selection,
                        totalCount: items.count
                    )
                    .tag(idx)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 140)
        }
    }
}

public struct ProductItem: Identifiable, Hashable {
    public let id = UUID()
    let title: String
    let color: Color
}

// 链接区域
struct LinksSection: View {
    var body: some View {
        VStack(spacing: 12) {
            AccountLinkItem(
                icon: "link",
                title: "链接",
                subtitle: "点击进行设备与app链接"
            )
            
            AccountLinkItem(
                icon: "link",
                title: "链接",
                subtitle: "点击进行设备与app链接"
            )
        }
    }
}

// 链接项组件
struct AccountLinkItem: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 左侧图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
            
            // 中间文字
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 右侧箭头
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 30, height: 30)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.clear)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    AccountPage().environmentObject(UserSession())
}
