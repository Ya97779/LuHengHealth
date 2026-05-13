//
//  MainPage.swift
//  test
//
//  Created by macios on 2025/7/11.
//

import SwiftUI

struct MainPage: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    
    var body: some View {
        
        // MARK:  - 底部标签栏
        mytabbaar()
            .accentColor(.black)
    }
}

// MARK:  - 标签栏对应跳转页面
struct HomeView: View {
    var body: some View {
        // 首页：使用 fit，避免字体和图形拉伸变形（白边交由基线选择与安全区背景兜底处理）
        ResponsiveContainer(fillMode: .fit) {
            HomePage()
        }
            .background(AppColors.background.ignoresSafeArea()) //整体背景色,
            .accentColor(.blue)
    
          
    }
}

struct HealthView: View {
    var body: some View {
        // 健康页：滚动内容为主，使用 fit
        ResponsiveContainer(fillMode: .fit) {
            HealthPage()
        }
        
    }
}
struct DeviceView: View {
    
    var body: some View {
        // 设备页：滚动为主，使用 fit
        ResponsiveContainer(fillMode: .fit) {
            DevicePage()
        }
        
    }
}
struct SportView: View {
    
    var body: some View {
        // 运动页：滚动+过渡动画，使用 fit 避免过渡时形变
        ResponsiveContainer(fillMode: .fit) {
            SportPage()
        }
        
    }
}
struct AccountView: View {
    @EnvironmentObject var userSession: UserSession
    var body: some View {
        // 我的页：滚动为主，使用 fit
        ResponsiveContainer(fillMode: .fit) {
            if userSession.isLoggedIn {
                AccountPage()
            } else {
                LoginView()
            }
        }
    }
}



// MARK:  - 预览
#Preview {
    MainPage().environmentObject(UserSession())
             .environmentObject(DeviceState())
}
