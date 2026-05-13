//
//  SuperDateUtill.swift
//  test
//  日期管理工具
//  Created by macios on 2025/7/11.
//

import Foundation

class SuperDateUtill {
    
    static func CurrentYear() -> Int {
        let date = Date()
        
        let calender = Calendar.current
        
        let d = calender.dateComponents([.year,.month,.day],from: date)
        
        return d.year ?? 0
    }
    
    
    static func getCurrentDateForHealthLog() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: Date())
    }
    
    static func getCurrentDateForSportPage() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
