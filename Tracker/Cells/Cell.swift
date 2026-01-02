//
//  Cell.swift
//  Tracker
//
//  Created by Волошин Александр on 1/2/26.
//

import UIKit

class Cell : UIViewController {
    let label : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Hello, World!"
        return label
    }()
}
