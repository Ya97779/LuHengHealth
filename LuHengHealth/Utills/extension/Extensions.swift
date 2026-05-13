//
//  Extensions.swift
//  LuHengHeath
//
//  Created by macios on 2025/7/18.
//

import SwiftUI
import Foundation


// MARK:  - 颜色扩展
extension Color {
    func toHex() -> String? {
        UIColor(self).toHex()
    }

    init(hex: String) {
        self = Color(UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xff0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00ff00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000ff) / 255

        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    func toHex() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
}


// MARK:  - 使用方法
/*
 ✅ 颜色字符串 → Color

 let red = Color(hex: "#FF0000") // 纯红色
 ✅ Color → 十六进制字符串

 let color = Color.blue
 if let hex = color.toHex() {
     print(hex) // "#0000ff"
 }
 ✅ 颜色字符串 → UIColor

 let uiRed = UIColor(hex: "#FF0000")
 ✅ UIColor → 十六进制字符串

 let uiColor = UIColor.green
 if let hex = uiColor.toHex() {
     print(hex) // "#00ff00"
 }
 
 
 
 
 */
