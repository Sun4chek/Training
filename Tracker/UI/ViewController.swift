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
    private var trackerStore: TrackerStore?
    private var categoryStore: TrackerCategoryStore?
    private var recordStore: TrackerRecordStore?

    // MARK: - UI
    private let trackerCellId = "TrackerCollectionViewCell"

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Трекеры"
        l.font = UIFont(name: "SFProText-Bold", size: 34)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Поиск"
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
        return iv
    }()

    private lazy var helloTitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Что будем отслеживать?"
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
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false

        setupUI()
        setupStores()
        loadAllDataAndRefreshUI()
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
        plusButton.tintColor = .black
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

        if allCategories.isEmpty {
            do {
                try categoryStore?.add(TrackerCategory(name: "Важное", trackers: []))
                allCategories = categoryStore?.categories ?? []
            } catch {
                print("❗️ Ошибка при создании дефолтной категории: \(error)")
            }
        }

        rebuildVisibleCategories()
        safeReloadCollectionView()
    }

    private func rebuildVisibleCategories() {
        let filteredTrackers = filteredTrackersForSelectedDateAndSearch()

        visibleCategories = allCategories.compactMap { category in
            let categoryTrackerIds = Set(category.trackers.map { $0.id })
            let trackersInCategory: [Tracker]

            if categoryTrackerIds.isEmpty {
                trackersInCategory = filteredTrackers
            } else {
                trackersInCategory = filteredTrackers.filter { categoryTrackerIds.contains($0.id) }
            }

            return trackersInCategory.isEmpty ? nil : TrackerCategory(name: category.name, trackers: trackersInCategory)
        }
    }

    private func filteredTrackersForSelectedDateAndSearch() -> [Tracker] {
        let weekdayName = transformDateToWeekday(selectedDate)
        let dayOpt = Weekdays.fromString(weekdayName)

        let byDate: [Tracker]
        if let day = dayOpt {
            byDate = allTrackers.filter { $0.schedule.contains(day) }
        } else {
            byDate = allTrackers
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return byDate
        }

        let lower = searchText.lowercased()
        return byDate.filter { $0.name.lowercased().contains(lower) }
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

    private func updateEmptyState() {
        if visibleCategories.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }

    private func transformDateToWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    // MARK: - Actions
    @objc private func plusTapped() {
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
    }

    // MARK: - Empty State
    private func showEmptyState() {
        if helloImage.superview == nil {
            view.addSubview(helloImage)
            view.addSubview(helloTitleLabel)
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
    func didCreateNewTracker(_ tracker: Tracker) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let trackerStore = self.trackerStore else { return }
            do {
                try trackerStore.addNewTracker(tracker)
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

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchText = ""
        searchBar.resignFirstResponder()
        rebuildVisibleCategories()
        safeReloadCollectionView()
    }
}

// MARK: - Safe array index
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

