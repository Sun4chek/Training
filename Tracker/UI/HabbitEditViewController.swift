import UIKit

protocol HabitEditViewControllerDelegate: AnyObject {
    func didUpdateTracker(_ tracker: Tracker, categoryName: String)
}

final class HabitEditViewController: UIViewController {
    
    
  
    // MARK: - Properties
    weak var delegate: HabitEditViewControllerDelegate?
    private var tracker: Tracker
    private var originalCategory: String
    private var completedDays: Int
    
    // MARK: - UI Components (копируем из HabbitRegisterViewController)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private var completedDaysLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProText-Regular", size: 17)
        let maxLenth = NSLocalizedString("maxLenth", comment: "")
        label.text = maxLenth
        label.textColor = .red
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        let trackerName = NSLocalizedString("trackerName", comment: "")
        tf.placeholder = trackerName
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
    
    private let scheduleOrCategoryTableView: UITableView = {
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
        let cancel = NSLocalizedString("cancel", comment: "")
        button.setTitle(cancel, for: .normal)
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
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        let save = NSLocalizedString("save", comment: "Сохранить")
        button.setTitle(save, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.backgroundColor = .black
        button.layer.cornerRadius = 16
        button.isEnabled = true
        button.widthAnchor.constraint(equalToConstant: 166).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
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
    
    // MARK: - Data
    private let emojiSet = ["🙂","😻","🌺","🐶","❤️","😱","😇","😡","🥶","🤔","🙌","🍔","🥦","🏓","🥇","🎸","🏝️","😪"]
    private let colors = ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18"]
    private var selectedEmojiIndexPath: IndexPath?
    private var selectedColorIndexPath: IndexPath?
    private var selectedCategory: String = ""
    private var selectedDays: [Weekdays] = []
    
    private var options: [SettingsOption] = {
        let mainCategory = NSLocalizedString("mainCategory", comment: "")
        let schedule = NSLocalizedString("schedule", comment: "")
        return [
            SettingsOption(title: mainCategory, detail: nil, accessory: .chevron),
            SettingsOption(title: schedule, detail: nil, accessory: .chevron, selectedDays: [])
        ]
    }()
    
    private let itemsPerRow: CGFloat = 6
    private let spacing: CGFloat = 5
    private let sectionInsets = UIEdgeInsets(top: 24, left: 18, bottom: 40, right: 18)
    private let rowHeight: CGFloat = 75
    private var tableViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    init(tracker: Tracker, categoryName: String, completedDays: Int) {
        self.tracker = tracker
        self.originalCategory = categoryName
        self.completedDays = completedDays
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithTracker()
        updateCompletedDaysLabel()
        
        nameTextField.delegate = self
        nameTextField.returnKeyType = .done
        scheduleOrCategoryTableView.dataSource = self
        scheduleOrCategoryTableView.delegate = self
        emojiAndColorCollectionView.dataSource = self
        emojiAndColorCollectionView.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scheduleOrCategoryTableView.layoutIfNeeded()
        let height = scheduleOrCategoryTableView.contentSize.height
        if tableViewHeightConstraint?.constant != height {
            tableViewHeightConstraint?.constant = height
        }
    }
    
    // MARK: - Private methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        let editHabbit = NSLocalizedString("editHabbit", comment: "Редактирование привычки")
        navigationItem.title = editHabbit
        navigationItem.hidesBackButton = true
        
        // ScrollView setup
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
            contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: frameGuide.widthAnchor, constant: -32)
        ])
        
        // Stack for buttons
        let stack = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(completedDaysLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(warningLabel)
        contentView.addSubview(scheduleOrCategoryTableView)
        contentView.addSubview(emojiAndColorCollectionView)
        contentView.addSubview(stack)
        
        completedDaysLabel.text = "\(completedDays)"
        // Constraints
        NSLayoutConstraint.activate([
            completedDaysLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            completedDaysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            completedDaysLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            completedDaysLabel.heightAnchor.constraint(equalToConstant: 38),
            
            nameTextField.topAnchor.constraint(equalTo: completedDaysLabel.bottomAnchor, constant: 40),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),
            
            warningLabel.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            warningLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            scheduleOrCategoryTableView.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 24),
            scheduleOrCategoryTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scheduleOrCategoryTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            emojiAndColorCollectionView.topAnchor.constraint(equalTo: scheduleOrCategoryTableView.bottomAnchor, constant: 32),
            emojiAndColorCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emojiAndColorCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            emojiAndColorCollectionView.heightAnchor.constraint(equalToConstant: 460),
            
            stack.topAnchor.constraint(equalTo: emojiAndColorCollectionView.bottomAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        tableViewHeightConstraint = scheduleOrCategoryTableView.heightAnchor.constraint(equalToConstant: CGFloat(options.count) * rowHeight)
        tableViewHeightConstraint?.isActive = true
    }
    
    private func configureWithTracker() {
        // Заполняем данными трекера
        nameTextField.text = tracker.name
        selectedCategory = originalCategory
        selectedDays = tracker.schedule
        
        // Настраиваем опции
        options[0].detail = originalCategory
        options[1].selectedDays = tracker.schedule
        if !tracker.schedule.isEmpty {
            options[1].detail = tracker.schedule.map { $0.short }.joined(separator: ", ")
        }
        
        // Находим emoji
        if let emojiIndex = emojiSet.firstIndex(of: tracker.emoji) {
            selectedEmojiIndexPath = IndexPath(row: emojiIndex, section: 0)
        }
        
        // Находим цвет
        let colorName = findColorName(for: tracker.color)
        if let colorIndex = colors.firstIndex(of: colorName) {
            selectedColorIndexPath = IndexPath(row: colorIndex, section: 1)
        }
        
        scheduleOrCategoryTableView.reloadData()
    }
    
    private func findColorName(for color: UIColor) -> String {
        for colorName in colors {
            if let namedColor = UIColor(named: colorName), namedColor.isEqual(color) {
                return colorName
            }
        }
        return colors.first ?? "1"
    }
    
    private func updateCompletedDaysLabel() {
        completedDaysLabel.text = "\(pluralizedDays(completedDays))"
    }
    
    private func pluralizedDays(_ count: Int) -> String {
        let format = NSLocalizedString("days_count", comment: "Количество дней в правильной форме")
        return String.localizedStringWithFormat(format, count)
    }
    
    // MARK: - Actions
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let habitTitle = nameTextField.text, !habitTitle.isEmpty,
              let emojiIndexPath = selectedEmojiIndexPath,
              let colorIndexPath = selectedColorIndexPath else {
            return
        }
        
        let selectedEmoji = emojiSet[emojiIndexPath.row]
        let selectedColorName = colors[colorIndexPath.row]
        let selectedColor = UIColor(named: selectedColorName) ?? .blue
        
        let updatedTracker = Tracker(
            id: tracker.id, // Сохраняем оригинальный ID!
            name: habitTitle,
            color: selectedColor,
            emoji: selectedEmoji,
            schedule: selectedDays
        )
        
        delegate?.didUpdateTracker(updatedTracker, categoryName: selectedCategory)
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let maxLength: Int = 38
        guard let currentText = textField.text as NSString? else { return }
        
        if currentText.length > maxLength {
            warningLabel.isHidden = false
        } else {
            warningLabel.isHidden = true
        }
    }
}

// MARK: - UITableViewDataSource
extension HabitEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as? SettingsCell else { return UITableViewCell() }
        cell.configure(title: option.title, detail: option.detail, accessory: option.accessory)
        cell.backgroundColor = .secondarySystemBackground
        cell.contentView.backgroundColor = .secondarySystemBackground
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HabitEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            do {
                let store = try TrackerCategoryStore()
                let categoryVC = CategoryListViewController(
                    selectedCategory: options[indexPath.row].detail,
                    store: store
                )
                categoryVC.onCategorySelected = { [weak self] selectedName in
                    guard let self else { return }
                    self.selectedCategory = selectedName
                    self.options[indexPath.row].detail = selectedName
                    self.scheduleOrCategoryTableView.reloadRows(at: [indexPath], with: .automatic)
                }
                navigationController?.pushViewController(categoryVC, animated: true)
            } catch {
                print("❌ Ошибка инициализации TrackerCategoryStore: \(error)")
            }
            
        case 1:
            let vc = ScheduleViewController()
            vc.delegate = self
            vc.mainIndex = indexPath.row
            
            if let saved = options[indexPath.row].selectedDays {
                vc.selectedDays = Set(saved)
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
extension HabitEditViewController: ScheduleViewControllerDelegate {
    func scheduleViewController(_ vc: ScheduleViewController, didselect days: [Weekdays], atIndex index: Int?) {
        guard let idx = index else { return }
        options[idx].selectedDays = days
        selectedDays = days
        options[idx].detail = days.map { $0.short }.joined(separator: ", ")
        scheduleOrCategoryTableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
    }
}

// MARK: - UITextFieldDelegate
extension HabitEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let currentText = textField.text as NSString? else { return true }
        let newText = currentText.replacingCharacters(in: range, with: string)
        return newText.count <= 38
    }
}

// MARK: - UICollectionViewDataSource
extension HabitEditViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return emojiSet.count
        } else {
            return colors.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrackerCreateCell", for: indexPath) as? TrackerCreateCell else { return UICollectionViewCell()}
        
        if indexPath.section == 0 {
            cell.config(type: .image, name: emojiSet[indexPath.row])
            if indexPath == selectedEmojiIndexPath {
                cell.select()
            }
        } else {
            cell.config(type: .color, name: colors[indexPath.row])
            if indexPath == selectedColorIndexPath {
                cell.select()
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HabitEditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if let previous = selectedEmojiIndexPath {
                if let cell = collectionView.cellForItem(at: previous) as? TrackerCreateCell {
                    cell.deselect()
                }
            }
            if let cell = collectionView.cellForItem(at: indexPath) as? TrackerCreateCell {
                cell.select()
            }
            selectedEmojiIndexPath = indexPath
        } else if indexPath.section == 1 {
            if let previous = selectedColorIndexPath {
                if let cell = collectionView.cellForItem(at: previous) as? TrackerCreateCell {
                    cell.deselect()
                }
            }
            if let cell = collectionView.cellForItem(at: indexPath) as? TrackerCreateCell {
                cell.select()
            }
            selectedColorIndexPath = indexPath
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HabitEditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                           withReuseIdentifier: "Header",
                                                                           for: indexPath) as? SectionHeader else {
            return UICollectionReusableView()
        }
        
        let colors = NSLocalizedString("colors", comment: "")
        let emoji = NSLocalizedString("Emoji", comment: "")
        header.label.text = indexPath.section == 0 ? emoji : colors
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
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
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
}
