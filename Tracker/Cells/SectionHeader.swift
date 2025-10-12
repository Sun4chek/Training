//
//  SectionHeader.swift
//  Tracker
//
//  Created by Волошин Александр on 9/22/25.
//

import UIKit

class SectionHeader: UICollectionReusableView {
    let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        label.font = UIFont.systemFont(ofSize: 19, weight: .semibold)
    }
    required init?(coder: NSCoder) { fatalError() }
}
