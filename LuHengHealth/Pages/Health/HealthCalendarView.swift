//
//  HealthCalendarView.swift
//  LuHengHealth
//
//  Created by macios on 2025/9/10.
//
//  健康页面日历控件
//  支持选择任意日期查看对应的健康数据，集成数据库查询功能

import SwiftUI

struct HealthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onDateSelected: (Date) -> Void
    let healthDataStorage = HealthDataStorage.shared
    
    @State private var currentMonth = Date()
    @State private var daysWithData: Set<String> = []
    @State private var isLoading = false
    @State private var lastClickTime: Date = Date.distantPast
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份导航
                monthNavigationView
                
                // 星期标题
                weekdayHeaderView
                
                // 日历网格
                calendarGridView
                
                Spacer()
                
                // 底部说明
                dataIndicatorView
            }
            .padding()
            .navigationTitle("选择日期")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") { isPresented = false },
                trailing: Button("今天") { 
                    selectToday()
                }
            )
        }
        .onAppear {
            // 仅在首次显示时加载，而不是每次点击HealthPage时都加载
            if daysWithData.isEmpty {
                loadHealthDataDates()
            }
        }
        .onChange(of: currentMonth) { newMonth in
            loadHealthDataDates()
        }
    }
    
    // MARK: - 月份导航视图
    private var monthNavigationView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(isLoading ? .gray : .blue)
            }
            .disabled(isLoading)
            
            Spacer()
            
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 8)
                }
                Text(monthYearString(currentMonth))
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(isLoading ? .gray : .blue)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - 星期标题视图
    private var weekdayHeaderView: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - 日历网格视图
    private var calendarGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(daysInMonth, id: \.self) { date in
                DayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
                    hasData: hasHealthData(for: date),
                    isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                ) {
                    selectDate(date)
                }
            }
        }
    }
    
    // MARK: - 数据指示器视图
    private var dataIndicatorView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("有健康数据")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("今天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 8, height: 8)
                    Text("已选择")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("点击日期查看当日健康数据")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - 计算属性
    
    private var weekdaySymbols: [String] {
        ["日", "一", "二", "三", "四", "五", "六"]
    }
    
    private var daysInMonth: [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let paddingDays = (firstWeekday - 1) % 7
        
        var days: [Date] = []
        
        // 添加上个月的填充日期
        if paddingDays > 0 {
            for i in (1...paddingDays).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    days.append(date)
                }
            }
        }
        
        // 添加当月的日期
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // 添加下个月的填充日期，确保6行
        let remainingCells = 42 - days.count
        for i in 0..<remainingCells {
            if let lastDay = days.last,
               let date = calendar.date(byAdding: .day, value: i + 1, to: lastDay) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - 方法
    
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        let now = Date()
        // 防止频繁点击（0.5秒防抖）
        guard !isLoading && now.timeIntervalSince(lastClickTime) > 0.5 else { 
            print("操作太频繁，跳过")
            return 
        }
        lastClickTime = now
        
        let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        currentMonth = newMonth
    }
    
    private func nextMonth() {
        let now = Date()
        // 防止频繁点击（0.5秒防抖）
        guard !isLoading && now.timeIntervalSince(lastClickTime) > 0.5 else { 
            print("操作太频繁，跳过")
            return 
        }
        lastClickTime = now
        
        let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        currentMonth = newMonth
    }
    
    private func selectDate(_ date: Date) {
        selectedDate = date
        onDateSelected(date)
        isPresented = false
    }
    
    private func selectToday() {
        let today = Date()
        currentMonth = today
        selectDate(today)
    }
    
    private func hasHealthData(for date: Date) -> Bool {
        let dateString = dateFormatter.string(from: date)
        return daysWithData.contains(dateString)
    }
    
    private func loadHealthDataDates() {
        // 防止重复加载
        guard !isLoading else { 
            print("数据正在加载中，跳过重复请求")
            return 
        }
        
        isLoading = true
        
        // 获取当前月份范围内有数据的日期
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.end ?? currentMonth
        
        print("加载日历数据: \(monthYearString(currentMonth))")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let healthData = self.healthDataStorage.getHealthData(from: startOfMonth, to: endOfMonth)
            let dateStrings = Set(healthData.map { data in
                self.dateFormatter.string(from: data.timestamp ?? Date())
            })
            
            DispatchQueue.main.async {
                self.daysWithData = dateStrings
                self.isLoading = false
                print("日历数据加载完成: \(self.monthYearString(self.currentMonth))，有数据的日期: \(dateStrings.count)天")
            }
        }
    }
}

// MARK: - 日期单元格组件
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasData: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景
                Circle()
                    .fill(backgroundColor)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                // 日期数字
                Text(dayNumber)
                    .font(.system(size: 16, weight: isSelected || isToday ? .semibold : .regular))
                    .foregroundColor(textColor)
                
                // 数据指示器
                if hasData && isCurrentMonth {
                    VStack {
                        Spacer()
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                            .offset(y: -2)
                    }
                }
            }
        }
        .frame(width: 40, height: 40)
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isToday {
            return .orange.opacity(0.3)
        } else {
            return .clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isCurrentMonth {
            return isToday ? .orange : .primary
        } else {
            return .secondary
        }
    }
}

#Preview {
    HealthCalendarView(
        selectedDate: .constant(Date()),
        isPresented: .constant(true),
        onDateSelected: { _ in }
    )
}