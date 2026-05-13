//
//  RecommendationCard.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/8.
//

import SwiftUI

struct SmartRecommendationView: View {
    @Binding var modelColor: Color

    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    RecommendationCard(
                        title: "天时",
                        subtitle: "气温适配色",
                        imagename: "HomeSmart1", imagename2: "HomeSmart11",
                        iconColor: Color.orange,
                        onUse: { modelColor = .black }
                    )
                    
                    RecommendationCard(
                        title: "人和",
                        subtitle: "社交热门色",
                        imagename: "HomeSmart2", imagename2: "HomeSmart22",
                        iconColor: Color.orange,
                        onUse: { modelColor = .white }
                    )
                    
                    RecommendationCard(
                        title: "心意",
                        subtitle: "压力情绪色",
                        imagename: "HomeSmart3", imagename2: "HomeSmart33",
                        iconColor: Color.orange,
                        onUse: { modelColor = .cyan }
                    )
                }
                .padding(.horizontal, 20)
            }
            .frame(width:geo.size.width, height:geo.size.height)
        }

    }
}



// MARK:  - 单个卡片
// 推荐卡片单个组件
struct RecommendationCard: View {
    let title: String
    let subtitle: String
    let imagename: String
    let imagename2: String
    let iconColor: Color
    let onUse: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            
            // 卡片图片区域
            Image(imagename)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 25)) // 保持圆角
                .frame(width: 100, height: 100)
                .overlay(
                    ZStack {
                        // 底层：矩形8 作为按钮背景
                        Image("rec8")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 108)
                            .offset(x:1)
                        // 上层：矩形7 覆盖在 矩形8 之上
                        
                        Image("rec7")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                            .overlay(
                                Image(imagename2)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30)
                                    .offset(x: -4, y: 0)
                            )
                            .offset(x: -26, y: -6)
                        
                        // 顶层：按钮文本
                        Button(action: { onUse() }) {
                            Text("立即使用")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                                .offset(x: 20)
 
                        }
                        .buttonStyle(.plain)
                    }
                    .offset(y:34)
                )

            
            // 按钮和文字
            VStack(spacing: 4) {

                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .offset(y:0)
        }
        .frame(width: 120)
        .padding(.bottom, 10)
        
    }
}

#Preview("多个卡片") {
    
    SmartRecommendationView(modelColor: .constant(.white))
}
#Preview("单个卡片组件")  {
    RecommendationCard(title: "主标题", subtitle: "副标题", imagename: "HomeSmart2", imagename2: "HomeSmart22", iconColor: .blue, onUse: {})
}
