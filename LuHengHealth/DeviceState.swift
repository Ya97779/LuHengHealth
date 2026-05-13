//
//  DeviceState.swift
//  LuHengHeath
//
//  Created by macios on 2025/9/1.
//


import SwiftUI
import Combine

class DeviceState: ObservableObject {
    @Published var isPad: Bool
    @Published var isLandscape: Bool
    
    init() {
        self.isPad = UIDevice.current.userInterfaceIdiom == .pad
        self.isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        // 监听方向变化
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let size = UIScreen.main.bounds.size
            self.isLandscape = size.width > size.height
        }
    }
}