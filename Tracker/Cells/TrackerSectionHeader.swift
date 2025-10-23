//
//  TrackerSectionHeader.swift
//  Tracker
//
//  Created by Волошин Александр on 9/15/25.
//

import UIKit

final class TrackerSectionHeader: UICollectionReusableView {
    static let reuseId = "TrackerSectionHeader"
    
    let colors = Colors()
    let titleLabel: UILabel = {
        let l = UILabel()
        
        l.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.textColor = colors.plusColor
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
