//
//  WeekDays.swift
//  Tracker
//
//  Created by Волошин Александр on 9/26/25.
//

enum Weekdays: Int , CaseIterable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday  // Исправлена опечатка: monday вместо mondey
    
    var title: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
        
    var short: String {
        switch self {
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        case .sunday: return "Вс"
        }
    }
    
    static func fromString(_ string: String) -> Weekdays? {
            switch string.lowercased() {
            case "понедельник": return .monday
            case "вторник": return .tuesday
            case "среда": return .wednesday
            case "четверг": return .thursday
            case "пятница": return .friday
            case "суббота": return .saturday
            case "воскресенье": return .sunday
            default: return nil
            }
        }
    
}
