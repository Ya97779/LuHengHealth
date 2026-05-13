//
//  AppColors.swift
//  LuHengHeath
//  全局UI界面配置
//  Created by macios on 2025/7/17.
//


import SwiftUI

// MARK:  - 颜色配置
struct AppColors {
    static let primary = Color("White") //
    static let background = Color(hex: "#D6D6D6")
    static let title = Color.black
    static let subtitle = Color.gray
    static let error = Color.red
}

// MARK:  - 字体配置
struct AppFonts {
    static let title = Font.system(size: 24, weight: .bold)
    static let subtitle = Font.system(size: 18, weight: .semibold)
    static let body = Font.system(size: 16)
    static let caption = Font.system(size: 12)
}
// MARK:  - 封装常用按钮样式
struct AppStyles {
    static func primaryButtonStyle() -> some ViewModifier {
        return ButtonStyleModifier()
    }
}

struct ButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppFonts.body)
            .foregroundColor(.white)
            .padding()
            .background(AppColors.primary)
            .cornerRadius(12)
    }
}
