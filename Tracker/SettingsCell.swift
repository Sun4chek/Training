//
//  SettingsCell.swift
//  Tracker
//
//  Created by Малика Есипова on 10.09.2025.
//

import UIKit
class SettingsCell: UITableViewCell {

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()

    private let chevronImageView: UIImageView = {
        let img = UIImageView(image: UIImage(systemName: "chevron.right"))
        img.tintColor = .systemGray2
        img.isHidden = true
        return img
    }()

    private var toggleSwitch: UISwitch?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .default
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        detailLabel.font = UIFont.systemFont(ofSize: 15)
        detailLabel.textColor = .gray
        detailLabel.isHidden = true
        
        let stackTitle = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stackTitle.axis = .vertical
        stackTitle.alignment = .leading
        stackTitle.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [stackTitle, chevronImageView])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .equalSpacing

        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(title: String, detail: String? = nil, accessory: SettingsCellAccessory) {
        titleLabel.text = title
        detailLabel.text = detail
        detailLabel.isHidden = detail == nil

        chevronImageView.isHidden = true
        accessoryView = nil
        toggleSwitch?.removeFromSuperview()
        toggleSwitch = nil

        switch accessory {
        case .chevron:
            chevronImageView.isHidden = false
        case .toggle(let toggle):
            toggleSwitch = toggle
            accessoryView = toggle
        case .text(let text):
            detailLabel.isHidden = false
            detailLabel.text = text
        case .none:
            break
        }
    }
}
