//
//  TracerCollectionViewCell.swift
//  Tracker
//
//  Created by Малика Есипова on 10.09.2025.
//
import UIKit

protocol TrackerCollectionViewCellDelegate: AnyObject {
    func didTapCompleteButton(for tracker: Tracker, index: Int, on date: Date)
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
    
        let avatarImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()

        let titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        let daysLabel: UILabel = {
            let label = UILabel()
            label.textColor = .black
            label.font = .systemFont(ofSize: 12)
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
            
            topContainer.addSubview(avatarImageView)
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
                avatarImageView.leadingAnchor.constraint(equalTo: topContainer.leadingAnchor, constant: 12),
                avatarImageView.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: 12),
                avatarImageView.widthAnchor.constraint(equalToConstant: 24),
                avatarImageView.heightAnchor.constraint(equalToConstant: 24),

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
    func configure(with tracker: Tracker, index: Int, chooseDate: Date) {
        self.tracker = tracker
        self.idx = index
        self.chooseDate = chooseDate
        
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        let calendar = Calendar.current
        
        // Проверяем выполнение для КОНКРЕТНОЙ ДАТЫ
        let isCompletedOnSelectedDate = tracker.records.contains { record in
            calendar.isDate(record.date, inSameDayAs: chooseDate)
        }
        
        // Настраиваем кнопку
        if isCompletedOnSelectedDate {
            let checkImage = UIImage(systemName: "checkmark", withConfiguration: config)
            addButton.setImage(checkImage, for: .normal)
            addButton.backgroundColor = UIColor(named: "ypBlue")?.withAlphaComponent(0.3)
        } else {
            let plusImage = UIImage(systemName: "plus", withConfiguration: config)
            addButton.setImage(plusImage, for: .normal)
            addButton.backgroundColor = UIColor(named: "ypBlue")
        }
        
        // Блокируем кнопку если дата в будущем
        let isFutureDate = chooseDate > Date()
        addButton.isEnabled = !isFutureDate
        addButton.alpha = isFutureDate ? 0.5 : 1.0
        
        // Обновляем счетчик дней
        if tracker.daysCount % 10 == 1 {
            daysLabel.text = "\(tracker.daysCount) день"
        } else if tracker.daysCount % 10 >= 2 && tracker.daysCount % 10 <= 4 {
            daysLabel.text = "\(tracker.daysCount) дня"
        } else {
            daysLabel.text = "\(tracker.daysCount) дней"
        }
        
        titleLabel.text = tracker.name
        avatarImageView.image = UIImage(named: "crySmile")
    }
    
    @objc func trackerComplete() {
        guard let tracker = tracker else { return }
        
        // Передаем выбранную дату делегату
        delegate?.didTapCompleteButton(for: tracker, index: idx, on: chooseDate)
    }

}

