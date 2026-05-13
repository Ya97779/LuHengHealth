//
//  CircularProgressChart.swift
//  test
//
//  Created by macios on 2025/7/14.
//

import SwiftUI

struct CircularProgressChart: View {
    let pressure: Double      // 压力值 (0-100)
    let health: Double        // 健康值 (0-100)
    let sleep: Double         // 睡眠值 (0-100)
    
    // 控制显示哪些环形
    let showPressure: Bool
    let showHealth: Bool
    let showSleep: Bool
    
    // 环形配置
    private let strokeWidth: CGFloat = 20
    private let circleSize: CGFloat = 250
    private let ringSpacing: CGFloat = 50  // 环形之间的间距
    
    init(
        pressure: Double = 0,
        health: Double = 0,
        sleep: Double = 0,
        showPressure: Bool = true,
        showHealth: Bool = true,
        showSleep: Bool = true
    ) {
        self.pressure = pressure
        self.health = health
        self.sleep = sleep
        self.showPressure = showPressure
        self.showHealth = showHealth
        self.showSleep = showSleep
    }
    
    var body: some View {
        ZStack {
            // 背景透明
            Color.clear
            
            // 最内层：压力环形 (红色) - 270度弧形
            if showPressure {
                Circle()
                    .trim(from: 0.0, to: 0.75) // 270度 = 0.75
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .opacity(0.3)
                    .foregroundColor(.red)
                    .rotationEffect(Angle(degrees: 135)) // 270/2 = 135度
                    .frame(width: circleSize - ringSpacing * 2, height: circleSize - ringSpacing * 2)
                
                Circle()
                    .trim(from: 0.0, to: (pressure / 100) * 0.75) // 根据压力值计算270度内的进度
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.red)
                    .rotationEffect(Angle(degrees: 135)) // 270/2 = 135度
                    .frame(width: circleSize - ringSpacing * 2, height: circleSize - ringSpacing * 2)
                    .animation(.linear(duration: 1.0), value: pressure)
            }
            
            // 中间层：健康环形 (绿色渐变) - 270度弧形
            if showHealth {
                Circle()
                    .trim(from: 0.0, to: 0.75) // 270度 = 0.75
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .opacity(0.3)
                    .foregroundColor(.green)
                    .rotationEffect(Angle(degrees: 135)) // 270/2 = 135度
                    .frame(width: circleSize - ringSpacing, height: circleSize - ringSpacing)
                
                Circle()
                    .trim(from: 0.0, to: (health / 100) * 0.75) // 根据健康值计算270度内的进度
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.green.opacity(0.8))
                    .rotationEffect(Angle(degrees: 135)) // 270/2 = 135度
                    .frame(width: circleSize - ringSpacing, height: circleSize - ringSpacing)
                    .animation(.linear(duration: 1.0), value: health)
            }
            
            // 最外层：睡眠环形 (蓝色) - 270度弧形
            if showSleep {
                Circle()
                    .trim(from: 0.0, to: 0.75) // 270度 = 0.75
                    .stroke(lineWidth: strokeWidth)
                    .opacity(0.3)
                    .foregroundColor(.orange.opacity(0.7))
                    .rotationEffect(Angle(degrees: 135)) // 270/2 = 135度
                    .frame(width: circleSize, height: circleSize)
                
                Circle()
                    .trim(from: 0.0, to: (sleep / 100) * 0.75) // 根据睡眠值计算270度内的进度
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.yellow)
                    .rotationEffect(Angle(degrees: 135)) // 270/2 = 135度
                    .frame(width: circleSize, height: circleSize)
                    .animation(.linear(duration: 1.0), value: sleep)
            }
            
            // 中心内容
            VStack(spacing: 8) {
                // 主要百分比显示
                Text("\(Int(health))%")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.black)
                
                // 健康状态文字
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                    Text("健康")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
            }
            
            // 三个小图标 (分别放在对应圆环的起点位置)
            if showPressure {
                // 压力图标 - 放在压力圆环起点 (135度位置)
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 30, height: 30)
                    Image(systemName: "face.smiling")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .offset(
                    x: -sin(Angle(degrees: 135).radians) * (circleSize - ringSpacing * 2) / 2,
                    y: -cos(Angle(degrees: 135).radians) * (circleSize - ringSpacing * 2) / 2
                )
            }
            
            if showHealth {
                // 健康图标 - 放在健康圆环起点 (135度位置)
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 30, height: 30)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .offset(
                    x: -sin(Angle(degrees: 135).radians) * (circleSize - ringSpacing) / 2,
                    y: -cos(Angle(degrees: 135).radians) * (circleSize - ringSpacing) / 2
                )
            }
            
            if showSleep {
                // 睡眠图标 - 放在睡眠圆环起点 (135度位置)
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 30, height: 30)
                    HStack(spacing: 2) {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                        Text("Z")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .offset(
                    x: -sin(Angle(degrees: 135).radians) * circleSize / 2,
                    y: -cos(Angle(degrees: 135).radians) * circleSize / 2
                )
            }
        }
        .frame(width: circleSize, height: circleSize)
    }
}



#Preview {
    VStack(spacing: 30) {
        // 显示所有环形
        CircularProgressChart(
            pressure: 26,
            health: 87,
            sleep: 75,
            showPressure: true,
            showHealth: true,
            showSleep: true
        )
        
        // 只显示健康环形
        CircularProgressChart(
            pressure: 0,
            health: 87,
            sleep: 0,
            showPressure: false,
            showHealth: true,
            showSleep: false
        )
        
        // 只显示压力和睡眠环形
        CircularProgressChart(
            pressure: 26,
            health: 0,
            sleep: 75,
            showPressure: true,
            showHealth: false,
            showSleep: true
        )
    }
    .background(Color.orange.opacity(0.3))
    .padding()
}
