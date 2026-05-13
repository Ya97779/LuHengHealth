//
//  RealTimeDataComponents.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

// MARK: - 实时数据页面内容


// 实时数据页面内容（运动页面的原内容）
struct SubSportPage: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    // 用户信息存储服务
    private let userInfoStorage = UserInfoStorage.shared
    
    // 共享的用户数据状态
    @State private var userHeight: Int = 0  // 身高 cm
    @State private var userWeight: Double = 0  // 体重 kg
    @State private var userName: String = ""
    @State private var userGender: String = ""
    @State private var exerciseTime: Double = 0  // 运动时长 min
    var body: some View {
        
        let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
        
        VStack(spacing: 0) {
            
            ZStack(alignment: .topLeading) {
                Image("userbg")
                    .resizable()
                    .scaledToFit()
                    .frame(width:  DeviceType.current == .iPad ? 600 : 370)
                
                
                HStack(spacing: DeviceType.current == .iPad ? 60: 10) {
                    // 左侧用户信息卡片
                    UserInfoCard(
                        userHeight: $userHeight,
                        userName: $userName,
                        userGender: $userGender
                    )
                    
                    
                    // 右侧今日数据卡片
                    TodayDataCard(
                        userWeight: $userWeight,
                        exerciseTime: $exerciseTime
                    )
                    
                    
                    
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            
            // 励志文案
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 300, height: 30)
                Text("身体的平衡，是心灵平衡的开始")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.top, 30)
                    .padding(.bottom, 30)
                
            }
            
            
            // 身体数据区域
            VStack(spacing:0) {
                HStack {
                    Text("身体数据")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 6) {
                    // 第一个身体数据卡片
                    BodyDataCard1()
                        .frame(maxWidth: .infinity)   // 占满剩余空间
                    // 燃脂率圆环
                    FatBurnRateCard()
                        .frame(maxWidth: .infinity)   // 占满剩余空间
                    // BMI卡片
                    BMICard(
                        bodyHeight: userHeight,
                        bodyWeight: userWeight
                    )
                        .frame(maxWidth: .infinity)   // 占满剩余空间
                }
                
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            
            // 运动数据区域
            VStack(spacing: 0) {
                HStack {
                    Text("运动数据")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("更多 >>")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                // 运动计划卡片滚动区域
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<4) { index in
                            ExercisePlanCard(index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
        }
        .background(.clear)
        .onAppear {
            loadUserInfo()
        }
    }
    
    // MARK: - 数据加载方法
    
    /// 加载用户信息
    private func loadUserInfo() {
        userName = userInfoStorage.getUsername()
        userGender = userInfoStorage.getGender()
        userHeight = userInfoStorage.getHeight()
        userWeight = userInfoStorage.getWeight()
        
        print("加载用户信息: 昵称=\(userName), 性别=\(userGender), 身高=\(userHeight)cm, 体重=\(userWeight)kg")
    }
    
}

// MARK: - 实时数据组件

// 用户信息卡片
struct UserInfoCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showingInput = false     // 控制弹窗
    @State private var inputname = ""
    @State private var inputgender = ""
    @State private var inputbodyheight = ""
    
    // 用户信息存储服务
    private let userInfoStorage = UserInfoStorage.shared
    
    // 从父组件的绑定参数
    @Binding var userHeight: Int
    @Binding var userName: String
    @Binding var userGender: String

    
    var body: some View {
        
        let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
        ZStack {
            // 白色矩形背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                .frame(width: DeviceType.current == .iPad ? 300 : 200 , height: DeviceType.current == .iPad ? 240 : 160)
            Button(action: { showingInput = true }) {
                VStack(alignment: .leading, spacing:ResponsiveSpacing.vertical(config)) {
                    
                    HStack(spacing: ResponsiveSpacing.horizontal(config)) {
                        // 用户头像
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: DeviceType.current == .iPad ? 100 : 50)
                            .overlay(
                                // 模拟头像内容
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: DeviceType.current == .iPad ? 60 :20))
                            )
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("昵称：\(userName)")
                                .font( ResponsiveFont.body(config))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 8) {
                                Text("性别：")
                                    .font( ResponsiveFont.body(config))
                                    .foregroundColor(.gray)
                                Text(userGender)
                                    .font( ResponsiveFont.body(config))
                                    .foregroundColor(.gray)
                            }
                            HStack {
                                Text("身高：")
                                    .font( ResponsiveFont.body(config))
                                    .foregroundColor(.gray)
                                Text("\(userHeight)cm")
                                    .font( ResponsiveFont.body(config))
                                    .foregroundColor(.gray)
                            }
                            // 徽章图标
                            HStack(spacing: DeviceType.current == .iPad ? 15:10) {
                                
                                Image("medal2")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect( DeviceType.current == .iPad ? 2 : 1.5)
                                    .frame(width:  DeviceType.current == .iPad ? 20: 15)
                                
                                Image("medal3")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect( DeviceType.current == .iPad ? 2 : 1.5)
                                    .frame(width:  DeviceType.current == .iPad ? 20: 15)
                                Image("medal1")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect( DeviceType.current == .iPad ? 2 : 1.5)
                                    .frame(width:  DeviceType.current == .iPad ? 20: 15)
                                
                            }
                            .frame(height: DeviceType.current == .iPad ? 20: 15)
                            .padding([.top,.leading], DeviceType.current == .iPad ? 10:0)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已坚持打卡21天")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("本月已完成计划3项")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .frame(width: DeviceType.current == .iPad ? 300 : 200 , height: DeviceType.current == .iPad ? 240 : 160)
                .padding(16)
                .background(Color.clear)
                
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingInput) {
                        VStack(spacing: 16) {
                            Text("请输入数据")
                                .font(.headline)

                            TextField("昵称", text: $inputname)
                                .textFieldStyle(.roundedBorder)

                            TextField("性别", text: $inputgender)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("身高 cm", text: $inputbodyheight)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)

                            

                            HStack {
                                Button("取消") {
                                    showingInput = false
                                }
                                Spacer()
                                Button("确定") {
                                    // 保存到数据库
                                    let success = userInfoStorage.saveUserInfo(
                                        username: inputname.isEmpty ? nil : inputname,
                                        gender: inputgender.isEmpty ? nil : inputgender,
                                        height: Int(inputbodyheight),
                                        weight: nil // 体重在TodayDataCard中处理
                                    )
                                    
                                    if success {
                                        // 更新父组件的状态
                                        if !inputname.isEmpty {
                                            userName = inputname
                                        }
                                        if !inputgender.isEmpty {
                                            userGender = inputgender
                                        }
                                        if let h = Int(inputbodyheight) {
                                            userHeight = h
                                        }
                                    }
                                    
                                    showingInput = false
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .presentationDetents([.height(300)]) // sheet 高度
                    }
           
            
        
         
            
            
            
        }
        
    }
}

// 今日数据卡片
struct TodayDataCard: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var showingInput = false     // 控制弹窗
    @State private var inputweight = ""
    @State private var inputtime = ""
    
    // 用户信息存储服务
    private let userInfoStorage = UserInfoStorage.shared
    
    // 从父组件的绑定参数
    @Binding var userWeight: Double
    @Binding var exerciseTime: Double

    var body: some View {
        
        let config = ResponsiveConfig(horizontal: horizontalSizeClass ?? .compact, vertical: verticalSizeClass ?? .compact)
        // 白色矩形背景
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                .frame(width:  DeviceType.current == .iPad ? 180 : 120 , height:  DeviceType.current == .iPad ? 240 : 160)
            
            // 顶层：按钮文本
            Button(action: { showingInput = true }) {
                VStack(alignment: .trailing, spacing: 8) {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("今日\(String(format: "%.2f", userWeight))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("单位：kg")
                            .font( ResponsiveFont.body(config))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        let weightChange = userInfoStorage.getWeightChange()
                        Image(systemName: weightChange.trendIcon)
                            .font( ResponsiveFont.body(config))
                            .foregroundColor(getWeightChangeColor(weightChange))
                        Text(weightChange.changeDescription)
                            .font( ResponsiveFont.body(config))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("运动时长：\(Int(exerciseTime)) min")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(SuperDateUtill.getCurrentDateForSportPage())
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .frame(width:  DeviceType.current == .iPad ? 180 : 120 , height:  DeviceType.current == .iPad ? 240 : 160)
                .background(Color.clear)
                
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingInput) {
                        VStack(spacing: 16) {
                            Text("请输入数据")
                                .font(.headline)

                            TextField("体重 kg", text: $inputweight)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)

                            TextField("运动时常 min", text: $inputtime)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)

                            

                            HStack {
                                Button("取消") {
                                    showingInput = false
                                }
                                Spacer()
                                Button("确定") {
                                    // 保存到数据库
                                    var success = false
                                    var newWeight: Double? = nil
                                    var newTime: Double? = nil
                                    
                                    if let w = Double(inputweight), w > 0 {
                                        newWeight = w
                                        success = userInfoStorage.saveUserInfo(
                                            username: nil,
                                            gender: nil,
                                            height: nil,
                                            weight: w
                                        )
                                    }
                                    
                                    if let t = Double(inputtime), t > 0 {
                                        newTime = t
                                    }
                                    
                                    if success || newTime != nil {
                                        // 更新父组件的状态
                                        if let w = newWeight {
                                            userWeight = w
                                        }
                                        if let t = newTime {
                                            exerciseTime = t
                                        }
                                    }
                                    
                                    showingInput = false
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .presentationDetents([.height(300)]) // sheet 高度
                    }
           
            
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取体重变化的颜色
    private func getWeightChangeColor(_ weightChange: WeightChangeInfo) -> Color {
        if weightChange.isIncrease {
            return .red      // 体重增加用红色
        } else if weightChange.isDecrease {
            return .green    // 体重减少用绿色
        } else {
            return .gray     // 稳定用灰色
        }
    }
    
}

// 身体数据卡片1（营养数据）
struct BodyDataCard1: View {
    @State private var showingInput = false     // 控制弹窗
    @State private var inputText = ""           // 用户输入的字符串
    @State private var inputcarbohydrates = ""
    @State private var inputprotein = ""
    @State private var inputfat = ""
    @State private var inputwater = ""
    @State private var carbohydrates : Double = 0
    @State private var protein : Double = 0
    @State private var fat : Double = 0
    @State private var water : Int   = 0
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                .frame(width: 120 , height: 160)
            ZStack {
                
                // 底层：矩形8 作为按钮背景
                Image("rec11")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124)
                
                    .offset(y:-4)
                // 上层：矩形7 覆盖在 矩形8 之上
                
                Image("rec10")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .overlay(
                        Image("food1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .offset(x: 0, y: -2)
                    )
                    .offset(x: -45, y: -2)
                
                // 顶层：按钮文本
                Button(action: { showingInput = true }) {
                    Text("点击调整")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                        .offset(x: 5,y:-5)
                    
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingInput) {
                            VStack(spacing: 16) {
                                Text("请输入数据")
                                    .font(.headline)

                                TextField("碳数 g", text: $inputcarbohydrates)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)

                                TextField("蛋白质 g", text: $inputprotein)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)

                                TextField("脂肪 g", text: $inputfat)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                
                                TextField("饮水 ml", text: $inputwater)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)

                                HStack {
                                    Button("取消") {
                                        showingInput = false
                                    }
                                    Spacer()
                                    Button("确定") {
                                        if let c = Double(inputcarbohydrates) {
                                            carbohydrates = max(0, c)
                                        }
                                        if let p = Double(inputprotein) {
                                            protein = max(0, p)
                                        }
                                        if let f = Double(inputfat) {
                                            fat = max(0, f)
                                        }
                                        if let w = Double(inputwater) {
                                            water = Int(max(0, w))
                                        }
                                        
                                        showingInput = false
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .padding()
                            .presentationDetents([.height(300)]) // sheet 高度
                        }
            }
            .offset(y: -61)
            
            
            // 营养数据
            VStack(alignment: .leading, spacing: 8) {
                NutritionRow(title: "碳水", value: Int(carbohydrates), progress: carbohydrates / 100.0,imgname: "food")
                NutritionRow(title: "蛋白质", value: Int(protein), progress: protein / 100.0,imgname: "pro")
                NutritionRow(title: "脂肪", value: Int(fat), progress: fat / 100.0,imgname: "fats")
                
                HStack(spacing: 8) {
                    Image("water1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20)
                    Text("饮水量：\(water) ml")
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                }
            }
            .frame(width: 110, height: 160)
            .background(Color.clear)
            .offset(y:20)
            
            
            
        }
    }
}

// 营养数据行
struct NutritionRow: View {
    let title: String
    let value: Int
    let progress: Double
    let imgname:String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景轨道 - 添加3D效果
                        ZStack {
                            // 渐变阴影层
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color.gray.opacity(0.4), location: 0.0),   // 顶部
                                            .init(color: Color.gray.opacity(0.2), location: 0.2),   // 中间点
                                            .init(color: Color.gray.opacity(0.0), location: 1.0)    // 底部
                                        ]),
                                        startPoint: .top,
                                        
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 20)
                                .cornerRadius(10)
                            
                            // 主轨道
                            Rectangle()
                                .fill(Color.gray.opacity(0.05))
                                .frame(height:20)
                                .cornerRadius(10)
                        }
                        
                        // 主进度条
                        Rectangle()
                            .fill(Color(hex: "#FFF7EB"))
                            .frame(width: geometry.size.width, height: 20)
                            .cornerRadius(10)
                        
                    }
                }
                .frame(height: 20)
                
                Image(imgname)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                    .offset(x: -45)
                Text("\(title)：\(value) g")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
            }
            
            
        }
        .frame(width: 110)
    }
}

// 体脂率圆环卡片
struct FatBurnRateCard: View {
    @State private var showingInput = false     // 控制弹窗
    @State private var inputText = ""           // 用户输入的字符串
    @State private var bodyfat :Int = 0
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                .frame(width: 120 , height: 160)
            ZStack {
                
                // 底层：矩形8 作为按钮背景
                Image("rec11")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124)
                
                    .offset(y:-4)
                // 上层：矩形7 覆盖在 矩形8 之上
                
                Image("rec10")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .overlay(
                        Image("fire")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20)
                            .offset(x: 0, y: -2)
                    )
                    .offset(x: -45, y: -2)
                
                // 顶层：按钮文本
                Button(action: { showingInput = true }) {
                    Text("点击调整")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                        .offset(x: 5,y:-5)
                    
                }
                .buttonStyle(.plain)
                // 弹出输入框
                .alert("输入体脂率", isPresented: $showingInput) {
                    TextField("请输入0~100之间的数值", text: $inputText)
                        .keyboardType(.decimalPad)
                    Button("确定") {
                        if let value = Int(inputText) {
                            bodyfat = value // 转换成 0~1
                        }
                    }
                    Button("取消", role: .cancel) { }
                }
            }
            .offset(y: -61)
            
            
            // 圆环进度
            ZStack {
                //底部轨道圆环
                
                Circle()
                    .stroke(Color.gray.opacity(0.2),lineWidth: 15)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.gray.opacity(0.6), radius: 2, x: 0, y: 0) //
                
                //填充圆环
                Circle()
                    .trim(from: 0, to: CGFloat(bodyfat)/100.0)
                    .stroke(Color(hex: "#FFAD98"), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(0))
                
                VStack(spacing: 2) {
                    Text("体脂率")
                        .font(.system(size: 16))
                        .foregroundColor(.black.opacity(0.7))
                    Text("\(bodyfat)%")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.red)
                }
            }
            .offset(y:10)
            
        }
    }
}

// BMI卡片
struct BMICard: View {
    let bodyHeight: Int  // 从父组件传入的身高
    let bodyWeight: Double  // 从父组件传入的体重
    
    // 计算BMI值
    private var bmiValue: Double {
        guard bodyHeight > 0 && bodyWeight > 0 else { return 0 }
        let heightInMeters = Double(bodyHeight) / 100.0
        return bodyWeight / (heightInMeters * heightInMeters)
    }
    
    // BMI等级判断
    private var bmiCategory: (text: String, color: Color) {
        if bmiValue == 0 {
            return ("未知", .gray)
        } else if bmiValue < 18.5 {
            return ("偏瘦", .blue)
        } else if bmiValue < 24 {
            return ("正常", .orange)
        } else if bmiValue < 28 {
            return ("偏胖", .yellow)
        } else {
            return ("肥胖", .red)
        }
    }
    
    // BMI显示文本
    private var bmiDisplayText: String {
        if bmiValue == 0 {
            return "未知"
        } else {
            return String(format: "%.1f", bmiValue)
        }
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                .frame(width: 120 , height: 160)
            Image("wave1")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
                .offset(y:15)
            // BMI显示区域
            
            HStack(spacing: 0) {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("BMI")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    Text(bmiDisplayText)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .offset(y: -25)
            
            ZStack {
                Image("rec14")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 55)
                Text(bmiCategory.text)
                    .font(.system(size: 16))
                    .foregroundColor(bmiCategory.color)
            }
            .offset(x:-33, y:67)
            
            
            
            
            
            
            
        }
    }
}

// 运动计划卡片
struct ExercisePlanCard: View {
    let index: Int
    
    private let exerciseData = [
        ("跑步",  "sport1",  "walk2"),
        ("排球",  "sport2",  "volleyball"),
        ("篮球",  "sport3",  "basketball"),
        ("篮球",  "sport3",  "walk2"),
    ]
    
    var body: some View {
        let data = exerciseData[index % exerciseData.count]
        ZStack {
            
            Image(data.1)
                .resizable()
                .scaledToFit()
                .frame(width: 110)
            
                .overlay(
                    
                    ZStack {
                        
                        // 底层：矩形8 作为按钮背景
                        Image("rec11")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 114)
                        
                            .offset(y:-3)
                        // 上层：矩形7 覆盖在 矩形8 之上
                        
                        Image("rec9")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .overlay(
                                Image(data.2)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20)
                                    .offset(x: -2, y: 0)
                            )
                            .offset(x: -40, y: -6)
                        
                        // 顶层：按钮文本
                        Button(action: {  }) {
                            Text("查看计划")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                                .offset(x: 5,y:-5)
                            
                        }
                        .buttonStyle(.plain)
                    }
                        .offset(y: 50))
            
        }
        
    }
}

// MARK: - 预览
#Preview("实时数据页面内容") {
    SubSportPage()
        .background(Color.gray.opacity(0.1))
}

#Preview("实时数据组件") {
    @State var height = 175
    @State var weight = 70.0
    @State var name = "用户"
    @State var gender = "男"
    @State var time = 30.0
    
    VStack(spacing: 20) {
        UserInfoCard(
            userHeight: .constant(height),
            userName: .constant(name),
            userGender: .constant(gender)
        )
        TodayDataCard(
            userWeight: .constant(weight),
            exerciseTime: .constant(time)
        )
        HStack(spacing: 12) {
            BodyDataCard1()
            FatBurnRateCard()
            BMICard(
                bodyHeight: height,
                bodyWeight: weight
            )
        }
        ExercisePlanCard(index: 0)
    }
    .padding()
    .background(Color.gray.opacity(0.4))
}
