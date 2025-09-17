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
        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(named: "Addtracker"), for: .normal)
        plusButton.tintColor = .black
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        plusButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)

        
        // Констрейнты размера
        NSLayoutConstraint.activate([
            
            plusButton.widthAnchor.constraint(equalToConstant: 42),
            plusButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        
        let plusItem = UIBarButtonItem(customView: plusButton)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        
        let datePickerItem = UIBarButtonItem(customView: datePicker)
        
        navigationItem.leftBarButtonItem = plusItem
        navigationItem.rightBarButtonItem = datePickerItem
    }

    
    private lazy var titlelabel : UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont(name: "SFProText-Bold", size: 34)
        label.textColor = .ypBlack
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
        label.font = UIFont(name: "SFProText-Medium", size: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 12
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 44) // дефолтный размер заголовка

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(TrackerCollectionViewCell.self, forCellWithReuseIdentifier: trackerCellId)
        cv.register(TrackerSectionHeader.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: TrackerSectionHeader.reuseId)
        cv.backgroundColor = .clear
        return cv
    }()
    
    func reloadData() {
        
        print("меня вызвали ")
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        categories = [TrackerCategory(name: "Важное", trackers: [])]

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
            titlelabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 91 ),
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
    
    private func filteredTrackers(for category: TrackerCategory) -> [Tracker] {
        let targetDate = selectDate ?? Date()
        let currentDayString = transformDateInToWekkDay(targetDate)
        guard let currentDay = Weekdays.fromString(currentDayString) else { return [] }
        return category.trackers.filter { $0.schedule.contains(currentDay) }
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
        let newVC = CreateNewHabbitViewController()
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

extension MainViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let trackersForDate = getFilteredTrackersForSelectedDate()
        return trackersForDate.isEmpty ? 0 : categories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let category = categories[section]
        return filteredTrackers(for: category).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: trackerCellId, for: indexPath) as! TrackerCollectionViewCell

        let category = categories[indexPath.section]
        let filtered = filteredTrackers(for: category)

        // defensive: если индекс вдруг вне диапазона — возвращаем пустую ячейку
        guard indexPath.item < filtered.count else { return cell }

        let tracker = filtered[indexPath.item]
        let selectedDate = selectDate ?? Date()

        let isCompleted = completedTrackers.contains { record in
            record.id == tracker.id && Calendar.current.isDate(record.date, inSameDayAs: selectedDate)
        }
       
        let completedDays = completedTrackers.filter { $0.id == tracker.id }.count
        
        cell.delegate = self
        cell.configure(with: tracker, index: indexPath.item, isCompleted: isCompleted, selectDate: selectedDate,completedDays: completedDays)
        return cell
    }

    // Заголовок секции
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: TrackerSectionHeader.reuseId,
                                                                     for: indexPath) as! TrackerSectionHeader
        header.titleLabel.text = categories[indexPath.section].name
        header.titleLabel.font = UIFont(name: "SFProText-Bold", size: 16)
        return header
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
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        // верни ноль, если заголовок не нужен; сейчас вернём высоту 44
        return CGSize(width: collectionView.bounds.width, height: 44)
    }
}

extension MainViewController: HabbitRegisterViewControllerDelegate {
    func didCreateNewTracker(_ tracker: Tracker) {
        print("тот самый делегат отработал и добавил новый трекер")

        if categories.isEmpty {
            categories = [TrackerCategory(name: "Важное", trackers: [])]
        }
        categories[0].trackers.append(tracker) // добавляем в "Важное"
        treckers.append(tracker) // можно оставить для совместимости, но основная работа - с categories

        
        let filteredTrackers = getFilteredTrackersForSelectedDate()
        if filteredTrackers.isEmpty {
            showdemo() // показываем приветствие, если нет подходящих трекеров
        } else {
            hideEmptyState() // скрываем приветствие, если есть подходящие трекеры
        }
        
        collectionView.reloadData()
    }


}


extension MainViewController: TrackerCollectionViewCellDelegate {

    
    func didTapCompleteButton(for tracker: Tracker,in date : Date, isCompleted : Bool) {
        print("Трекер обновлен для даты: \(date)")
        
        // Находим трекер в исходном массиве по ID
        if let originalIndex = treckers.firstIndex(where: { $0.id == tracker.id }) {
            var updatedTracker = treckers[originalIndex]
            
            // Переключаем выполнение для КОНКРЕТНОЙ ДАТЫ
            let calendar = Calendar.current
            
            
            
            if let existingIndex = completedTrackers.firstIndex(where: {
                $0.id == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: date)
            }) {
                // Удаляем запись, если уже выполнено в этот день
                completedTrackers.remove(at: existingIndex)
            } else {
                // Добавляем запись, если ещё не выполнено
                let newRecord = TrackerRecord(id: tracker.id, date: date)
                completedTrackers.append(newRecord)
            }
            
            
            if let filteredIndex = getFilteredTrackersForSelectedDate().firstIndex(where: { $0.id == tracker.id }) {
                let indexPath = IndexPath(item: filteredIndex, section: 0)
                
                collectionView.performBatchUpdates {
                    collectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
}
