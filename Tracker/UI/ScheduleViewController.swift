//
//  Schedule.swift
//  Tracker
//
//  Created by Волошин Александр on 9/9/25.
//

import UIKit




protocol ScheduleViewControllerDelegate: AnyObject {
    func scheduleViewController(_ vc: ScheduleViewController,didselect: [Weekdays], atIndex index: Int?)
}

final class ScheduleViewController: UIViewController {
    
    var mainIndex: Int?
    weak var delegate: ScheduleViewControllerDelegate?
    var selectedDays: Set<Weekdays> = []
    
    private var setDays: Set<Weekdays> = []
    private let days = Weekdays.allCases
    
    
    
    
    private var options: [SettingsOption] = {
        let weekdays: [Weekdays] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        return weekdays.map { weekday in
            let toggle = UISwitch()
            toggle.isOn = false
            toggle.addTarget(self, action: #selector(dayToggleChanged(_:)), for: .valueChanged)
            return SettingsOption(title: weekday.title, detail: nil, accessory: .toggle(toggle))
        }
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")  // Регистрация кастомной ячейки
        table.separatorStyle = .singleLine
        table.layer.cornerRadius = 16
        table.isScrollEnabled = false
        table.backgroundColor = .secondarySystemBackground
        table.clipsToBounds = true
        table.allowsSelection = true
        table.delaysContentTouches = false
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    private lazy var okButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.backgroundColor = .ypBlack 
        button.setTitleColor(.white, for: .normal)  // Белый текст
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDays = selectedDays
        view.backgroundColor = .systemBackground
        navigationItem.title = "Расписание"
        navigationItem.hidesBackButton = true
        
        
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()  // Reload после добавления в hierarchy — избегает warning
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("Schedule Table frame: \(tableView.frame)")  // Дебаг: проверьте frames
    }
    
    func setupUI() {
        view.addSubview(tableView)
        view.addSubview(okButton)
        
        NSLayoutConstraint.activate([
            // TableView
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: CGFloat(options.count * 75)),
            
            // OkButton под таблицей
            okButton.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 24),
            okButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            okButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            okButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc func dayToggleChanged(_ sender: UISwitch) {
        // Находим день по ссылке на toggle
        if let index = options.firstIndex(where: { option in
            if case .toggle(let toggle) = option.accessory, toggle === sender {
                return true
            }
            return false
        }) {
            let day = options[index].title
            print("Выбран/снят день: \(day) (isOn: \(sender.isOn))")
        } else {
            print("Не удалось найти день для свитча")
        }
    }
    
    @objc func okButtonTapped() {
        let order = Weekdays.allCases.filter{selectedDays.contains($0)}
        delegate?.scheduleViewController(self, didselect: order, atIndex: mainIndex)
        navigationController?.popViewController(animated: true)// Возврат из push
    }
}

extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath) as? SettingsCell  else {return UITableViewCell() }// Теперь as! работает
        
        
        
        cell.backgroundColor = .secondarySystemBackground
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.isUserInteractionEnabled = true
        let day = days[indexPath.row]
        let toggle = UISwitch()
        toggle.tag = indexPath.row
        toggle.isOn = selectedDays.contains(day)
        toggle.addTarget(self, action: #selector(daySwitchChanged(_:)), for: .valueChanged)
        cell.configure(title: day.title, accessory: .toggle(toggle))
        return cell
    }
    
    @objc private func daySwitchChanged(_ sender: UISwitch) {
        let index = sender.tag
        let day = days[index]
        if sender.isOn {
            selectedDays.insert(day)
        } else {
            selectedDays.remove(day)
        }
    }
}

extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == options.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}




