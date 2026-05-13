//
//  SportPage.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

// MARK: - 主页面
struct SportPage: View {
    @State private var selectedTab = "SubSportPage" // 当前选中的标签，默认显示实时数据
    
    var body: some View {
        let bottomPadding: CGFloat = DeviceType.current == .iPad ? 600 : 100
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Image("Appbackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 顶部导航栏（靠左对齐）
                        VStack(spacing: 16) {
                            // 第一行导航
                            HStack(spacing: 20) {
                                Button("运动") {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        selectedTab = "SubSportPage"
                                    }
                                }
                                .font(.system(size: 28, weight: (selectedTab == "Sport" || selectedTab == "SubSportPage" || selectedTab == "FriendsCircle") ? .bold : .regular))
                                .foregroundColor((selectedTab == "Sport" || selectedTab == "SubSportPage" || selectedTab == "FriendsCircle") ? .black : .gray)
                                .scaleEffect((selectedTab == "Sport" || selectedTab == "SubSportPage" || selectedTab == "FriendsCircle") ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                
                                Button("计划与挑战") {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        selectedTab = "PlanAndChallenge"
                                    }
                                }
                                .font(.system(size: 28, weight: selectedTab == "PlanAndChallenge" ? .bold : .regular))
                                .foregroundColor(selectedTab == "PlanAndChallenge" ? .black : .gray)
                                .scaleEffect(selectedTab == "PlanAndChallenge" ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                
                                Button("课程") {
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        selectedTab = "Course"
                                    }
                                }
                                .font(.system(size: 28, weight: selectedTab == "Course" ? .bold : .regular))
                                .foregroundColor(selectedTab == "Course" ? .black : .gray)
                                .scaleEffect(selectedTab == "Course" ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 第二行导航（只在运动栏目下显示）
                            if selectedTab == "Sport" || selectedTab == "SubSportPage" || selectedTab == "FriendsCircle" {
                                HStack(spacing: 30) {
                                    Button("运动") {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedTab = "SubSportPage"
                                        }
                                    }
                                    .font(.system(size: 20, weight: selectedTab == "SubSportPage" ? .bold : .regular))
                                    .foregroundColor(selectedTab == "SubSportPage" ? .black : .gray)
                                    .scaleEffect(selectedTab == "SubSportPage" ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                    
                                    Button("朋友圈") {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            selectedTab = "FriendsCircle"
                                        }
                                    }
                                    .font(.system(size: 20, weight: selectedTab == "FriendsCircle" ? .bold : .regular))
                                    .foregroundColor(selectedTab == "FriendsCircle" ? .black : .gray)
                                    .scaleEffect(selectedTab == "FriendsCircle" ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                .offset(x:10)
                                
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    // 主要内容区域 - 根据选中标签显示不同内容
                    VStack(spacing: 0) {
                        if selectedTab == "PlanAndChallenge" {
                            // 计划与挑战页面内容
                            PlanAndChallengeContent()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else if selectedTab == "Course" {
                            // 课程页面内容
                            CourseContent()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else if selectedTab == "SubSportPage" {
                            // 运动子页面（运动页面的原内容）
                            SubSportPage()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else if selectedTab == "FriendsCircle" {
                            // 朋友圈页面内容
                            FriendsCircleContent()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }

                    .padding(.bottom, tabBarReservedHeight() + bottomPadding) // 动态为底部导航栏留空间
                    .background(Color.clear)
                    .animation(.easeInOut(duration: 0.4), value: selectedTab)
                    }
                }
                
                .ignoresSafeArea(.all, edges: .bottom) // 横屏也能下拉到底
            }
        }
    }
}

// MARK: - 预览
#Preview("运动页面") {
    SportPage()
}
