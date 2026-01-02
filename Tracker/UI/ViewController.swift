//
//  MainViewController.swift
//  Tracker
//
//  Final safe version — no force unwraps, safe Core Data access.
//  Created by Волошин Александр on 9/26/25.
//

import UIKit

final class MainViewController: UIViewController {

    // MARK: - Stores
    private var colors = Colors()
    private var trackerStore: TrackerStore?
    private var categoryStore: TrackerCategoryStore?
    private var recordStore: TrackerRecordStore?

    // MARK: - UI
    private let trackerCellId = "TrackerCollectionViewCell"

    private var currentFilter: TrackerFilter = .all {
        didSet { applyFilterAndReload() }
    }

    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("filters", comment: ""), for: .normal)
        button.backgroundColor = .ypBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Regular", size: 17)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Проверяет, есть ли вообще трекеры на выбранную дату (без учета поиска и фильтров)
    private var hasTrackersForSelectedDate: Bool {
        let weekdayName = transformDateToWeekday(selectedDate)
        guard let day = Weekdays.fromString(weekdayName) else { return false }
        
        return allTrackers.contains { $0.schedule.contains(day) }
    }
    
    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        let trackers = NSLocalizedString("trackers", comment: "")
        l.text = trackers
        l.font = UIFont(name: "SFProText-Bold", size: 34)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        let search = NSLocalizedString("search", comment: "")
        sb.placeholder = search
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        sb.delegate = self
        return sb
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 44)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.register(TrackerCollectionViewCell.self, forCellWithReuseIdentifier: trackerCellId)
        cv.register(TrackerSectionHeader.self,
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    withReuseIdentifier: TrackerSectionHeader.reuseId)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    private lazy var helloImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "helloImage"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        return iv
    }()

    private lazy var helloTitleLabel: UILabel = {
        let l = UILabel()
        let whatTrack = NSLocalizedString("whatTrack", comment: "")
        l.text = whatTrack
        l.font = UIFont(name: "SFProText-Medium", size: 12)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private lazy var nothingImage: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "nothing"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        
        return iv
    }()
    
    private lazy var nothingTitleLabel: UILabel = {
        let l = UILabel()
        let whatTrack = NSLocalizedString("nothingTrack", comment: "")
        l.text = whatTrack
        l.font = UIFont(name: "SFProText-Medium", size: 12)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Data
    private var allTrackers: [Tracker] = []
    private var allCategories: [TrackerCategory] = []
    private var visibleCategories: [TrackerCategory] = []

    private var selectedDate: Date = Date()
    private var searchText: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = colors.backgroundColor
        navigationController?.navigationBar.isHidden = false

        setupUI()
        setupStores()
        loadAllDataAndRefreshUI()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AnalyticsService.trackOpen(screen: "Main")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsService.trackClose(screen: "Main")
    }

    deinit {
        trackerStore?.delegate = nil
        categoryStore?.delegate = nil
        recordStore?.delegate = nil
    }
    
    

    // MARK: - Setup
    private func setupUI() {
        setupNavigationBar()
        
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        setupFilterButton()

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            searchBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            searchBar.heightAnchor.constraint(equalToConstant: 36),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        let plusButton = UIButton(type: .system)
        plusButton.setImage(UIImage(named: "Addtracker"), for: .normal)
        plusButton.tintColor = colors.plusColor
        plusButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        NSLayoutConstraint.activate([
            plusButton.widthAnchor.constraint(equalToConstant: 42),
            plusButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: plusButton)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.addTarget(self, action: #selector(datePickerChanged(_:)), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)
    }

    private func setupStores() {
        trackerStore = TrackerStore()
        categoryStore = TrackerCategoryStore()
        recordStore = TrackerRecordStore()

        trackerStore?.delegate = self
        categoryStore?.delegate = self
        recordStore?.delegate = self
    }

    // MARK: - Data & UI

    private func loadAllDataAndRefreshUI() {
        allTrackers = trackerStore?.trackers ?? []
        allCategories = categoryStore?.categories ?? []

        debugCategoriesAndTrackers()

        rebuildVisibleCategories()
        safeReloadCollectionView()
        updateFilterButtonVisibility()
    }
    
    private func setupFilterButton() {
        view.addSubview(filterButton)
        NSLayoutConstraint.activate([
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        // добавляем оверскролл
        collectionView.contentInset.bottom = 100
        collectionView.alwaysBounceVertical = true
    }

    private func applyFilterAndReload() {
        switch currentFilter {
        case .all:
            rebuildVisibleCategories()
            filterButton.setTitleColor(.white, for: .normal)
        case .today:
            selectedDate = Date()
            rebuildVisibleCategories()
            filterButton.setTitleColor(.white, for: .normal)
        case .completed:
            let all = filteredTrackersForSelectedDateAndSearch()
            let completed = all.filter { recordStore?.isTrackerCompleted($0, on: selectedDate) ?? false }
            visibleCategories = allCategories.compactMap { category in
                let trackers = completed.filter { tracker in
                    category.trackers.contains(where: { $0.id == tracker.id })
                }
                return trackers.isEmpty ? nil : TrackerCategory(name: category.name, trackers: trackers)
            }
            filterButton.setTitleColor(.white, for: .normal)
        case .incomplete:
            let all = filteredTrackersForSelectedDateAndSearch()
            let incomplete = all.filter { !(recordStore?.isTrackerCompleted($0, on: selectedDate) ?? false) }
            visibleCategories = allCategories.compactMap { category in
                let trackers = incomplete.filter { tracker in
                    category.trackers.contains(where: { $0.id == tracker.id })
                }
                return trackers.isEmpty ? nil : TrackerCategory(name: category.name, trackers: trackers)
            }
            filterButton.setTitleColor(.white, for: .normal)
        }
        
        safeReloadCollectionView()
        updateFilterButtonVisibility() // Обновляем видимость кнопки после применения фильтра
    }

    @objc private func filterButtonTapped() {
        AnalyticsService.trackClick(item: "filter")
        let vc = FilterViewController(currentFilter: currentFilter)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    
    private func debugCategoriesAndTrackers() {
        print("=== DEBUG CATEGORIES AND TRACKERS ===")
        print("Всего трекеров: \(allTrackers.count)")
        print("Всего категорий: \(allCategories.count)")
        
        for (index, category) in allCategories.enumerated() {
            print("Категория \(index): '\(category.name)'")
            print("  - Трекеров в категории: \(category.trackers.count)")
            for tracker in category.trackers {
                print("    - \(tracker.name) (ID: \(tracker.id))")
            }
        }
        print("=====================================")
    }
    private func rebuildVisibleCategories() {
        let filteredTrackers = filteredTrackersForSelectedDateAndSearch()
        
        print("Все трекеры: \(allTrackers.count)")
        print("Все категории: \(allCategories.count)")
        
        visibleCategories = allCategories.compactMap { category in
            let categoryTrackerIds = Set(category.trackers.map { $0.id })
            let trackersInCategory = filteredTrackers.filter { categoryTrackerIds.contains($0.id) }
            
            print("Категория '\(category.name)': \(category.trackers.count) трекеров, после фильтрации: \(trackersInCategory.count)")
            
            return trackersInCategory.isEmpty ? nil : TrackerCategory(name: category.name, trackers: trackersInCategory)
        }
        
        print("Видимые категории: \(visibleCategories.count)")
    }

    private func filteredTrackersForSelectedDateAndSearch() -> [Tracker] {
        // 1. Сначала фильтруем по дате - какие трекеры доступны сегодня
        let weekdayName = transformDateToWeekday(selectedDate)
        let dayOpt = Weekdays.fromString(weekdayName)
        
        let trackersForSelectedDate: [Tracker]
        if let day = dayOpt {
            trackersForSelectedDate = allTrackers.filter { $0.schedule.contains(day) }
        } else {
            trackersForSelectedDate = allTrackers
        }
        
        // 2. Если есть поисковый запрос - фильтруем по названию среди доступных на дату трекеров
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return trackersForSelectedDate
        }
        
        let lowerSearchText = searchText.lowercased()
        return trackersForSelectedDate.filter { $0.name.lowercased().contains(lowerSearchText) }
    }

    private func safeReloadCollectionView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isViewLoaded && self.view.window != nil {
                self.updateEmptyState()
                self.collectionView.reloadData()
            } else {
                self.updateEmptyState()
            }
        }
    }
    
    private func updateFilterButtonVisibility() {
        // Показываем кнопку фильтра только если есть трекеры на выбранную дату
        // И скрываем, если трекеров нет вообще
        filterButton.isHidden = !hasTrackersForSelectedDate
        
        // Но кнопка всегда должна быть активной, если отображается
        filterButton.isEnabled = true
    }

    private func updateEmptyState() {
        // Всегда скрываем все заглушки сначала
        hideEmptyState()
        hideEmptyState1()
        
        if visibleCategories.isEmpty {
            if !hasTrackersForSelectedDate {
                // Случай 0: Нет трекеров на выбранную дату вообще
                showEmptyState() // "Что будем отслеживать?"
            } else if !searchText.isEmpty {
                // Случай 1: Есть поисковый запрос, но ничего не найдено
                showEmptyState1() // "Ничего не найдено"
            } else {
                // Случай 2: Есть трекеры на дату, но они отфильтровались (completed/incomplete)
                showEmptyState1() // "Ничего не найдено"
            }
        }
        
        // Обновляем видимость кнопки фильтра
        updateFilterButtonVisibility()
    }

    private func transformDateToWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }
    
    
    

    // MARK: - Actions
    @objc private func plusTapped() {
        AnalyticsService.trackClick(item: "add_track")
        let createVC = CreateNewHabbitViewController()
        
        createVC.delegate = self
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func datePickerChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        rebuildVisibleCategories()
        safeReloadCollectionView()
        updateFilterButtonVisibility()
    }

    // MARK: - Empty State
    private func showEmptyState() {
        if helloImage.superview == nil {
            view.insertSubview(helloImage, belowSubview: filterButton)
                  view.insertSubview(helloTitleLabel, belowSubview: filterButton)
                  
            NSLayoutConstraint.activate([
                helloImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                helloImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                helloImage.widthAnchor.constraint(equalToConstant: 80),
                helloImage.heightAnchor.constraint(equalToConstant: 80),

                helloTitleLabel.topAnchor.constraint(equalTo: helloImage.bottomAnchor, constant: 8),
                helloTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    }

    
    
    
    
    private func hideEmptyState() {
        helloImage.removeFromSuperview()
        helloTitleLabel.removeFromSuperview()
    }
    
    
    
    private func showEmptyState1() {
        if nothingImage.superview == nil {
            view.insertSubview(nothingImage, belowSubview: filterButton)
            view.insertSubview(nothingTitleLabel, belowSubview: filterButton)
                  
            NSLayoutConstraint.activate([
                nothingImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                nothingImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
                nothingImage.widthAnchor.constraint(equalToConstant: 80),
                nothingImage.heightAnchor.constraint(equalToConstant: 80),

                // ИСПРАВЛЕНО: было helloImage, должно быть nothingImage
                nothingTitleLabel.topAnchor.constraint(equalTo: nothingImage.bottomAnchor, constant: 8),
                nothingTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    }
    
    private func hideEmptyState1() {
        nothingImage.removeFromSuperview()
        nothingTitleLabel.removeFromSuperview()
    }
    
    private func presentEditScreen(for tracker: Tracker, categoryName: String) {
        guard let recordStore = recordStore else { return }

        // Количество выполнений (записей) по этому трекеру
        let completedDays = recordStore.records.filter { $0.id == tracker.id }.count

        // Создаём экран редактирования
        let editVC = HabitEditViewController(
            tracker: tracker,
            categoryName: categoryName,
            completedDays: completedDays
        )
        editVC.delegate = self

        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

}

// MARK: - UICollectionViewDataSource
extension MainViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[safe: section]?.trackers.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let category = visibleCategories[safe: indexPath.section],
            let tracker = category.trackers[safe: indexPath.item],
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: trackerCellId,
                for: indexPath
            ) as? TrackerCollectionViewCell
        else {
            assertionFailure("❌ Ошибка конфигурации ячейки")
            return UICollectionViewCell()
        }

        let isCompleted = recordStore?.isTrackerCompleted(tracker, on: selectedDate) ?? false
        let completedCount = recordStore?.records.filter { $0.id == tracker.id }.count ?? 0

        cell.configure(with: tracker,
                       index: indexPath.item,
                       isCompleted: isCompleted,
                       selectDate: selectedDate,
                       completedDays: completedCount)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: TrackerSectionHeader.reuseId,
                for: indexPath
            ) as? TrackerSectionHeader,
            let category = visibleCategories[safe: indexPath.section]
        else {
            assertionFailure("❌ Ошибка хедера секции")
            return UICollectionReusableView()
        }

        header.titleLabel.text = category.name
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 168, height: 150)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let category = visibleCategories[safe: section] else { return .zero }
        return category.trackers.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: 44)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {

        guard let indexPath = indexPaths.first else {
            return nil
        }

        let edit = NSLocalizedString("edit", comment: "")
        let delete = NSLocalizedString("delete", comment: "")

        return UIContextMenuConfiguration(actionProvider: { _ in
            return UIMenu(children: [
                UIAction(
                    title: edit,
                    image: UIImage(systemName: "pencil"), // опционально — иконка
                    handler: { [weak self] _ in
                            guard
                                let self,
                                let indexPath = indexPaths.first,
                                let category = self.visibleCategories[safe: indexPath.section],
                                let tracker = category.trackers[safe: indexPath.item]
                            else { return }
                        AnalyticsService.trackClick(item: "edit")
                            self.presentEditScreen(for: tracker, categoryName: category.name)
                        }
                ),
                UIAction(
                    title: delete,
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive,
                    handler: { [weak self] _ in
                        guard
                            let self,
                            let indexPath = indexPaths.first,
                            let category = self.visibleCategories[safe: indexPath.section],
                            let tracker = category.trackers[safe: indexPath.item],
                            let trackerStore = self.trackerStore
                        else { return }

                        let alertTitle = NSLocalizedString("deleteAlertTitle", comment: "Удалить трекер?")
                        let alertMessage = NSLocalizedString("deleteAlertMessage", comment: "Вы уверены, что хотите удалить этот трекер? Это действие нельзя отменить.")
                        let alertYes = NSLocalizedString("deleteYes", comment: "Удалить")
                        let alertCancel = NSLocalizedString("cancel", comment: "Отмена")

                        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: alertCancel, style: .cancel))
                        alert.addAction(UIAlertAction(title: alertYes, style: .destructive, handler: { _ in
                            DispatchQueue.global(qos: .userInitiated).async {
                                do {
                                    try trackerStore.deleteTracker(tracker)
                                    DispatchQueue.main.async {
                                        self.loadAllDataAndRefreshUI()
                                    }
                                    AnalyticsService.trackClick(item: "delete")
                                } catch {
                                    print("❗️ Ошибка при удалении трекера: \(error)")
                                }
                            }
                        }))
                        self.present(alert, animated: true)
                    }
                )

            ])
        })
    }

}

// MARK: - TrackerCollectionViewCellDelegate
extension MainViewController: TrackerCollectionViewCellDelegate {
    func didTapCompleteButton(for tracker: Tracker, in date: Date, isCompleted: Bool) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let recordStore = self.recordStore else { return }
            do {
                if recordStore.isTrackerCompleted(tracker, on: date) {
                    try recordStore.deleteRecord(for: tracker, date: date)
                } else {
                    try recordStore.addRecord(for: tracker, date: date)
                }
                DispatchQueue.main.async {
                    self.loadAllDataAndRefreshUI()
                }
            } catch {
                print("❗️ Ошибка при обновлении записи: \(error)")
            }
        }
    }
}

// MARK: - HabbitRegisterViewControllerDelegate
extension MainViewController: HabbitRegisterViewControllerDelegate {
    func didCreateNewTracker(_ tracker: Tracker, name : String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let trackerStore = self.trackerStore else { return }
            do {
                try trackerStore.addNewTracker(tracker, toCategoryName: name )
                DispatchQueue.main.async {
                    self.loadAllDataAndRefreshUI()
                }
            } catch {
                print("❗️ Ошибка при добавлении трекера: \(error)")
            }
        }
    }
}

// MARK: - Store Delegates
extension MainViewController: TrackerStoreDelegate, TrackerCategoryStoreDelegate, TrackerRecordStoreDelegate {
    func didUpdateTrackers() {
        allTrackers = trackerStore?.trackers ?? []
        rebuildVisibleCategories()
        safeReloadCollectionView()
    }

    func didUpdateCategories() {
        allCategories = categoryStore?.categories ?? []
        rebuildVisibleCategories()
        safeReloadCollectionView()
    }

    func didUpdateRecords() {
        safeReloadCollectionView()
    }
}


// MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        rebuildVisibleCategories()
        safeReloadCollectionView()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        rebuildVisibleCategories()
        safeReloadCollectionView()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // Скрываем клавиатуру при нажатии Enter
    }
}

// MARK: - Safe array index
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - HabitEditViewControllerDelegate
extension MainViewController: HabitEditViewControllerDelegate {
  
    
    func didUpdateTracker(_ updatedTracker: Tracker, categoryName: String) {
        guard let trackerStore = trackerStore else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try trackerStore.updateTracker(updatedTracker, inCategory: categoryName)
                DispatchQueue.main.async {
                    self.loadAllDataAndRefreshUI()
                }
            } catch {
                print("❗️Ошибка обновления трекера: \(error)")
            }
        }
    }
}


extension MainViewController: FilterViewControllerDelegate {
    func didSelectFilter(_ filter: TrackerFilter) {
        currentFilter = filter
    }
}


