//
//  TrackerStruct.swift
//  Tracker
//
//  Created by Волошин Александр on 8/30/25.
//

import UIKit

struct Tracker {
    let id : UUID
    let name : String
    let color : UIColor
    let emoji : String
    let schedule: [Weekdays]
}

struct TrackerCategory {
    let name : String
    let trackers : [Tracker]
}

struct TrackerRecord {
    let id : UUID
    let date : Date
}





