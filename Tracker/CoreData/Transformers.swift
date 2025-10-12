//
//  Transformers.swift
//  Tracker
//
//  Created by Волошин Александр on 9/26/25.
//

import Foundation

@objc(WeekdaysTransformer)
final class WeekdaysTransformer: ValueTransformer {

    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let weekdays = value as? [Weekdays] else { return nil }
        do {
            let data = try JSONEncoder().encode(weekdays.map { $0.rawValue })
            return data
        } catch {
            print("Ошибка при кодировании Weekdays: \(error)")
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            let rawValues = try JSONDecoder().decode([Int].self, from: data)
            return rawValues.compactMap { Weekdays(rawValue: $0) }
        } catch {
            print("Ошибка при декодировании Weekdays: \(error)")
            return nil
        }
    }
}



import UIKit

@objc(UIColorTransformer)
final class UIColorTransformer: ValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        do {
            let components = color.cgColor.components ?? []
            let data = try JSONEncoder().encode(components)
            return data
        } catch {
            print("Ошибка кодирования UIColor: \(error)")
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            let components = try JSONDecoder().decode([CGFloat].self, from: data)
            switch components.count {
            case 2:
                return UIColor(white: components[0], alpha: components[1])
            case 4:
                return UIColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
            default:
                return UIColor.gray
            }
        } catch {
            print("Ошибка декодирования UIColor: \(error)")
            return UIColor.gray
        }
    }
}
