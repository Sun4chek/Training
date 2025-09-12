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
        
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    weak var delegate: HabbitRegisterViewControllerDelegate?

    // высота таблицы (мы будем менять .constant после layout)
    private var tableViewHeightConstraint: NSLayoutConstraint?
    private let rowHeight: CGFloat = 75
    private var habitTitle: String?
    private var selectedDays: [Weekdays] = []
    
    private var options: [SettingsOption] = [
        SettingsOption(title: "Категория", detail: nil, accessory: .chevron),
        SettingsOption(title: "Расписание", detail: nil, accessory: .chevron,selectedDays: [])
    ]
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Учиться делать iOS-приложения"
        tf.font = UIFont.systemFont(ofSize: 17)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 16
        tf.clearButtonMode = .whileEditing
        tf.textAlignment = .center
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
    
    private var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отмена", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
           button.layer.borderColor = UIColor.systemRed.cgColor
        button.heightAnchor.constraint(equalToConstant: 75).isActive = true
        return button
    }()
    
    private var createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.setTitleColor(.systemGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 16
        button.isEnabled = false
        button.heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        button.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        return button
    }()

    private func updateCreateButtonState() {
        // Проверяем: текст есть и выбраны дни
        let hasText = !(nameTextField.text?.isEmpty ?? true)
        let hasSchedule = !(options[1].selectedDays?.isEmpty ?? true)
        
        if hasText && hasSchedule {
            createButton.isEnabled = true
            createButton.backgroundColor = .black
            createButton.setTitleColor(.white, for: .normal)
        } else {
            createButton.isEnabled = false
            createButton.backgroundColor = .systemGray6
            createButton.setTitleColor(.systemGray, for: .normal)
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.delegate = self
        nameTextField.returnKeyType = .done
        scheduleOrCategoryTableView.dataSource = self
        scheduleOrCategoryTableView.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
        
        
        view.backgroundColor = .systemBackground
        navigationItem.title = "Создание привычки"
        navigationItem.hidesBackButton = true
        nameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        setupUI()
        // reload чтобы заполнить contentSize
        scheduleOrCategoryTableView.reloadData()
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
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

        // contentView — внутри scrollView, привязываемся к contentLayoutGuide и frameLayoutGuide
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            // Привязки по контенту
            contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 16),  // боковой inset
            contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -16),
           

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
        contentView.addSubview(scheduleOrCategoryTableView)
        contentView.addSubview(stack)

        // Констрейнты для текстового поля
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            nameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameTextField.heightAnchor.constraint(equalToConstant: 75)
        ])
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scheduleOrCategoryTableView.bottomAnchor, constant: 24),
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
            scheduleOrCategoryTableView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 24),
            scheduleOrCategoryTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scheduleOrCategoryTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
           
        ])
    }

    private func openScheduleScreen() {
        let vc = ScheduleViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "Расписание"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        updateCreateButtonState()
        habitTitle = textField.text
    }
    
    @objc private func createButtonTapped() {
        if let habitTitle = nameTextField.text {
            let newTracker = Tracker(
               
                id: UUID(),
                name: habitTitle,
                schedule: selectedDays,
                createDay : Date()
                
            )
            delegate?.didCreateNewTracker(newTracker)
            
            print("новый трекер готов")
            dismiss(animated: true)
        }
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
}
