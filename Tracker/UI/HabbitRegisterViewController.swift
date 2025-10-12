import UIKit

// MARK: - Модель

struct SettingsOption {
    let title: String
    var detail: String?            // строка для показа под заголовком, например "Пн, Пт"
    var accessory: SettingsCellAccessory
    var selectedDays: [Weekdays]?  // реальная структура выбранных дней
}


enum SettingsCellAccessory {
    case chevron
    case toggle(UISwitch)
    case text(String)
    case none
}

protocol HabbitRegisterViewControllerDelegate: AnyObject {
    func didCreateNewTracker(_ tracker: Tracker)
}

// MARK: - Контроллер

class HabbitRegisterViewController: UIViewController {
    
    
    private var selectedEmojiIndexPath: IndexPath?
    private var selectedColorIndexPath: IndexPath?
    let itemsPerRow: CGFloat = 6
    let spacing: CGFloat = 5
    let sectionInsets = UIEdgeInsets(top: 24, left: 18, bottom: 40, right: 18)
    
    let emojiSet  :  [String] = ["🙂","😻","🌺","🐶","❤️","😱","😇","😡","🥶","🤔","🙌","🍔","🥦","🏓","🥇","🎸","🏝️","😪"]
    let colors : [String] = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18"]
    
    private var selectedCategory: String = "Важное"
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    weak var delegate: HabbitRegisterViewControllerDelegate?
    
    // высота таблицы (мы будем менять .constant после layout)
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private let rowHeight: CGFloat = 75
    private var habitTitle: String?
    private var selectedDays: [Weekdays] = []
    
    private var options: [SettingsOption] = [
        SettingsOption(title: "Категория", detail: "Важное", accessory: .chevron),
        SettingsOption(title: "Расписание", detail: nil, accessory: .chevron,selectedDays: [])
    ]
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProText-Regular", size: 17)
        label.text = "Ограничение 38 символов"
        label.textColor = .red
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true // скрыт по умолчанию
        return label
    }()
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите название трекера"
        tf.font = UIFont(name: "SFProText-Regular", size: 17)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 16
        tf.clearButtonMode = .whileEditing
        tf.textAlignment = .left
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private var scheduleOrCategoryTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.backgroundColor = .clear
        table.separatorStyle = .singleLine
        table.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
        table.isScrollEnabled = false
        table.layer.cornerRadius = 12
        table.clipsToBounds = true
        table.allowsSelection = true
        table.delaysContentTouches = false
        table.tableFooterView = UIView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.widthAnchor.constraint(equalToConstant: 166).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return button
    }()
    
    private lazy var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.backgroundColor = .createBtnNA
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.widthAnchor.constraint(equalToConstant: 166).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        return button
    }()
    
    
    
    private let emojiAndColorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(TrackerCreateCell.self, forCellWithReuseIdentifier: "TrackerCreateCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(SectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "Header")
        collectionView.isScrollEnabled = false

        return collectionView
    }()
    
    private func updateCreateButtonState() {
        let hasText = !(nameTextField.text?.isEmpty ?? true)
        let hasSchedule = !(options[1].selectedDays?.isEmpty ?? true)
        let hasSelectedEmoji = selectedEmojiIndexPath != nil
        let hasSelectedColor = selectedColorIndexPath != nil
        
        let isReady = hasText && hasSchedule && hasSelectedEmoji && hasSelectedColor
        
        createButton.isEnabled = isReady
        createButton.backgroundColor = isReady ? .black : .systemGray6
        createButton.setTitleColor(isReady ? .white : .systemGray, for: .normal)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        nameTextField.returnKeyType = .done
        scheduleOrCategoryTableView.dataSource = self
        scheduleOrCategoryTableView.delegate = self
                emojiAndColorCollectionView.dataSource = self
                emojiAndColorCollectionView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        
        view.backgroundColor = .systemBackground
        navigationItem.title = "Новая привычка"
        navigationItem.hidesBackButton = true
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        setupUI()
        // reload чтобы заполнить contentSize
        scheduleOrCategoryTableView.reloadData()
    }
    
  
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Обновляем высоту таблицы по её contentSize — это важно
        scheduleOrCategoryTableView.layoutIfNeeded()
        let height = scheduleOrCategoryTableView.contentSize.height
        if tableViewHeightConstraint?.constant != height {
            tableViewHeightConstraint?.constant = height
            // если нужно, можно анимировать, но не обязательно
        }
        
        let collectionHeight = calculateCollectionViewHeight()
           emojiAndColorCollectionView.heightAnchor.constraint(equalToConstant: collectionHeight).isActive = true
    }
    
    // MARK: - UI setup
 
    
    
    
    private func setupUI() {
        // добавляем scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide
        
        NSLayoutConstraint.activate([
            // Привязки по контенту
            contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 16),  // боковой inset
            contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -16),
            
            
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // ширина contentView = ширина frame - 32 (16+16) — гарантирует корректную область для сабвью
            contentView.widthAnchor.constraint(equalTo: frameGuide.widthAnchor, constant: -32)
        ])
        
        let stack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually   // <-- это автоматически задаст одинаковую ширину
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        // Добавляем сабвью внутрь contentView
        contentView.addSubview(nameTextField)
        contentView.addSubview(warningLabel)
        contentView.addSubview(scheduleOrCategoryTableView)
        contentView.addSubview(emojiAndColorCollectionView)
        contentView.addSubview(stack)
        
        
        
        
        // Констрейнты для текстового поля
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameTextField.heightAnchor.constraint(equalToConstant: 75)
        ])
        
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            warningLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: emojiAndColorCollectionView.bottomAnchor, constant: 16),
               stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
               stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            cancelButton.heightAnchor.constraint(equalToConstant: 75),
            createButton.heightAnchor.constraint(equalToConstant: 75)
        ])
        contentView.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 24).isActive = true
        
        // Констрейнты для таблицы: top, leading, trailing, height; а также bottom привязка к contentView.bottom
        tableViewHeightConstraint = scheduleOrCategoryTableView.heightAnchor.constraint(equalToConstant: CGFloat(options.count) * rowHeight)
        tableViewHeightConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            scheduleOrCategoryTableView.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 24),
            scheduleOrCategoryTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scheduleOrCategoryTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
        ])
        
        
        
        NSLayoutConstraint.activate([
            emojiAndColorCollectionView.topAnchor.constraint(equalTo: scheduleOrCategoryTableView.bottomAnchor, constant: 32),
            emojiAndColorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor ),
            emojiAndColorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
             // пример, потом можно вычислить динамически
            ])
            
    }
    
    
    private func calculateCollectionViewHeight() -> CGFloat {
        let numberOfSections = 2
        let itemsPerSection = emojiSet.count // предполагаем, что в обеих секциях одинаковое количество
        
        // Высота заголовков секций
        let headerHeight: CGFloat = 32
        let totalHeadersHeight = CGFloat(numberOfSections) * headerHeight
        
        // Высота отступов секций
        let sectionInsetsTop: CGFloat = 24
        let sectionInsetsBottom: CGFloat = 40
        let totalInsetsHeight = CGFloat(numberOfSections) * (sectionInsetsTop + sectionInsetsBottom)
        
        // Расчет количества строк в секции
        let itemsPerRow: CGFloat = 6
        let rowsPerSection = ceil(CGFloat(itemsPerSection) / itemsPerRow)
        
        // Высота одной ячейки
        let availableWidth = view.bounds.width - 32 - 4 // ширина contentView - отступы
        let totalSpacing = sectionInsets.left + sectionInsets.right + (itemsPerRow - 1) * spacing
        let itemWidth = (availableWidth - totalSpacing) / itemsPerRow
        let cellHeight = itemWidth
        
        // Общая высота ячеек
        let totalCellsHeight = CGFloat(numberOfSections) * rowsPerSection * cellHeight
        
        // Общая высота коллекции
        let totalHeight = totalHeadersHeight + totalInsetsHeight + totalCellsHeight
        
        return totalHeight
    }

    
    
    
    private func openScheduleScreen() {
        let vc = ScheduleViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "Расписание"
        navigationController?.pushViewController(vc, animated: true)
    }
    
// MARK: - objc methods
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        updateCreateButtonState()
        habitTitle = textField.text
    }
    
    @objc private func createButtonTapped() {
        guard let habitTitle = nameTextField.text,
              !habitTitle.isEmpty,
              let emojiIndexPath = selectedEmojiIndexPath,
              let colorIndexPath = selectedColorIndexPath else {
            return
        }
        
        let selectedEmoji = emojiSet[emojiIndexPath.row]
        let selectedColorName = colors[colorIndexPath.row]
        
        // Преобразуем название цвета в UIColor
        let selectedColor = UIColor(named: selectedColorName) ?? .blue
        
        let newTracker = Tracker(
            id: UUID(),
            name: habitTitle,
            color: selectedColor,  // теперь передаем UIColor
            emoji: selectedEmoji,
            schedule: selectedDays
        )
        
        delegate?.didCreateNewTracker(newTracker)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension HabbitRegisterViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as! SettingsCell
        cell.configure(title: option.title, detail: option.detail, accessory: option.accessory)
        cell.backgroundColor = .secondarySystemBackground
        cell.contentView.backgroundColor = .secondarySystemBackground
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HabbitRegisterViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            print("Открыть экран выбора категории")
            // push category screen
            let vc = UIViewController()
            vc.view.backgroundColor = .systemBackground
            vc.title = "Категории"
            navigationController?.pushViewController(vc, animated: true)
        case 1:
            print("Открыть экран расписания")
            let vc = ScheduleViewController()
            vc.delegate = self
            vc.mainIndex = indexPath.row
            
            if let saved = options[indexPath.row].selectedDays {
                vc.selectedDays = Set(saved) // преобразуем Array -> Set
            } else {
                vc.selectedDays = []
            }
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == options.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}

// MARK: - ScheduleDelegate

extension HabbitRegisterViewController: ScheduleViewControllerDelegate {
    func scheduleViewController(_ vc: ScheduleViewController, didselect days: [Weekdays], atIndex index: Int?) {
        guard let idx = index else { return }
        options[idx].selectedDays = days
        selectedDays = days
        options[idx].detail = days.map { $0.short }.joined(separator: ", ")
        scheduleOrCategoryTableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
        
        updateCreateButtonState()
    }
}

// MARK: - UITextFieldDelegate
extension HabbitRegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Скрываем клавиатуру при нажатии на кнопку "Готово"
        
        
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let currentText = textField.text as NSString? else { return true }
        let newText = currentText.replacingCharacters(in: range, with: string)
        
        let maxLength: Int = 38
        
        if newText.count > maxLength {
            warningLabel.isHidden = false
            
        } else {
            warningLabel.isHidden = true
        }
        
        return newText.count <= maxLength
    }
}


// MARK: - UICollectionViewDataSource
extension HabbitRegisterViewController : UICollectionViewDataSource {
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return emojiSet.count
        } else {
            return colors.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCreateCell", for: indexPath) as! TrackerCreateCell
        
        if indexPath.section == 0 {
            cell.config(type: .image, name : emojiSet[indexPath.row] )
        } else {
            cell.config(type: .color, name : colors[indexPath.row] )
        }
        
        return cell
    }
    
    
}

// MARK: - UICollectionViewDelegate
extension HabbitRegisterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            // Emoji секция
            if let previous = selectedEmojiIndexPath {
                // Снимаем выделение с предыдущего emoji
                if let cell = collectionView.cellForItem(at: previous) as? TrackerCreateCell {
                    cell.deselect()
                }
            }
            // Выделяем новый emoji
            if let cell = collectionView.cellForItem(at: indexPath) as? TrackerCreateCell {
                cell.select()
            }
            selectedEmojiIndexPath = indexPath
            
        } else if indexPath.section == 1 {
            // Цвета секция
            if let previous = selectedColorIndexPath {
                // Снимаем выделение с предыдущего цвета
                if let cell = collectionView.cellForItem(at: previous) as? TrackerCreateCell {
                    cell.deselect()
                }
            }
            // Выделяем новый цвет
            if let cell = collectionView.cellForItem(at: indexPath) as? TrackerCreateCell {
                cell.select()
            }
            selectedColorIndexPath = indexPath
        }
        updateCreateButtonState()
    }
    

}

// MARK: - UICollectionViewDelegateFlowLayout
extension HabbitRegisterViewController: UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // секция 0 = Emoji, секция 1 = Цвета
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: "Header",
                                                                     for: indexPath) as! SectionHeader
        header.label.text = indexPath.section == 0 ? "Emoji" : "Цвета"
        return header
    }

    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        // верни ноль, если заголовок не нужен; сейчас вернём высоту 44
        return CGSize(width: collectionView.bounds.width, height: 32)
    }
    
    

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = sectionInsets.left + sectionInsets.right + (itemsPerRow - 1) * spacing
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 2, bottom: 40, right: 2)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0 // ячейка строго под ячейкой
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5 // отступ между ячейками по горизонтали
    }
}



