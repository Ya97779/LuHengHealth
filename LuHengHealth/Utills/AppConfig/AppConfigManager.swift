//
//  RecentColorManager.swift
//  LuHengHeath
//
//  Created by macios on 2025/7/18.
//


import SwiftUI

class AppConfigManager: ObservableObject {
    @AppStorage("RecentColorHexes") private var storedHexes: String = ""

    /// 最近颜色，最多保存 3 个
    var recentColors: [Color] {
        get {
            storedHexes
                .split(separator: ",")
                .compactMap { Color(hex: String($0)) }
        }
        set {
            let hexes = newValue.compactMap { $0.toHex() }
            storedHexes = hexes.joined(separator: ",")
        }
    }

    /// 添加一个颜色到最近列表（最多保留 3 个，去重）
    func addColor(_ color: Color) {
        guard let hex = color.toHex() else { return }
        var currentHexes = storedHexes.split(separator: ",").map { String($0) }

        // 去重后插入最前面
        currentHexes.removeAll { $0 == hex }
        currentHexes.insert(hex, at: 0)

        // 保留最近三个
        if currentHexes.count > 3 {
            currentHexes = Array(currentHexes.prefix(3))
        }

        storedHexes = currentHexes.joined(separator: ",")
    }
}
