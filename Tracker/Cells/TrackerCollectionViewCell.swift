//
//  TracerCollectionViewCell.swift
//  Tracker
//
//  Created by Малика Есипова on 10.09.2025.
//
import UIKit

protocol TrackerCollectionViewCellDelegate: AnyObject {
    func didTapCompleteButton(for tracker: Tracker,in date : Date, isCompleted : Bool)
}


final class TrackerCollectionViewCell : UICollectionViewCell {
    
    weak var delegate: TrackerCollectionViewCellDelegate?
    private var tracker: Tracker?
    private var isCompleted = false
    private var idx : Int = -1
    private var chooseDate: Date = Date()
    
        // Зеленый контейнер для верхней части
        let topContainer: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(named: "ypBlue")// #4CAF50
            view.layer.cornerRadius = 16
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
    
    let allContainer: UIView = {
       let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let avatarView : UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let avatarLabel : UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont(name: "SFProText-Medium", size: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 22).isActive = true
        label.widthAnchor.constraint(equalToConstant: 16).isActive = true
        return label
    }()
 
        let titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            
            label.font = UIFont(name: "SFProText-Medium", size: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        let daysLabel: UILabel = {
            let label = UILabel()
            label.textColor = .black
            label.font = UIFont(name: "SFProText-Medium", size: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        let addButton: UIButton = {
            let button = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            let plusImage = UIImage(systemName: "plus", withConfiguration: config)
            button.setImage(plusImage, for: .normal)
            button.tintColor = .white
            button.backgroundColor = UIColor(named: "ypBlue")
            button.layer.cornerRadius = 18
            button.addTarget(self, action: #selector(trackerComplete), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()


        override init(frame: CGRect) {
            super.init(frame: frame)
            setupCell()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupCell() {
            contentView.backgroundColor = .clear // Прозрачный фон для ячейки (или .black для темного)

            contentView.addSubview(allContainer)
            contentView.addSubview(topContainer)
            
            topContainer.addSubview(avatarView)
            
            topContainer.addSubview(avatarLabel)
            
            topContainer.addSubview(titleLabel)
            
            contentView.addSubview(daysLabel)
            contentView.addSubview(addButton)

            // Автолейаут
            NSLayoutConstraint.activate([
                
                
                allContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
                allContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                allContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                allContainer.heightAnchor.constraint(equalTo: contentView.heightAnchor),
                // Верхний контейнер
                topContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                topContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                topContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
                topContainer.heightAnchor.constraint(equalToConstant: 90), // Высота верхней части (подгоните под дизайн)

                // Эмодзи внутри контейнера
                
                
                avatarView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: 12),
                avatarView.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: 12),
                avatarView.widthAnchor.constraint(equalToConstant: 24),
                avatarView.heightAnchor.constraint(equalToConstant: 24),
                
                avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
                avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),

                // Заголовок внутри контейнера
                
                
                titleLabel.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: 12),
                titleLabel.bottomAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: -12),
                titleLabel.trailingAnchor.constraint(equalTo: topContainer.trailingAnchor, constant: -12),

                // Нижняя часть: дни
                daysLabel.leadingAnchor.constraint(equalTo: allContainer.leadingAnchor, constant: 12),
                daysLabel.topAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: 16),

                // Кнопка +
                addButton.trailingAnchor.constraint(equalTo: allContainer.trailingAnchor, constant: -12),
                addButton.topAnchor.constraint(equalTo: topContainer.bottomAnchor, constant: 8),
                addButton.widthAnchor.constraint(equalToConstant: 34),
                addButton.heightAnchor.constraint(equalToConstant: 34)
            ])
        }

        // Метод для конфигурации
    func configure(with tracker: Tracker, index: Int, isCompleted: Bool, selectDate: Date,completedDays: Int) {
        self.tracker = tracker
        self.idx = index
        self.isCompleted = isCompleted        // <- обязательно сохраняем
        self.chooseDate = selectDate
        
        
        updateButtonAppearance()
        avatarLabel.text = tracker.emoji
        titleLabel.text = tracker.name
        topContainer.backgroundColor = tracker.color
        
        addButton.backgroundColor = tracker.color
        daysLabel.text = "\(completedDays) \(pluralizedDays(completedDays))"
        
        addButton.alpha = isCompleted ? 0.3 : 1.0
    }
    
    
    private func pluralizedDays(_ count: Int) -> String {
        switch count % 10 {
        case 1 where count % 100 != 11: return "день"
        case 2...4 where !(12...14).contains(count % 100): return "дня"
        default: return "дней"
        }
    }
    private func updateButtonAppearance() {
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        if isCompleted {
            let checkImage = UIImage(systemName: "checkmark", withConfiguration: config)
            addButton.setImage(checkImage, for: .normal)
            addButton.backgroundColor = UIColor(named: "ypBlue")?.withAlphaComponent(0.3)
        } else {
            let plusImage = UIImage(systemName: "plus", withConfiguration: config)
            addButton.setImage(plusImage, for: .normal)
            addButton.backgroundColor = UIColor(named: "ypBlue")
        }
        // блокирование кнопки для будущих дат:
        let isFutureDate = chooseDate > Date()
        addButton.isEnabled = !isFutureDate
        addButton.alpha = isFutureDate ? 0.5 : 1.0
    }

    
    @objc func trackerComplete() {
        guard let tracker = tracker else { return }
        self.isCompleted.toggle()
        updateButtonAppearance()                                    // сразу обновляем UI
        delegate?.didTapCompleteButton(for: tracker, in: chooseDate, isCompleted: isCompleted)
    }

}

