//
//  QuickAdjustMorePage.swift
//  LuHengHeath
//
//  Created by macios on 2025/8/4.
//

import SwiftUI

struct QuickAdjustMorePage: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var moreColor : Color
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
                Text("快速调节")
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
                
              ColorPicker("颜色调节", selection: $moreColor)
                    .padding()
                    .labelsHidden()
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    QuickAdjustMorePage(moreColor: .constant(.red))
}
