//
//  LuHengHealthApp.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/8.
//

import SwiftUI

@main
struct LuHengHealthApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var userSession = UserSession()
    @StateObject private var deviceState = DeviceState()
    // 创建一个全局共享的BLEViewModel实例
    @StateObject private var sharedBLEViewModel = BLEViewModel()
    var body: some Scene {
        WindowGroup {
            MainPage()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(userSession)
                .environmentObject(deviceState)
                .environmentObject(sharedBLEViewModel)
               
        }
    }
}
