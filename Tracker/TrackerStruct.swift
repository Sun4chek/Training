//
//  TrackerStruct.swift
//  Tracker
//
//  Created by Волошин Александр on 8/30/25.
//

import UIKit
enum Typetracker {
    case habits
    case irregularEvent
}



struct Tracker {
//    let type : Typetracker?
    let id : UUID
    let name : String
//    let color : UIColor
//    let emoji : String
    let schedule: [Weekdays]
    var records: [TrackerRecord] = []
    let createDay : Date
    var daysCount: Int {
        return records.count
    }
    
    func isCompletedToday() -> Bool {
           let today = Date() // Получаем текущую дату
           let calendar = Calendar.current
           
           // Проверяем, есть ли запись с сегодняшней датой
           return records.contains { record in
               calendar.isDate(record.date, inSameDayAs: today)
           }
       }
}

struct TrackerCategory {
    let name : String
    var trackers : [Tracker]
}

struct TrackerRecord {
    let id : UUID
    let date : Date
    
    
}





