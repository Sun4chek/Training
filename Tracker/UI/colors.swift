//
//  colors.swift
//  Tracker
//
//  Created by Волошин Александр on 10/22/25.
//

import UIKit

final class Colors {
    let backgroundColor : UIColor = .systemBackground
    
    let plusColor = UIColor { (traits: UITraitCollection) -> UIColor in
        if traits.userInterfaceStyle == .light {
            return UIColor(resource: .ypBlack)                                  // светлый режим
        } else {
            return .white
        }
    }
    
}
