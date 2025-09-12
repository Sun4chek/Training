//
//  ViewController.swift
//  Tracker
//
//  Created by Волошин Александр on 8/27/25.
//

import UIKit

class MainViewController: UIViewController, UISearchBarDelegate {

    private let trackerCellId = "TrackerCollectionViewCell"
    var categories: [TrackerCategory] = []
    var completedTrackers: [TrackerRecord] = []
    var treckers: [Tracker] = []
    private var selectDate : Date?

    
    private func setupNavigationBar() {

        let plusButton = UIBarButtonItem(
            image: UIImage(named: "Addtracker"),
            style: .plain,
            target: self,
            action: #selector(plusTapped)
        )
        
        plusButton.customView?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6).isActive = true
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact// компактный стиль
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        datePicker.date = currentDate
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        
        
        navigationItem.rightBarButtonItem = datePickerItem
        navigationItem.leftBarButtonItem = plusButton
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .black
    }
    
    private lazy var titlelabel : UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
        private lazy var datePicker: UIDatePicker = {
            let picker = UIDatePicker()
            picker.datePickerMode = .date
            picker.preferredDatePickerStyle = .wheels
            picker.locale = Locale(identifier: "ru_RU")
            picker.backgroundColor = .white
            picker.layer.cornerRadius = 12
            picker.isHidden = true
            picker.alpha = 0
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
            return picker
        }()
    
    private lazy var dateButton: UIButton = {
        let button = UIButton(type: .system)
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        button.setTitle(formatter.string(from: currentDate), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(dateChanged), for: .touchUpInside)
        button.backgroundColor = UIColor(named: "ypGrey")
        button.layer.cornerRadius = 8


        return button
    }()
    
    private lazy var helloImage : UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "helloImage"))
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var helloTitleLabel : UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var collectionView : UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(TrackerCollectionViewCell.self , forCellWithReuseIdentifier: trackerCellId)
        collectionView.backgroundColor = .clear

        return collectionView
    }()
    
    func reloadData() {
        
        print("меня вызвали ")
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        searchBar.delegate = self
        
        
        
        
        print("загружаем основной вью контроллер")
        showdemo()
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        
        
        setupNavigationBar()
        
        setupUI()
        setupCollectionView()
     
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("подгружаем данныЭ")
        collectionView.reloadData()
    }
    
    // MARK: - UISearchBarDelegate

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Показываем кнопку отмены при начале редактирования
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // При нажатии отмены скрываем клавиатуру и очищаем поиск
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        
        // Здесь можно добавить логику сброса поиска
        // collectionView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // При нажатии поиска скрываем клавиатуру
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        
        // Здесь можно добавить логику поиска
        // filterTrackers(searchText: searchBar.text ?? "")
    }
    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor , constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
            
        ])
    }
    
    
    
    private func showdemo() {
        view.addSubview(helloTitleLabel)
        view.addSubview(helloImage)
        
        NSLayoutConstraint.activate([
            helloImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            helloImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            helloImage.widthAnchor.constraint(equalToConstant: 80),
            helloImage.heightAnchor.constraint(equalToConstant: 80),
            
            helloTitleLabel.topAnchor.constraint(equalTo: helloImage.bottomAnchor, constant: 8),
            helloTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            helloTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            helloTitleLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    func setupUI() {
        view.addSubview(titlelabel)
        view.addSubview(searchBar)

        let guide = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            titlelabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titlelabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 90 ),
            titlelabel.widthAnchor.constraint(equalToConstant: 254),
            titlelabel.heightAnchor.constraint(equalToConstant: 41)
        ])
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: titlelabel.topAnchor, constant: 48),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            searchBar.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    private func getFilteredTrackersForSelectedDate() -> [Tracker] {
        let targetDate = selectDate ?? Date()
        let currentDayString = transformDateInToWekkDay(targetDate)
        
        if let currentDay = Weekdays.fromString(currentDayString) {
            return treckers.filter { $0.schedule.contains(currentDay) }
        } else {
            return []
        }
    }
    
    @objc private func dateChanged() {
        if let datePickerItem = navigationItem.rightBarButtonItem,
           let datePicker = datePickerItem.customView as? UIDatePicker {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yy"
            selectDate = datePicker.date
            print("работала смена даты: \(formatter.string(from: datePicker.date))")
            
            // Обновляем UI
            let filteredTrackers = getFilteredTrackersForSelectedDate()
            if filteredTrackers.isEmpty {
                showdemo()
            } else {
                hideEmptyState()
            }
            
            collectionView.reloadData()
        }
    }
    
    @objc private func plusTapped() {
        
        print("нажали плюс")
        let newVC = HabbitRegisterViewController()
        newVC.delegate = self
        let navController = UINavigationController(rootViewController: newVC)
        newVC.modalPresentationStyle = .fullScreen
        
        present(navController, animated: true)
    }

    
    private func hideEmptyState() {
        helloImage.removeFromSuperview()
        helloTitleLabel.removeFromSuperview()
    }
    
    private func setupManualSearchBar() {
        
    }
    
    func transformDateInToWekkDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

extension MainViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Всего трекеров:", treckers.count, "подходит по дню:")
        return getFilteredTrackersForSelectedDate().count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: trackerCellId, for: indexPath) as! TrackerCollectionViewCell
               
               let filteredTrackers = getFilteredTrackersForSelectedDate()
               let tracker = filteredTrackers[indexPath.item]
               let selectedDate = selectDate ?? Date()
               
               cell.delegate = self
               cell.configure(with: tracker, index: indexPath.row, chooseDate: selectedDate)
               return cell
           }
    
}

extension MainViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

extension MainViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 168, height: 150)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }
}

extension MainViewController: HabbitRegisterViewControllerDelegate {
    func didCreateNewTracker(_ tracker: Tracker) {
        print("тот самый делегат отработал и добавил новый трекер")
        
        // Добавляем трекер в массив
        treckers.append(tracker)
        
        // Проверяем, должен ли трекер отображаться для текущей даты
        let shouldShowTracker = getFilteredTrackersForSelectedDate().contains(where: { $0.id == tracker.id })
        
        if shouldShowTracker {
            hideEmptyState()
            // Если трекер должен отображаться, добавляем с анимацией
            collectionView.performBatchUpdates {
                let newIndexPath = IndexPath(item: getFilteredTrackersForSelectedDate().count - 1, section: 0)
                collectionView.insertItems(at: [newIndexPath])
            }
        }
        
     
    }
}

extension MainViewController: TrackerCollectionViewCellDelegate {
    func didTapCompleteButton(for tracker: Tracker, index: Int, on date: Date) {
        print("Трекер обновлен для даты: \(date)")
        
        // Находим трекер в исходном массиве по ID
        if let originalIndex = treckers.firstIndex(where: { $0.id == tracker.id }) {
            var updatedTracker = treckers[originalIndex]
            
            // Переключаем выполнение для КОНКРЕТНОЙ ДАТЫ
            let calendar = Calendar.current
            
            if let existingRecordIndex = updatedTracker.records.firstIndex(where: {
                calendar.isDate($0.date, inSameDayAs: date)
            }) {
                // Удаляем запись если уже выполнено в этот день
                updatedTracker.records.remove(at: existingRecordIndex)
            } else {
                // Добавляем запись если не выполнено
                let newRecord = TrackerRecord(id: tracker.id, date: date)
                updatedTracker.records.append(newRecord)
            }
            
            // Обновляем массив
            treckers[originalIndex] = updatedTracker
            
            // ОБНОВЛЯЕМ ТОЛЬКО КОНКРЕТНУЮ ЯЧЕЙКУ с анимацией
            if let filteredIndex = getFilteredTrackersForSelectedDate().firstIndex(where: { $0.id == tracker.id }) {
                let indexPath = IndexPath(item: filteredIndex, section: 0)
                
                collectionView.performBatchUpdates {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
}
