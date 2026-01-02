//
//  Analitics.swift
//  Tracker
//
//  Created by Волошин Александр on 10/23/25.
//

import Foundation
import AppMetricaCore

final class AnalyticsService {
    
    private static let defaultScreen = "Main"
    
    static var sendEventOverride: ((String, String, String?) -> Void)?
    
    static func trackOpen(screen: String? = nil) {
        sendEvent(event: "open", screen: screen ?? defaultScreen)
    }
    
    static func trackClose(screen: String? = nil) {
        sendEvent(event: "close", screen: screen ?? defaultScreen)
    }
    
    static func trackClick(item: String, screen: String? = nil) {
        sendEvent(event: "click", screen: screen ?? defaultScreen, item: item)
    }
    
    private static func sendEvent(event: String, screen: String, item: String? = nil) {
        if let override = sendEventOverride {
            override(event, screen, item)
            return
        }
        
        var attributes: [String: Any] = [
            "event": event,
            "screen": screen
        ]
        if let item {
            attributes["item"] = item
        }
        
        print("📊 Analytics event: \(attributes)")
        AppMetrica.reportEvent(name: "user_action", parameters: attributes) { error in
            print("❌ Analytics error: \(error.localizedDescription)")
        }
    }
}
