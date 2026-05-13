//
//  FriendsCircleComponents.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

// MARK: - 朋友圈内容组件

struct FriendsCircleContent: View {
    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 12)
                    
                    Text("搜索昵称、ID...")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    Spacer()
                }
                .frame(height: 40)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            
            // 热门活动区域
            VStack(spacing: 0) {
                HStack {
                    Text("热门活动")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("更多 >>")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                // 热门活动圆形头像
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(0..<4) { index in
                            HotActivityItem(index: index)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            
            // 最新动态区域
            VStack(spacing: 0) {
                HStack {
                    Text("最新")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                
                // 动态列表
                VStack(spacing: 0) {
                    FriendsPost(
                        username: "Tsuki",
                        time: "12:35",
                        date: "2025-5-7",
                        content: "打个卡🤔，骑行第二十天。",
                        tags: ["#美食", "#活动"],
                        likeCount: 977,
                        commentCount: 2547,
                        shareCount: 67
                    )
                    
                    FriendsPost(
                        username: "Alison",
                        time: "刚刚",
                        date: "2025-5-7",
                        content: "",
                        tags: [],
                        likeCount: 0,
                        commentCount: 0,
                        shareCount: 0
                    )
                }
                .padding(.top, 20)
            }
        }
    }
}

// 热门活动圆形头像项
struct HotActivityItem: View {
    let index: Int
    
    private let activities = [
        ("接力棒", Color.cyan),
        ("高尔夫", Color.green),
        ("棒球", Color.orange),
        ("接力棒", Color.blue)
    ]
    
    var body: some View {
        let activity = activities[index % activities.count]
        
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(activity.1.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                // 运动图标
                if activity.0 == "高尔夫" {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else if activity.0 == "棒球" {
                    Image(systemName: "baseball.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "figure.run")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                
                // 右上角时间标签（针对高尔夫）
                if activity.0 == "高尔夫" {
                    VStack {
                        HStack {
                            Spacer()
                            Text("025-5-3")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                        }
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                        Spacer()
                    }
                }
            }
            
            Text(activity.0)
                .font(.system(size: 12))
                .foregroundColor(.black)
        }
    }
}

// 朋友圈动态帖子
struct FriendsPost: View {
    let username: String
    let time: String
    let date: String
    let content: String
    let tags: [String]
    let likeCount: Int
    let commentCount: Int
    let shareCount: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // 用户信息头部
            HStack(spacing: 12) {
                // 用户头像
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(username)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 8) {
                        Text(time)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(date)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 右侧按钮
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 图片网格
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(0..<3) { index in
                    PostImageView(index: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // 内容文字
            if !content.isEmpty {
                HStack {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            
            // 标签
            if !tags.isEmpty {
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            
            // 互动数据
            if likeCount > 0 || commentCount > 0 || shareCount > 0 {
                HStack(spacing: 40) {
                    InteractionButton(icon: "heart", count: likeCount, color: .gray)
                    InteractionButton(icon: "message", count: commentCount, color: .green)
                    InteractionButton(icon: "square.and.arrow.up", count: shareCount, color: .blue)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            // 分割线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
    }
}

// 帖子图片视图
struct PostImageView: View {
    let index: Int
    
    private let images = [
        (Color.blue, "car.fill"),
        (Color.orange, "pizza"),
        (Color.brown, "cup.and.saucer.fill")
    ]
    
    var body: some View {
        let imageData = images[index % images.count]
        
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [imageData.0.opacity(0.7), imageData.0.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 80)
            .overlay(
                Image(systemName: imageData.1)
                    .font(.system(size: 25))
                    .foregroundColor(.white)
            )
    }
}

// 互动按钮
struct InteractionButton: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - 预览
#Preview("朋友圈内容") {
    ScrollView {
        FriendsCircleContent()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("热门活动项") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 20) {
            ForEach(0..<4) { index in
                HotActivityItem(index: index)
            }
        }
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}

#Preview("朋友圈动态帖子") {
    VStack(spacing: 20) {
        FriendsPost(
            username: "Tsuki",
            time: "12:35",
            date: "2025-5-7",
            content: "打个卡🤔，骑行第二十天。",
            tags: ["#美食", "#活动"],
            likeCount: 977,
            commentCount: 2547,
            shareCount: 67
        )
        
        FriendsPost(
            username: "Alison",
            time: "刚刚",
            date: "2025-5-7",
            content: "",
            tags: [],
            likeCount: 0,
            commentCount: 0,
            shareCount: 0
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("帖子图片视图") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: 8) {
        ForEach(0..<3) { index in
            PostImageView(index: index)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("互动按钮") {
    HStack(spacing: 40) {
        InteractionButton(icon: "heart", count: 977, color: .gray)
        InteractionButton(icon: "message", count: 2547, color: .green)
        InteractionButton(icon: "square.and.arrow.up", count: 67, color: .blue)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
