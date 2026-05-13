//
//  PlanAndChallengeComponents.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

// MARK: - 计划与挑战内容组件

struct PlanAndChallengeContent: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    var body: some View {
        
        let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
        VStack(spacing: 0) {
            // 计划区域
            VStack(spacing: 0) {
                HStack {
                    Text("计划")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                HStack(spacing: 2) {
                    // 左侧两个小卡片
                    VStack(spacing: DeviceType.current == .iPad ? 40 :10) {
                        SkiPlanCard()
                            .scaleEffect(DeviceType.current == .iPad ? 1.2 :1)
                            .frame(maxWidth: .infinity)

                        RunPlanCard()
                            .scaleEffect(DeviceType.current == .iPad ? 1.2 :1)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 右侧大卡片
                    HorsePlanCard()
                        .frame(maxWidth: .infinity)
                        .scaleEffect(DeviceType.current == .iPad ? 1.2 :0.8)
                }
                .padding(.horizontal,-10)
                .padding(.top, 20)
            }
            
            // 挑战区域
            VStack(spacing: 0) {
                HStack {
                    Text("挑战")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    RacingChallengeCard()
                    SwimmingChallengeCard()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
}

// 滑雪计划卡片
struct SkiPlanCard: View {
    var body: some View {
        // 左侧图标区域
        ZStack {
            
            Button(action: {
                print("按钮点击了")
            }) {
                Image("planski")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180)
                    .overlay(
                        
                        ZStack {
                            
                            // 底层：矩形8 作为按钮背景
                            Image("rec25")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 164)
                            
                                .offset(x:10,y:42)
                            
                            
                            // 上层：矩形7 覆盖在 矩形8 之上
                            
                            Image("rec9")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40)
                                .overlay(
                                    Image("walk2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20)
                                        .offset(x: -3, y: 0)
                                )
                                .offset(x: -52, y: 36)
                            
                            // 顶层：按钮文本
                            Button(action: {  }) {
                                Text("立即加入   >")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.orange.opacity(0.9))
                            }
                            .offset(x: 20,y:40)
                            .buttonStyle(.plain)
                        }
                            .frame(width: 180,height: 100)
                    )
            }
            .buttonStyle(.plain)
            
            
        }
    }
}

// 跑步计划卡片
struct RunPlanCard: View {
    var body: some View {
        ZStack {
            
            Button(action: {
                print("按钮点击了")
            }) {
                Image("planrun")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 164)
                    .offset(x:10)
                    .overlay(
                        
                        ZStack {
                            
                            // 底层：矩形8 作为按钮背景
                            Image("rec25")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 162)
                            
                                .offset(x:14,y:40)
                            
                            
                            // 上层：矩形7 覆盖在 矩形8 之上
                            
                            Image("rec9")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 38)
                                .overlay(
                                    Image("walk2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20)
                                        .offset(x: -3, y: 0)
                                )
                                .offset(x: -48, y: 36)
                            
                            // 顶层：按钮文本
                            Button(action: {  }) {
                                Text("立即加入   >")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.orange.opacity(0.9))
                            }
                            .offset(x: 22,y:38)
                            .buttonStyle(.plain)
                        }
                            .frame(width: 180,height: 100)
                    )
            }
            .buttonStyle(.plain)
            
            
        }
    }
}

// 骑马计划大卡片
struct HorsePlanCard: View {
    var body: some View {
        ZStack {
            
            Button(action: {
                print("按钮点击了")
            }) {
                Image("ridehorse")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .overlay(
                        
                        ZStack {
                            
                            // 底层：按钮背景
                            Image("rec25")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 230)
                            
                                .offset(x:0,y:96)
                            
                            // 上层：
                            
                            Image("rec24")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120)
                                .overlay(
                                    Button(action: { print("立即加入")})
                                    {
                                        Text("立即加入")
                                            .font(.system(size: 20, weight: .regular))
                                            .foregroundColor(.orange.opacity(0.9))
                                            .frame(width: 90)
                                            .offset(x: -6,y:0)
                                        
                                    }
                                        .buttonStyle(.plain)
                                )
                                .offset(x: -56, y: 88)
                            
                            // 顶层：按钮文本
                            Button(action: { print("更多计划") }) {
                                Text("更多计划   >")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.orange.opacity(0.9))
                                
                            }
                            .offset(x: 46,y:94)
                            .buttonStyle(.plain)
                        }
                    )
            }
            .buttonStyle(.plain)
            
            
        }
        .frame(width: 220, height: 220)
    }
}

// 赛车挑战卡片
struct RacingChallengeCard: View {
    var body: some View {
        // 1) 用一个卡片容器，统一控制大小与比例（iPhone / iPad 一致）
        ZStack(alignment: .topLeading) {                     // 顶部-左对齐，便于摆放标题/标签

            // 背景图：填满容器，高度由容器决定
            Image("plancar")
                .resizable()
                .scaledToFill()                              // 填充，不留白
                .clipped()                                   // 超出部分裁剪

            // 标题区域：靠上靠左，用 padding 定位
            HStack(spacing: 8) {
                Text("赛车挑战")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)

                Text("2345人已报名")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.top, DeviceType.current == .iPad ? 20 :0)                               // 距离容器顶部 12
            .padding(.leading, 10)                           // 距离容器左侧 10

            // 底部信息区：放到底部-左侧（用 overlay/alignment 更直观）
            VStack { Spacer()                                // 用 Spacer 把内容推到底部
                HStack(spacing: 8) {
                    Text("#赛车").font(.system(size: 12)).foregroundColor(.black)
                    Text("#团队").font(.system(size: 12)).foregroundColor(.black)
                    Text("#竞速").font(.system(size: 12)).foregroundColor(.black)
                }
                .padding(.bottom, DeviceType.current == .iPad ? 40 :24)
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 左下角“报名截止”
            VStack { Spacer()
                HStack {
                    Image("rec15")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .overlay(
                            Text("报名截止：2025-6-8")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.orange.opacity(0.9))
                        )
                    Spacer()                                  // 让它贴左
                }
                .padding(.bottom, -4)
                .padding(.leading, -4)
            }

            // 右下角“点击报名”
            VStack { Spacer()
                HStack {
                    Spacer()
                    Image("rec16")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .overlay(
                            Button(action: { print("点击报名")}) {
                                Text("点击报名")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.orange.opacity(0.9))
                                    .frame(width: 90)
                            }
                            .buttonStyle(.plain)
                        )
                }
                .padding(.bottom, -4)
                .padding(.trailing, -4)
            }
        }
        // 2) 统一的“卡片尺寸策略”：固定比例 + 最大宽度，避免 iPad 无限变大
        .aspectRatio(16/9, contentMode: .fit)               // 卡片保持 16:9
        .frame(maxWidth: 700)                                // iPad 上限 700（可调）
        .padding(.horizontal, 20)                            // 页面留白
    }
}

// 游泳挑战卡片
struct SwimmingChallengeCard: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            
            
            Image("plancar2")
                .resizable()
                .scaledToFill()                              // 填充，不留白
                .clipped()                                   // 超出部分裁剪
            // 标题区域
            HStack(spacing: 8) {
                Text("游泳挑战")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                
                Text("2345人已报名")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            
            }
            .padding(.top, DeviceType.current == .iPad ? 20 :0)                               // 距离容器顶部 12
            .padding(.leading, 10)                           // 距离容器左侧 10
            // 底部信息区
            VStack { Spacer()                                // 用 Spacer 把内容推到底部
                HStack(spacing: 8) {
                    Text("#游泳").font(.system(size: 12)).foregroundColor(.black)
                    Text("#团队").font(.system(size: 12)).foregroundColor(.black)
                    Text("#竞速").font(.system(size: 12)).foregroundColor(.black)
                }
                .padding(.bottom, DeviceType.current == .iPad ? 40 :24)
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 左下角“报名截止”
            VStack { Spacer()
                HStack {
                    Image("rec15")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .overlay(
                            Text("报名截止：2025-6-8")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.orange.opacity(0.9))
                        )
                    Spacer()                                  // 让它贴左
                }
                .padding(.bottom, -4)
                .padding(.leading, -4)
            }

            // 右下角“点击报名”
            VStack { Spacer()
                HStack {
                    Spacer()
                    Image("rec16")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .overlay(
                            Button(action: { print("点击报名")}) {
                                Text("点击报名")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.orange.opacity(0.9))
                                    .frame(width: 90)
                            }
                            .buttonStyle(.plain)
                        )
                }
                .padding(.bottom, -4)
                .padding(.trailing, -4)
            }
        }
        // 2) 统一的“卡片尺寸策略”：固定比例 + 最大宽度，避免 iPad 无限变大
        .aspectRatio(16/9, contentMode: .fit)               // 卡片保持 16:9
        .frame(maxWidth: 700)                                // iPad 上限 700（可调）
        .padding(.horizontal, 20)                            // 页面留白

    }
}

// MARK: - 预览
#Preview("计划与挑战组件") {
    ScrollView {
        VStack(spacing: 30) {
            PlanAndChallengeContent()
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("滑雪计划卡片") {
    SkiPlanCard()
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("跑步计划卡片") {
    RunPlanCard()
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("骑马计划卡片") {
    HorsePlanCard()
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("赛车挑战卡片") {
    RacingChallengeCard()
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("游泳挑战卡片") {
    SwimmingChallengeCard()
        .padding()
        .background(Color.gray.opacity(0.1))
}
