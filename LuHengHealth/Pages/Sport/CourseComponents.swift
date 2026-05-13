//
//  CourseComponents.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

// MARK: - 课程内容组件

struct CourseContent: View {
    @State private var selectedFilter = "全部"
    
    var body: some View {
        VStack(spacing: 0) {
            // 课程轮播区域
            CourseCarouselView()
                .padding(.top, 30)
            
            // 筛选标签
            HStack(spacing: 30) {
                ForEach(["全部", "有氧", "无氧"], id: \.self) { filter in
                    Button(filter) {
                        selectedFilter = filter
                    }
                    .font(.system(size: 16, weight: selectedFilter == filter ? .bold : .regular))
                    .foregroundColor(selectedFilter == filter ? .black : .gray)
                    .underline(selectedFilter == filter)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            
            // 课程网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(0..<4) { index in
                    CourseCard(index: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
        }
    }
}

// 课程轮播视图
struct CourseCarouselView: View {
    @State private var currentIndex = 2 // 默认显示中间的课程
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let courseData = [
        ("春日热恋", "课人空白", "lunbo1"),
        ("线条的人", "复古复古天", "lunbo2"),
        ("瑜伽冥想", "放松身心", "lunbo3"),
        ("力量训练", "增肌塑形", "lunbo4"),
        ("有氧运动", "燃脂瘦身", "lunbo5")
    ]
    
    // 计算卡片X轴偏移
    private func calculateOffset(for index: Int, currentIndex: Int) -> CGFloat {
        if index == currentIndex {
            return 0 // 当前卡片居中
        } else if index < currentIndex {
            // 左边的卡片堆叠在左侧
            let distance = currentIndex - index
            return -60 - CGFloat(distance - 1) * 20
        } else {
            // 右边的卡片堆叠在右侧
            let distance = index - currentIndex
            return 60 + CGFloat(distance - 1) * 20
        }
    }
    
    // 计算卡片Y轴偏移
    private func calculateYOffset(for index: Int, currentIndex: Int) -> CGFloat {
        if index == currentIndex {
            return 0 // 当前卡片居中
        } else {
            // 非当前卡片稍微向下偏移，增加层次感
            return 10
        }
    }
    
    // 计算卡片缩放
    private func calculateScale(for index: Int, currentIndex: Int) -> CGFloat {
        if index == currentIndex {
            return 1.0 // 当前卡片正常大小
        } else {
            // 非当前卡片逐渐缩小
            let distance = abs(currentIndex - index)
            return max(0.7, 1.0 - CGFloat(distance) * 0.05)
        }
    }
    
    // 计算卡片透明度
    private func calculateOpacity(for index: Int, currentIndex: Int) -> CGFloat {
        if index == currentIndex {
            return 1.0 // 当前卡片完全不透明
        } else {
            // 非当前卡片逐渐透明，增加透明度差异
            let distance = abs(currentIndex - index)
            return max(0.2, 1.0 - CGFloat(distance) * 0.3)
        }
    }
    
    // 计算卡片层级
    private func calculateZIndex(for index: Int, currentIndex: Int) -> Double {
        if index == currentIndex {
            return 10 // 当前卡片在最上层
        } else {
            // 非当前卡片层级递减
            let distance = abs(currentIndex - index)
            return 10 - Double(distance)
        }
    }
    
    var body: some View {
        VStack {
            // 轮播容器
            ZStack {
                // 显示所有卡片，根据位置进行堆叠
                ForEach(0..<courseData.count, id: \.self) { index in
                    let isCurrent = index == currentIndex
                    let isLeft = index < currentIndex
                    let isRight = index > currentIndex
                    
                    CourseCarouselCard(
                        data: courseData[index],
                        isActive: isCurrent,
                        position: isCurrent ? .center : (isLeft ? .left : .right)
                    )
                    .offset(
                        x: calculateOffset(for: index, currentIndex: currentIndex),
                        y: calculateYOffset(for: index, currentIndex: currentIndex)
                    )
                    .scaleEffect(calculateScale(for: index, currentIndex: currentIndex))
                    .opacity(calculateOpacity(for: index, currentIndex: currentIndex))
                    .zIndex(calculateZIndex(for: index, currentIndex: currentIndex))
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
                

                
                // 左箭头
                if currentIndex > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex = max(0, currentIndex - 1)
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .opacity(0.8)
                    .offset(x: -150, y: 0)
                    .zIndex(100)
                }
                
                // 右箭头
                if currentIndex < courseData.count - 1 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex = min(courseData.count - 1, currentIndex + 1)
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                            
                    }
                    .opacity(0.8)
                    .offset(x: 150, y: 0)
                    .zIndex(100)
                }
            }
            .frame(width:350 ,height: 200)
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        isDragging = false
                        let threshold: CGFloat = 100
                        
                        if value.translation.width > threshold && currentIndex > 0 {
                            // 向右滑动，显示左下层课程
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex = max(0, currentIndex - 1)
                            }
                        } else if value.translation.width < -threshold && currentIndex < courseData.count - 1 {
                            // 向左滑动，显示右下层课程
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex = min(courseData.count - 1, currentIndex + 1)
                            }
                        }
                        
                        // 重置拖拽偏移
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
            )
            
            // 指示器
            HStack(spacing: 8) {
                ForEach(0..<courseData.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                }
            }
            .padding(.top, 0)
        }
    }
}

// 轮播卡片
struct CourseCarouselCard: View {
    let data: (String, String, String)
    let isActive: Bool
    let position: CardPosition
    
    enum CardPosition {
        case left, center, right
    }
    
    var body: some View {
        ZStack {
            // 背景图片
            Image(data.2)
                .resizable()
                .scaledToFit()
            
        }
        .scaleEffect(isActive ? 1.0 : 0.8)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// 课程卡片
struct CourseCard: View {
    let index: Int
    
    private let courseImages = [
        ("course1", Color.blue),
        ("course2", Color.purple),
        ("course3", Color.pink),
        ("course4", Color.orange)
    ]
    
    var body: some View {
        let imageData = courseImages[index % courseImages.count]
        
        VStack(alignment: .leading, spacing: 12) {
            // 课程图片
                Image(imageData.0)
                    .resizable()
                    .scaledToFit()
            
            // 课程信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("团体训练课程")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("#线下")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                
                Text("开课时间：2025-6-12")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack {
                    Text("已报名：212")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button("了解详情 >>") {
                        // Action
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal,10)
        .background(Color.clear)
    }
}

// MARK: - 预览
#Preview("课程内容") {
    ScrollView {
        CourseContent()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("课程轮播视图") {
    CourseCarouselView()
        .padding()
        .background(Color.gray.opacity(0.1))
}

#Preview("轮播卡片") {
    HStack(spacing: 16) {
        CourseCarouselCard(
            data: ("春日热恋", "课人空白", "lunbo1"),
            isActive: true,
            position: .center
        )
        CourseCarouselCard(
            data: ("线条的人", "复古复古天", "lunbo2"),
            isActive: false,
            position: .right
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("课程卡片") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 16) {
        ForEach(0..<4) { index in
            CourseCard(index: index)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
