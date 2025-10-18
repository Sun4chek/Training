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
    private let checkmarkImageView: UIImageView = {
        let img = UIImageView(image: UIImage(systemName: "checkmark"))
        img.tintColor = .systemBlue
        
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
        titleLabel.font = UIFont(name: "SFProText-Regular", size: 17)
        detailLabel.font = UIFont(name: "SFProText-Regular", size: 17)
        detailLabel.textColor = .gray
        detailLabel.isHidden = true

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let rightStack = UIStackView(arrangedSubviews: [checkmarkImageView, chevronImageView])
        rightStack.axis = .horizontal
        rightStack.alignment = .center
        rightStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [textStack, rightStack])
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.distribution = .equalSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(title: String, detail: String? = nil, accessory: SettingsCellAccessory) {
        titleLabel.text = title
        detailLabel.text = detail
        detailLabel.isHidden = detail == nil

        chevronImageView.isHidden = true
        checkmarkImageView.isHidden = true
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
        case .checkmark(let visible):
            checkmarkImageView.isHidden = !visible
        case .none:
            break
        }
    }
}

