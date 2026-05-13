//
//  InspirationLibraryPage.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

struct InspirationLibraryPage: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // 自定义顶部导航栏
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
                Text("灵感库")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                // 占位空间，保持标题居中
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("返回")
                        .font(.system(size: 16))
                }
                .opacity(0) // 隐藏但占位
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 20)
            
            // 页面内容
            VStack {
                Spacer()
                
                Text("灵感库")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Text("这里是智能推荐的灵感库页面")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    InspirationLibraryPage()
}
