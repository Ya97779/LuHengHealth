//
//  HealthDataDetailPage.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/10.
//
//  通用健康数据详情页面模板
//  支持心率和血氧数据的可视化显示

import SwiftUI
import Charts

// 健康数据类型枚举
enum HealthDataType {
    case heartRate
    case bloodOxygen
    case stepCount
    
    var title: String {
        switch self {
        case .heartRate: return "心率数据"
        case .bloodOxygen: return "血氧数据"
        case .stepCount: return "步数数据"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate: return "bpm"
        case .bloodOxygen: return "%"
        case .stepCount: return "步"
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate: return "waveform.path.ecg"
        case .bloodOxygen: return "heart.fill"
        case .stepCount: return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .bloodOxygen: return .blue
        case .stepCount: return .orange
        }
    }
    
    var yAxisRange: ClosedRange<Int> {
        switch self {
        case .heartRate: return 40...180
        case .bloodOxygen: return 85...105
        case .stepCount: return 0...20000
        }
    }
    
    var normalRange: String {
        switch self {
        case .heartRate: return "60-100 bpm"
        case .bloodOxygen: return "95-100%"
        case .stepCount: return "目标 10000 步"
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .heartRate:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.85), Color(red: 1.0, green: 0.92, blue: 0.92)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .bloodOxygen:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.96, green: 0.85, blue: 0.6), Color(red: 0.98, green: 0.92, blue: 0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .stepCount:
            return LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.8), Color(red: 1.0, green: 0.95, blue: 0.9)]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct HealthDataDetailPage: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: BLEViewModel
    
    let dataType: HealthDataType
    @State private var selectedTimeRange = "周" // 周、月
    @State private var selectedDate = Date()
    @State private var showCalendar = false
    @State private var chartData: [HealthDataEntry] = []
    @State private var isLoading = false
    
    // 健康数据存储服务
    private let healthDataStorage = HealthDataStorage.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部背景区域
                ZStack {
                    // 顶部背景渐变
                    dataType.backgroundGradient
                        .frame(height: 220)
                        .ignoresSafeArea(.all, edges: .top)
                    
                    VStack(spacing: 0) {
                        // 顶部导航栏
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            Text(dataType.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            // 占位，保持标题居中
                            Color.clear
                                .frame(width: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 80)
                        
                        // 日期选择器
                        RealDateSelectorView(
                            selectedDate: $selectedDate,
                            showCalendar: $showCalendar
                        )
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        Spacer()
                    }
                }
                
                // 白色背景内容区域
                VStack(spacing: 0) {
                    // 从设备获取历史数据按钮
                    if viewModel.connectedDevices.first != nil {
                        Button(action: {
                            requestHistoryData()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("从设备获取历史数据")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 20)
                        .onAppear {
                            print("[HealthDetail] 按钮可见 - 已连接设备: \(viewModel.connectedDevices.first?.name ?? "无")")
                        }
                    } else {
                        Text("请先连接设备以获取历史数据")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                            .onAppear {
                                print("[HealthDetail] 按钮隐藏 - 无已连接设备")
                            }
                    }
                    
                    // 时间范围选择器
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                        .padding(.horizontal, 20)
                        .padding(.top, 15)
                    
                    // 健康数据图表
                    HealthDataChartsView(
                        data: chartData,
                        timeRange: selectedTimeRange,
                        dataType: dataType,
                        isLoading: isLoading
                    )
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    
                    // 图例
                    HealthDataLegend(dataType: dataType)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 健康值提醒
                    HealthReminder()
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    
                    // AI医生诊断
                    AIDoctorDiagnosis()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // 记录
                    RecordSection()
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                .padding(.bottom, 100) // 为底部导航栏留空间
                .background(Color.white)
            }
        }
        .background(Color.white)
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarHidden(true)
        .onAppear {
            loadChartData()
        }
        .onChange(of: selectedDate) { _ in
            loadChartData()
        }
        .onChange(of: selectedTimeRange) { _ in
            loadChartData()
        }
        .onChange(of: viewModel.heartRateHistory) { _ in
            if dataType == .heartRate {
                loadChartData()
            }
        }
        .onChange(of: viewModel.bloodOxygenHistory) { _ in
            if dataType == .bloodOxygen {
                loadChartData()
            }
        }
        .onChange(of: viewModel.stepCountHistory) { _ in
            if dataType == .stepCount {
                loadChartData()
            }
        }
        .sheet(isPresented: $showCalendar) {
            HealthCalendarView(
                selectedDate: $selectedDate,
                isPresented: $showCalendar
            ) { date in
                selectedDate = date
                print("从日历选择了日期: \(formatDateString(date))")
            }
        }
    }
    
    // MARK: - 数据加载方法
    
    /// 请求设备历史数据
    private func requestHistoryData() {
        print("[HealthDetail] 点击了从设备获取历史数据按钮")
        print("[HealthDetail] 数据类型: \(dataType)")
        print("[HealthDetail] 已连接设备: \(viewModel.connectedDevices.first?.name ?? "无")")
        
        switch dataType {
        case .heartRate:
            print("[HealthDetail] 发送心率历史请求 CMD 0x17")
            viewModel.requestHeartRateHistory()
        case .bloodOxygen:
            print("[HealthDetail] 发送血氧历史请求 CMD 0x18")
            viewModel.requestBloodOxygenHistory()
        case .stepCount:
            print("[HealthDetail] 发送步数历史请求 CMD 0x19")
            viewModel.requestStepCountHistory()
        }
    }
    
    /// 格式化日期字符串
    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// 加载图表数据
    private func loadChartData() {
        guard !isLoading else { return }
        
        isLoading = true
        print("加载\(dataType.title): \(formatDateString(selectedDate)), 时间范围: \(selectedTimeRange)")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let dateRange = self.getDateRange()
            var entries: [HealthDataEntry] = []
            
            // 获取蓝牙历史数据（心率和血氧使用新协议DayHistoryData）
            let bleDayHistory: [BLEViewModel.DayHistoryData] = {
                switch self.dataType {
                case .heartRate: return self.viewModel.heartRateHistory
                case .bloodOxygen: return self.viewModel.bloodOxygenHistory
                case .stepCount: return []
                }
            }()
            
            // 获取步数历史数据（保持旧格式）
            let stepHistory: [BLEViewModel.HistoryRecord] = {
                if self.dataType == .stepCount {
                    return self.viewModel.stepCountHistory
                }
                return []
            }()
            
            for date in dateRange {
                var bleValue: Int? = nil
                
                if self.dataType == .stepCount {
                    // 步数使用旧格式
                    for history in stepHistory {
                        let calendar = Calendar.current
                        let historyDate = calendar.date(from: DateComponents(
                            year: 2000 + history.year,
                            month: history.month,
                            day: history.day
                        ))
                        if let historyDate = historyDate, calendar.isDate(historyDate, inSameDayAs: date) {
                            bleValue = history.value
                            break
                        }
                    }
                } else {
                    // 心率和血氧使用新格式
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateStr = dateFormatter.string(from: date)
                    
                    for dayData in bleDayHistory {
                        if dayData.date == dateStr {
                            // 计算当天有数据小时的平均值
                            let nonZeroValues = dayData.hourlyValues.filter { $0 > 0 }
                            if !nonZeroValues.isEmpty {
                                bleValue = nonZeroValues.reduce(0, +) / nonZeroValues.count
                            }
                            break
                        }
                    }
                }
                
                // 从数据库获取数据
                let dayData = self.healthDataStorage.getHealthData(for: date)
                
                if !dayData.isEmpty || bleValue != nil {
                    // 根据数据类型计算平均值
                    let averageValue: Int
                    let level: HealthDataLevel
                    
                    switch self.dataType {
                    case .heartRate:
                        let dbAverage = dayData.isEmpty ? 0 : dayData.map { Int($0.heartrate) }.reduce(0, +) / dayData.count
                        averageValue = bleValue ?? dbAverage
                        level = self.getHeartRateLevel(averageValue)
                    case .bloodOxygen:
                        let dbAverage = dayData.isEmpty ? 0 : dayData.map { Int($0.bloodoxygen) }.reduce(0, +) / dayData.count
                        averageValue = bleValue ?? dbAverage
                        level = self.getBloodOxygenLevel(averageValue)
                    case .stepCount:
                        let dbAverage = dayData.isEmpty ? 0 : dayData.map { Int($0.heartrate) }.reduce(0, +) / dayData.count
                        averageValue = bleValue ?? dbAverage
                        level = self.getStepCountLevel(averageValue)
                    }
                    
                    let entry = HealthDataEntry(
                        date: date,
                        dayOfWeek: self.getDayOfWeekString(for: date),
                        value: averageValue,
                        level: level
                    )
                    entries.append(entry)
                } else {
                    // 没有数据的日期，创建一个默认入口
                    let entry = HealthDataEntry(
                        date: date,
                        dayOfWeek: self.getDayOfWeekString(for: date),
                        value: 0,
                        level: .noData
                    )
                    entries.append(entry)
                }
            }
            
            DispatchQueue.main.async {
                self.chartData = entries
                self.isLoading = false
                print("\(self.dataType.title)加载完成，共\(entries.count)天数据")
            }
        }
    }
    
    /// 获取日期范围
    private func getDateRange() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        if selectedTimeRange == "周" {
            // 过去7天（包括今天）
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: selectedDate) {
                    dates.append(date)
                }
            }
            return dates.reversed()
        } else {
            // 过去30天（包括今天）
            for i in 0..<30 {
                if let date = calendar.date(byAdding: .day, value: -i, to: selectedDate) {
                    dates.append(date)
                }
            }
            return dates.reversed()
        }
    }
    
    /// 获取星期几字符串
    private func getDayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    /// 根据心率值获取级别
    private func getHeartRateLevel(_ value: Int) -> HealthDataLevel {
        if value == 0 {
            return .noData
        } else if value < 60 {
            return .low
        } else if value <= 100 {
            return .normal
        } else {
            return .high
        }
    }
    
    /// 根据血氧值获取级别
    private func getBloodOxygenLevel(_ value: Int) -> HealthDataLevel {
        if value == 0 {
            return .noData
        } else if value < 95 {
            return .low
        } else if value < 98 {
            return .normal
        } else {
            return .high
        }
    }
    
    /// 根据步数值获取级别
    private func getStepCountLevel(_ value: Int) -> HealthDataLevel {
        if value == 0 {
            return .noData
        } else if value < 5000 {
            return .low
        } else if value < 10000 {
            return .normal
        } else {
            return .high
        }
    }
}

// MARK: - 通用健康数据图表视图
struct HealthDataChartsView: View {
    let data: [HealthDataEntry]
    let timeRange: String
    let dataType: HealthDataType
    let isLoading: Bool
    
    @State private var showDataLabels = false // 新增：控制是否显示数字标签
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                // 加载指示器
                VStack {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("正在加载数据...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
                .frame(height: 250)
            } else if data.filter({ $0.value > 0 }).isEmpty {
                // 无数据提示
                VStack(spacing: 12) {
                    Image(systemName: dataType.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("暂无\(dataType.title)")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("请连接设备或选择其他日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 250)
            } else {
                VStack(spacing: 8) {
                    // 数字显示控制开关
                    HStack {
                        Text("显示数值")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("", isOn: $showDataLabels)
                            .toggleStyle(SwitchToggleStyle(tint: dataType.color))
                            .scaleEffect(0.8)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // 使用Charts库实现的折线图
                    chartView
                        .frame(height: 220)
                        .chartYScale(domain: dataType.yAxisRange)
                        .chartBackground { chartProxy in
                            chartBackgroundContent(chartProxy)
                        }
                        .chartXAxis {
                            chartXAxisContent
                        }
                        .chartYAxis {
                            chartYAxisContent
                        }
                        .chartPlotStyle { plotArea in
                            plotArea
                                .background(.white)
                                .cornerRadius(8)
                        }
                }
            }
        }
    }
    
    // MARK: - Chart组件分解
    
    /// 主图表视图
    private var chartView: some View {
        Chart(data, id: \.date) { entry in
            if entry.value > 0 {
                lineMarkView(for: entry)
                areaMarkView(for: entry)
                pointMarkView(for: entry)
                
                // 数字标签（可控制显示）
                if showDataLabels {
                    dataLabelView(for: entry)
                }
            }
        }
    }
    
    /// 折线图组件
    private func lineMarkView(for entry: HealthDataEntry) -> some ChartContent {
        LineMark(
            x: .value("日期", entry.date),
            y: .value(dataType.title, entry.value)
        )
        .foregroundStyle(dataType.color)
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.catmullRom)
    }
    
    /// 区域填充组件
    private func areaMarkView(for entry: HealthDataEntry) -> some ChartContent {
        AreaMark(
            x: .value("日期", entry.date),
            yStart: .value("基线", dataType.yAxisRange.lowerBound),
            yEnd: .value(dataType.title, entry.value)
        )
        .foregroundStyle(areaGradient)
        .interpolationMethod(.catmullRom)
    }
    
    /// 数据点组件
    private func pointMarkView(for entry: HealthDataEntry) -> some ChartContent {
        PointMark(
            x: .value("日期", entry.date),
            y: .value(dataType.title, entry.value)
        )
        .foregroundStyle(entry.level.color(for: dataType))
        .symbolSize(50)
        .opacity(entry.value > 0 ? 1.0 : 0.3)
    }
    
    /// 数字标签组件（新增）
    private func dataLabelView(for entry: HealthDataEntry) -> some ChartContent {
        PointMark(
            x: .value("日期", entry.date),
            y: .value(dataType.title, entry.value)
        )
        .opacity(0) // 隐藏数据点，只显示文本
        .annotation(position: .top, spacing: 6) {
            Text("\(entry.value)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(entry.level.color(for: dataType))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .overlay(
                            Capsule()
                                .stroke(entry.level.color(for: dataType).opacity(0.3), lineWidth: 0.5)
                        )
                )
                .opacity(showDataLabels ? 1.0 : 0.0)
                .scaleEffect(showDataLabels ? 1.0 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showDataLabels)
        }
    }
    
    /// 区域渐变色彩
    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [dataType.color.opacity(0.3), dataType.color.opacity(0.05)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// 图表背景内容
    private func chartBackgroundContent(_ chartProxy: ChartProxy) -> some View {
        let plotHeight = chartProxy.plotAreaSize.height
        let plotWidth = chartProxy.plotAreaSize.width
        
        // 根据数据类型显示不同的正常范围
        let (normalMin, normalMax, rangeText): (Int, Int, String)
        switch dataType {
        case .heartRate:
            (normalMin, normalMax, rangeText) = (60, 100, "正常范围 60-100 bpm")
        case .bloodOxygen:
            (normalMin, normalMax, rangeText) = (95, 100, "正常范围 95-100%")
        case .stepCount:
            (normalMin, normalMax, rangeText) = (5000, 15000, "目标 5000-15000 步")
        }
        
        let totalRange = dataType.yAxisRange.upperBound - dataType.yAxisRange.lowerBound
        let normalRangeHeight = plotHeight * CGFloat(normalMax - normalMin) / CGFloat(totalRange)
        let normalRangeY = plotHeight * CGFloat(dataType.yAxisRange.upperBound - normalMax) / CGFloat(totalRange) + normalRangeHeight / 2
        
        return RoundedRectangle(cornerRadius: 4)
            .fill(Color.green.opacity(0.1))
            .frame(height: normalRangeHeight)
            .position(x: plotWidth / 2, y: normalRangeY)
            .overlay(
                Text(rangeText)
                    .font(.caption2)
                    .foregroundColor(.green)
                    .opacity(0.7),
                alignment: .center
            )
    }
    
    /// X轴内容
    private var chartXAxisContent: some AxisContent {
        AxisMarks(values: getXAxisValues()) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.gray.opacity(0.3))
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(formatXAxisLabel(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Y轴内容
    private var chartYAxisContent: some AxisContent {
        let step = (dataType.yAxisRange.upperBound - dataType.yAxisRange.lowerBound) / 4
        let values = stride(from: dataType.yAxisRange.lowerBound, through: dataType.yAxisRange.upperBound, by: step).map { $0 }
        
        return AxisMarks(values: values) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(.gray.opacity(0.3))
            AxisValueLabel {
                if let intValue = value.as(Int.self) {
                    Text("\(intValue)\(dataType.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // 获取X轴显示值
    private func getXAxisValues() -> [Date] {
        if timeRange == "周" {
            // 周模式：显示所有日期
            return data.map { $0.date }
        } else {
            // 月模式：每隔5天显示一个刻度
            return data.enumerated().compactMap { index, entry in
                return index % 5 == 0 ? entry.date : nil
            }
        }
    }
    
    // 格式化X轴标签
    private func formatXAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        if timeRange == "周" {
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "E" // 星期几
        } else {
            formatter.dateFormat = "M/d" // 月/日
        }
        return formatter.string(from: date)
    }
    
    // 格式化选中日期
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 EEEE"
        return formatter.string(from: date)
    }
    
    // 查找最近的数据点（简化实现）
    private func findNearestDataPoint(at location: CGPoint) -> HealthDataEntry? {
        // 这里可以实现更精确的点击检测逻辑
        // 为简化，返回有数据的第一个点
        return data.first { $0.value > 0 }
    }
}

// MARK: - 通用健康数据图例
struct HealthDataLegend: View {
    let dataType: HealthDataType
    
    var body: some View {
        HStack(spacing: 20) {
            switch dataType {
            case .heartRate:
                LegendItem(color: .red, label: "高 (>100bpm)")
                LegendItem(color: .green, label: "正常 (60-100bpm)")
                LegendItem(color: .yellow, label: "低 (<60bpm)")
                LegendItem(color: .gray, label: "无数据")
            case .bloodOxygen:
                LegendItem(color: .purple, label: "高 (≥98%)")
                LegendItem(color: .green, label: "正常 (95-97%)")
                LegendItem(color: .yellow, label: "低 (<95%)")
                LegendItem(color: .gray, label: "无数据")
            case .stepCount:
                LegendItem(color: .green, label: "达标 (≥10000步)")
                LegendItem(color: .orange, label: "进行中 (5000-9999步)")
                LegendItem(color: .yellow, label: "不足 (<5000步)")
                LegendItem(color: .gray, label: "无数据")
            }
            
            Spacer()
        }
    }
}

// MARK: - 通用健康数据模型
struct HealthDataEntry: Equatable {
    let date: Date
    let dayOfWeek: String
    let value: Int
    let level: HealthDataLevel
    
    // 实现Equatable协议
    static func == (lhs: HealthDataEntry, rhs: HealthDataEntry) -> Bool {
        return lhs.date == rhs.date && lhs.value == rhs.value && lhs.level == rhs.level
    }
}

enum HealthDataLevel: Equatable {
    case low, normal, high, noData
    
    func color(for dataType: HealthDataType) -> Color {
        switch self {
        case .low: return .yellow
        case .normal: return .green
        case .high: 
            switch dataType {
            case .heartRate: return .red
            case .bloodOxygen: return .purple
            case .stepCount: return .green
            }
        case .noData: return .gray
        }
    }
}

// MARK: - 通用组件

// 时间范围选择器
struct TimeRangeSelector: View {
    @Binding var selectedRange: String
    let ranges = ["周", "月"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ranges, id: \.self) { range in
                Button(action: {
                    selectedRange = range
                }) {
                    Text(range)
                        .font(.system(size: 16))
                        .foregroundColor(selectedRange == range ? .black : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedRange == range ? 
                            Color.white : Color.clear
                        )
                        .cornerRadius(8)
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// 图例项组件
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 20, height: 8)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

// 真实日期选择器
struct RealDateSelectorView: View {
    @Binding var selectedDate: Date
    @Binding var showCalendar: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // 日历图标和日期
            Button(action: {
                showCalendar = true
            }) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange)
                            .frame(width: 40, height: 40)
                        
                        VStack(spacing: 2) {
                            Text(getMonthString())
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                            Text(getYearString())
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(getFullDateString())
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // 最近7天选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getRecentDates(), id: \.self) { date in
                        Button(action: {
                            selectedDate = date
                        }) {
                            VStack(spacing: 4) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 16, weight: isSelected(date) ? .bold : .regular))
                                    .foregroundColor(isSelected(date) ? .white : .black)
                                
                                Text(getDayOfWeek(for: date))
                                    .font(.system(size: 12))
                                    .foregroundColor(isSelected(date) ? .white : .gray)
                            }
                            .frame(width: 40, height: 50)
                            .background(isSelected(date) ? Color.orange : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // 右侧勾选图标
            Image(systemName: "checkmark")
                .font(.system(size: 16))
                .foregroundColor(.orange)
        }
    }
    
    private func getMonthString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月"
        return formatter.string(from: selectedDate)
    }
    
    private func getYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func getFullDateString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月 yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func getRecentDates() -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: selectedDate) {
                dates.append(date)
            }
        }
        
        return dates.reversed()
    }
    
    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    private func getDayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// 健康值提醒
struct HealthReminder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("健康值提醒")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            HStack {
                Text("本次测量并未发现异常")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("健康")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

// AI医生诊断
struct AIDoctorDiagnosis: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI医生诊断")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text("前去进行AI医生问诊")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

// 记录区域
struct RecordSection: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("记录")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text("最近测量：2025-5-7-12:05:08")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    HealthDataDetailPage(dataType: .heartRate)
}