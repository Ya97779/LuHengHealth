//
//  HealthPage.swift
//  test
//
//  Created by macios on 2025/7/14.
//

import SwiftUI

struct HealthPage: View {
    @State private var showBloodOxygenDetail = false
    @State private var showHeartRateDetail = false
    @State private var showStepCountDetail = false
    @State private var showStorageSettings = false
    @State private var showTestTool = false
    @State private var showCalendar = false
    @StateObject private var healthDataService = HealthDataService()
    @EnvironmentObject var viewModel: BLEViewModel
    
    var body: some View {
        let bottomPadding: CGFloat = DeviceType.current == .iPad ? 600 : 100
        ZStack {
            // 背景图层
            Image("Appbackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // 主体内容层
            ScrollView (.vertical, showsIndicators: false){
                VStack(alignment: .leading, spacing: 20) {
                    // 顶部日期选择和活力趋势
                    HStack {
                        VStack(alignment: .leading) {
                            Text("实时监测")
                                .font(.system(size: 28))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            // 可点击的日历部分
                            Button(action: {
                                showCalendar = true
                            }) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text(getCurrentDateString())
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    
                        HStack {
                            Text("活力趋势")
                                .font(.headline)
                                .foregroundColor(.black)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, topBarReservedPadding(6))
                    .padding(.horizontal, 20)
                    
                    // 日期选择器（最近七天的展开形式）
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("最近七天")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                            Button("查看更多") {
                                showCalendar = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(healthDataService.getRecentDates(), id: \.self) { date in
                                    Button(action: {
                                        print("点击了日期: \(healthDataService.formatDate(date))")
                                        healthDataService.selectedDate = date
                                        healthDataService.loadHealthData(for: date)
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(healthDataService.formatDate(date))
                                                .font(.system(size: 13))
                                                .fontWeight(healthDataService.isSelectedDate(date) ? .bold : .regular)
                                                .foregroundColor(healthDataService.isSelectedDate(date) ? .white : .black)
                                            Text(healthDataService.getDayOfWeek(date))
                                                .font(.system(size: 16))
                                                .foregroundColor(healthDataService.isSelectedDate(date) ? .white : .gray)
                                            
                                            // 数据指示器
                                            if hasHealthDataForDate(date) {
                                                Circle()
                                                    .fill(healthDataService.isSelectedDate(date) ? Color.white : Color.green)
                                                    .frame(width: 4, height: 4)
                                            }
                                        }
                                        .frame(width: 45, height: 70)
                                        .background(healthDataService.isSelectedDate(date) ? Color.orange : Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // ... existing code for 环形进度图 ...
                    CircularProgressChart(
                        pressure: healthDataService.currentHealthData?.stress ?? 0,
                        health: healthDataService.currentHealthData?.overallHealth ?? 0,
                        sleep: Double(healthDataService.currentHealthData?.sleep.hours ?? 0) * 10 + Double(healthDataService.currentHealthData?.sleep.minutes ?? 0) / 6.0,
                        showPressure: true,
                        showHealth: true,
                        showSleep: false
                    )
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .id(healthDataService.currentHealthData?.date ?? "no-data")
                    .onChange(of: healthDataService.currentHealthData) { newValue in
                        print("环形进度图数据更新: \(newValue?.overallHealth ?? 0)%")
                    }
                    
                    // ... existing code for 压力、健康、睡眠数据 ...
                    HStack(spacing: 20) {
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                Text("压力")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                            Text("强度\(Int(healthDataService.currentHealthData?.stress ?? 0))%")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                                Text("健康")
                                    .font(.headline)
                                    .foregroundColor(.black)
                            }
                            Text("总评估\(Int(healthDataService.currentHealthData?.overallHealth ?? 0))%")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // ... existing code for 健康日志 ...
                    VStack(alignment: .leading) {
                        HStack {
                            Text("健康日志")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                            Text("记录 »")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.8))
                            .frame(height: 80)
                            .overlay(
                                VStack(alignment: .leading) {
                                    Text("日常: 健康日志提醒您,再忙也不要忘记")
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Text("吃饭哦!")
                                        .font(.body)
                                        .foregroundColor(.black)
                                    HStack {
                                        Spacer()
                                        Text("今日: \(SuperDateUtill.getCurrentDateForHealthLog())")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                    .padding()
                            )
                            .padding(.horizontal)
                    }
                    
                    // 健康数据
                    VStack(alignment: .leading) {
                        HStack {
                            Text("健康数据")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Spacer()
                            
                            // 测试工具按钮
                            Button(action: {
                                showTestTool = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "testtube.2")
                                        .font(.caption)
                                    Text("测试")
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showStorageSettings = true
                            }) {
                                Text("管理 »")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            // 第一排：心率 + 血氧
                            HStack(spacing: 15) {
                                // 心率卡片
                                HealthDataCard(
                                    title: "心率",
                                    value: getDisplayHeartRate(),
                                    range: "40-160bpm",
                                    icon: "waveform.path.ecg",
                                    color: .red,
                                    progress: Double(getDisplayHeartRateValue()) / 100,
                                    action: { showHeartRateDetail = true }
                                )
                                // 血氧卡片
                                HealthDataCard(
                                    title: "血氧",
                                    value: getDisplayBloodOxygen(),
                                    range: "94-100",
                                    icon: "heart.fill",
                                    color: .green,
                                    progress: Double(getDisplayBloodOxygenValue()) / 100,
                                    action: { showBloodOxygenDetail = true }
                                )
                            }
                            
                            // 第二排：步数（宽度与心率+血氧之和相同）
                            HealthDataCard(
                                title: "步数",
                                value: getDisplayStepCount(),
                                range: "目标10000步",
                                icon: "heart.fill",
                                color: .orange,
                                progress: getDisplayStepCountProgress(),
                                action: { showStepCountDetail = true }
                            )
                        }
                        .padding(.horizontal)
                        
                        // 轮询控制按钮
                        HStack(spacing: 15) {
                            PollingButton(
                                title: "心率",
                                icon: "waveform.path.ecg",
                                color: .red,
                                isPolling: viewModel.isHeartRatePolling,
                                action: { viewModel.toggleHeartRatePolling() }
                            )
                            
                            PollingButton(
                                title: "血氧",
                                icon: "heart.fill",
                                color: .green,
                                isPolling: viewModel.isBloodOxygenPolling,
                                action: { viewModel.toggleBloodOxygenPolling() }
                            )
                            
                            PollingButton(
                                title: "步数",
                                icon: "figure.walk",
                                color: .orange,
                                isPolling: viewModel.isStepCountPolling,
                                action: { viewModel.toggleStepCountPolling() }
                            )
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarReservedHeight() + bottomPadding)
            }
            .onAppear {
                // 只有在页面首次显示且没有数据时才加载，避免重复加载
                if healthDataService.currentHealthData == nil {
                    print("首次进入健康页面，加载当前日期数据")
                    DispatchQueue.main.async {
                        healthDataService.loadCurrentDateData()
                    }
                }
            }
            .sheet(isPresented: $showBloodOxygenDetail) {
                HealthDataDetailPage(dataType: .bloodOxygen)
            }
            .sheet(isPresented: $showHeartRateDetail) {
                HealthDataDetailPage(dataType: .heartRate)
            }
            .sheet(isPresented: $showStorageSettings) {
                HealthDataStorageSettingsView(healthDataService: healthDataService)
            }
            .sheet(isPresented: $showTestTool) {
                HealthDataTestTool()
            }
            .sheet(isPresented: $showCalendar) {
                HealthCalendarView(
                    selectedDate: $healthDataService.selectedDate,
                    isPresented: $showCalendar
                ) { selectedDate in
                    healthDataService.selectedDate = selectedDate
                    healthDataService.loadHealthData(for: selectedDate)
                    print("从日历选择了日期: \(healthDataService.formatDate(selectedDate))")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - 数据显示辅助方法
    
    /// 获取当前日期字符串
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: healthDataService.selectedDate)
    }
    
    /// 获取健康日志的日期格式

    
    /// 检查指定日期是否有健康数据
    /// 使用缓存的方式，避免频繁查询数据库
    private func hasHealthDataForDate(_ date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // 检查是否为今天，如果是今天且有BLE连接，则显示有数据
        if Calendar.current.isDateInToday(date) {
            if let _ = viewModel.connectedDevices.first,
               let heartRate = viewModel.heartRate, heartRate > 0 {
                return true
            }
        }
        
        // 其他情况下，只有在用户点击日历时才查询，这里返回false避免频繁查询
        return false
    }
    
    /// 获取显示的心率值
    private func getDisplayHeartRate() -> String {
        if let connectedDevice = viewModel.connectedDevices.first,
           let heartRate = viewModel.heartRate, heartRate > 0 {
            return "\(heartRate)bpm (实时)"
        }
        else if let healthData = healthDataService.currentHealthData,
                healthData.heartRate > 0 {
            let dataType = healthDataService.dataDisplayType == .latest ? "最新" : "平均"
            return "\(healthData.heartRate)bpm (\(dataType))"
        }
        else {
            return "0bpm"
        }
    }
    
    /// 获取显示的心率数值
    private func getDisplayHeartRateValue() -> Int {
        if let connectedDevice = viewModel.connectedDevices.first,
           let heartRate = viewModel.heartRate, heartRate > 0 {
            return heartRate
        }
        else if let healthData = healthDataService.currentHealthData {
            return healthData.heartRate
        }
        return 0
    }
    
    /// 获取显示的血氧值
    private func getDisplayBloodOxygen() -> String {
        if let connectedDevice = viewModel.connectedDevices.first,
           let bloodOxygen = viewModel.bloodOxygen, bloodOxygen > 0 {
            return "\(bloodOxygen)% (实时)"
        }
        else if let healthData = healthDataService.currentHealthData,
                healthData.bloodOxygen > 0 {
            let dataType = healthDataService.dataDisplayType == .latest ? "最新" : "平均"
            return "\(Int(healthData.bloodOxygen))% (\(dataType))"
        }
        else {
            return "0%"
        }
    }
    
    /// 获取显示的血氧数值
    private func getDisplayBloodOxygenValue() -> Int {
        if let connectedDevice = viewModel.connectedDevices.first,
           let bloodOxygen = viewModel.bloodOxygen, bloodOxygen > 0 {
            return bloodOxygen
        }
        else if let healthData = healthDataService.currentHealthData {
            return Int(healthData.bloodOxygen)
        }
        return 0
    }
    
    /// 获取显示的步数值
    private func getDisplayStepCount() -> String {
        if let connectedDevice = viewModel.connectedDevices.first,
           let stepCount = viewModel.stepCount, stepCount > 0 {
            return "\(stepCount)步"
        }
        else {
            return "0步"
        }
    }
    
    /// 获取步数进度值 (0.0 ~ 1.0)
    /// 目标: 10000步 (WHO推荐每日步数)
    private func getDisplayStepCountProgress() -> Double {
        let stepGoal = 10000.0
        if let connectedDevice = viewModel.connectedDevices.first,
           let stepCount = viewModel.stepCount, stepCount > 0 {
            return min(Double(stepCount) / stepGoal, 1.0)
        }
        return 0.0
    }
}

// MARK: - 健康数据卡片组件
struct HealthDataCard: View {
    var title: String
    var value: String
    var range: String
    var icon: String
    var color: Color
    var progress: Double
    var action: (() -> Void)? = nil
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.white.opacity(0.8))
            .frame(height: 150)
            .overlay(
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            action?()
                        }) {
                            Image(systemName: "chevron.right.2")
                                .foregroundColor(.gray)
                        }
                        .disabled(action == nil)
                    }
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Text("健康范围: \(range)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text("健康")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("相较于昨天低2%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                    .padding()
            )
    }
}

// MARK: - 轮询控制按钮组件
struct PollingButton: View {
    var title: String
    var icon: String
    var color: Color
    var isPolling: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isPolling ? color : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isPolling ? .white : .gray)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isPolling ? color : .gray)
                
                Text(isPolling ? "采集中" : "点击采集")
                    .font(.caption2)
                    .foregroundColor(isPolling ? .green : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HealthPage()
}
