//
//  MainViewController.swift
//  Tracker
//
//  Final version — uses TrackerStore, TrackerCategoryStore, TrackerRecordStore
//  No import CoreData here — all CoreData logic is inside stores.
//  Created by ChatGPT (adapted for your project).
//

import UIKit

final class MainViewController: UIViewController {

    // MARK: - Stores (assume these exist and are implemented)
    private var trackerStore: TrackerStore!
    private var categoryStore: TrackerCategoryStore!
    private var recordStore: TrackerRecordStore!

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
    /// All trackers loaded from store (unfiltered)
    private var allTrackers: [Tracker] = []

    /// Categories loaded from store (unfiltered)
    private var allCategories: [TrackerCategory] = []

    /// Derived categories for current selectedDate and searchText
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
        // detach delegates to avoid callbacks when VC is deallocated (prevents crashes on backgrounding)
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
        do {
            trackerStore = try TrackerStore()
            categoryStore = try TrackerCategoryStore()
            recordStore = try TrackerRecordStore()

            trackerStore.delegate = self
            categoryStore.delegate = self
            recordStore.delegate = self
        } catch {
            // initialization error — log and continue with empty arrays (app should not crash)
            print("❗️ Error initializing stores: \(error)")
            trackerStore = nil
            categoryStore = nil
            recordStore = nil
        }
    }

    // MARK: - Data loading + UI refresh

    /// Loads all data from stores into local arrays, then rebuilds visibleCategories and reloads collectionView safely.
    private func loadAllDataAndRefreshUI() {
        // load (safe guards)
        allTrackers = trackerStore?.trackers ?? []
        allCategories = categoryStore?.categories ?? []

        // ensure default category exists
        if allCategories.isEmpty {
            do {
                try categoryStore.add(TrackerCategory(name: "Важное", trackers: []))
                allCategories = categoryStore.categories
            } catch {
                print("❗️ can't create default category: \(error)")
            }
        }

        rebuildVisibleCategories()
        safeReloadCollectionView()
    }

    /// Rebuild categories filtered by selectedDate and search text. Categories with zero visible trackers are dropped.
    private func rebuildVisibleCategories() {
        let filteredTrackers = filteredTrackersForSelectedDateAndSearch()

        // For each category, pick trackers that belong to it (by id) and are in filteredTrackers
        visibleCategories = allCategories.compactMap { cat -> TrackerCategory? in
            // category.trackers may be empty (if you store trackers separately), so we try to match by ids:
            let categoryTrackerIds = Set(cat.trackers.map { $0.id })
            // If category has no trackers stored in it, we treat "Важное" as universal (put all)
            let trackersInCategory: [Tracker]
            if categoryTrackerIds.isEmpty {
                // For default behaviour: all filtered trackers go into "Важное"
                trackersInCategory = filteredTrackers
            } else {
                trackersInCategory = filteredTrackers.filter { categoryTrackerIds.contains($0.id) }
            }
            return trackersInCategory.isEmpty ? nil : TrackerCategory(name: cat.name, trackers: trackersInCategory)
        }

        // if no visible categories — visibleCategories stays empty and empty state is shown
    }

    /// Returns trackers filtered by selectedDate and by search text
    private func filteredTrackersForSelectedDateAndSearch() -> [Tracker] {
        // Step 1: filter by schedule/day
        let weekdayName = transformDateToWeekday(selectedDate)
        let dayOpt = Weekdays.fromString(weekdayName)

        var byDate: [Tracker]
        if let day = dayOpt {
            byDate = allTrackers.filter { $0.schedule.contains(day) }
        } else {
            byDate = allTrackers
        }

        // Step 2: filter by search text (if any)
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return byDate
        } else {
            let lower = searchText.lowercased()
            return byDate.filter { $0.name.lowercased().contains(lower) }
        }
    }

    private func safeReloadCollectionView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // avoid reloading when VC is not visible (prevents crashes on background/suspend)
            if self.isViewLoaded && self.view.window != nil {
                self.updateEmptyState()
                self.collectionView.reloadData()
            } else {
                // still update empty state logic in memory (so when view appears it will be correct)
                self.updateEmptyState()
            }
        }
    }

    private func updateEmptyState() {
        // if no visible categories -> show empty state
        if visibleCategories.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }

    // MARK: - Helpers
    private func transformDateToWeekday(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    // MARK: - Actions
    @objc private func plusTapped() {
        let createVC = CreateNewHabbitViewController()
        createVC.delegate = self  // делегат передаётся дальше в HabbitRegisterViewController
        let nav = UINavigationController(rootViewController: createVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }


    @objc private func datePickerChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
        rebuildVisibleCategories()
        safeReloadCollectionView()
    }

    // MARK: - Empty state UI
    private func showEmptyState() {
        // add only if not already in hierarchy
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
        return visibleCategories.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleCategories[section].trackers.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.section < visibleCategories.count,
              indexPath.item < visibleCategories[indexPath.section].trackers.count else {
            return UICollectionViewCell()
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: trackerCellId, for: indexPath) as! TrackerCollectionViewCell
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]

        // Query recordStore to decide if tracker completed for selectedDate
        let isCompleted = recordStore?.isTrackerCompleted(tracker, on: selectedDate) ?? false
        let completedCount = recordStore?.records.filter { $0.id == tracker.id }.count ?? 0

        cell.configure(with: tracker, index: indexPath.item, isCompleted: isCompleted, selectDate: selectedDate, completedDays: completedCount)
        cell.delegate = self
        return cell
    }

    // Header
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              indexPath.section < visibleCategories.count else {
            return UICollectionReusableView()
        }
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: TrackerSectionHeader.reuseId,
                                                                     for: indexPath) as! TrackerSectionHeader
        header.titleLabel.text = visibleCategories[indexPath.section].name
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 168, height: 150)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        // if section has trackers, return header height; otherwise zero
        return visibleCategories[section].trackers.isEmpty ? .zero : CGSize(width: collectionView.bounds.width, height: 44)
    }
}

// MARK: - TrackerCollectionViewCellDelegate
extension MainViewController: TrackerCollectionViewCellDelegate {
    func didTapCompleteButton(for tracker: Tracker, in date: Date, isCompleted: Bool) {
        // Toggle completion for a single DAY (store should handle day-range matching internally)
        // Use startOfDay usage inside store methods (we assume recordStore does this).
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                if self.recordStore?.isTrackerCompleted(tracker, on: date) == true {
                    try self.recordStore.deleteRecord(for: tracker, date: date)
                } else {
                    try self.recordStore.addRecord(for: tracker, date: date)
                }
                // After successful save/delete, reload from stores on main thread
                DispatchQueue.main.async {
                    self.loadAllDataAndRefreshUI()
                }
            } catch {
                print("❗️ Error toggling record: \(error)")
            }
        }
    }
}

// MARK: - HabbitRegisterViewControllerDelegate
extension MainViewController: HabbitRegisterViewControllerDelegate {
    func didCreateNewTracker(_ tracker: Tracker) {
        // Save tracker and add to "Важное" category; do it in background to avoid UI freeze
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try self.trackerStore.addNewTracker(tracker)
                
                DispatchQueue.main.async {
                    self.loadAllDataAndRefreshUI()
                }
            } catch {
                print("❗️ Error saving new tracker: \(error)")
            }
        }
    }
}

// MARK: - Store Delegates
extension MainViewController: TrackerStoreDelegate, TrackerCategoryStoreDelegate, TrackerRecordStoreDelegate {
    func didUpdateTrackers() {
        // store content was changed — reload arrays then UI safely
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
        // records changed — completion state/count may have changed
        // we reload visible trackers counts safely
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
