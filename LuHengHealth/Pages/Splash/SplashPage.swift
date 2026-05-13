//
//  SwiftUIView.swift
//  test
//
//  Created by macios on 2025/7/11.
//

import SwiftUI

struct SplashPage: View {
    var body: some View {

        ZStack{
            Color(.systemPink)
                .ignoresSafeArea(.all)
            
            StaticContent(year: SuperDateUtill.CurrentYear())
            
        }
    }
}

// MARK:  - 静态内容
struct StaticContent: View {
    let year: Int
    var body: some View {
        
        VStack{
//            
//            Spacer()
//                .frame(height: 120)
            
            Image(systemName:"sun.min" )
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(.bottom,220)
                .foregroundStyle(.white)
            

            
            Text("Copyright ©\(year) LuHeng. All Rights Reserved")
                .foregroundStyle(.white)
                .font(.system(size: 13))
                .padding(.top,300)
            
        }
    }
}

#Preview {
    SplashPage()
}
