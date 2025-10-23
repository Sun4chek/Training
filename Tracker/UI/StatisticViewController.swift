import UIKit
import CoreData

final class StatisticsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("statistics.title", comment: "Статистика")
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.isScrollEnabled = false
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return table
    }()
    
    // MARK: - Placeholder UI
    private lazy var placeholderImage: UIImageView = {
        let iv = UIImageView(image: UIImage(resource: .analise))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("statistics.placeholder.empty", comment: "Анализировать пока нечего")
        l.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        l.textAlignment = .center
        l.numberOfLines = 0
        
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    // MARK: - Layout Constraints
    private var tableViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Data
    private var items: [(Int, String)] = []
    private var trackerRecordStore: TrackerRecordStore?
    private var trackerStore: TrackerStore?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupStores()
        setupLayout()
        setupTableView()
        loadStatistics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📊 Statistics: экран показан — обновляем статистику")
        loadStatistics()
    }
    
    // MARK: - Setup Stores
    private func setupStores() {
        // Создаем стора так же, как в главном экране
        trackerRecordStore = TrackerRecordStore()
        trackerStore = TrackerStore()
        
        // Подписываемся на обновления
        trackerRecordStore?.delegate = self
        trackerStore?.delegate = self
    }
    
    // MARK: - Load Data
    // MARK: - Load Data
    private func loadStatistics() {
        guard let recordStore = trackerRecordStore,
              let trackerStore = trackerStore else { return }
        
        let records = recordStore.records
        let trackers = trackerStore.trackers
        
        print("📊 ===== НАЧАЛО РАСЧЕТА СТАТИСТИКИ =====")
        print("📊 Исходные данные:")
        print("   - Всего записей в recordStore: \(records.count)")
        print("   - Всего трекеров в trackerStore: \(trackers.count)")
        
        // Выводим информацию о записях
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        print("📊 Все записи:")
        for record in records {
            print("   - ID: \(record.id), Дата: \(dateFormatter.string(from: record.date))")
        }
        
        let stats = calculateStatistics(records: records, trackers: trackers)
        
        items = [
            (stats.bestPeriod, NSLocalizedString("statistics.best_period_label", comment: "Лучший период")),
            (stats.idealDays, NSLocalizedString("statistics.ideal_days_label", comment: "Идеальные дни")),
            (stats.completedTrackers, NSLocalizedString("statistics.completed_trackers_label", comment: "Трекеров завершено")),
            (stats.averageTrackersPerDay, NSLocalizedString("statistics.average_label", comment: "Среднее значение"))
        ]
        
        print("📊 ФИНАЛЬНЫЕ РЕЗУЛЬТАТЫ:")
        print("   - Лучший период: \(stats.bestPeriod)")
        print("   - Идеальные дни: \(stats.idealDays)")
        print("   - Завершено трекеров: \(stats.completedTrackers)")
        print("   - Среднее в день: \(stats.averageTrackersPerDay)")
        print("📊 ===== КОНЕЦ РАСЧЕТА СТАТИСТИКИ =====")
        
        tableView.reloadData()
        updateTableHeight()
        updatePlaceholderVisibility()
    }
    
    // MARK: - Statistics Calculation
    // MARK: - Statistics Calculation
    // MARK: - Statistics Calculation
    private func calculateStatistics(records: [TrackerRecord], trackers: [Tracker]) -> Statistics {
        guard !records.isEmpty else {
            return Statistics(bestPeriod: 0, idealDays: 0, completedTrackers: 0, averageTrackersPerDay: 0)
        }
        
        // MARK: - Best Period
        let uniqueDates = Set(records.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
        
        var bestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for date in uniqueDates {
            if let previous = previousDate {
                let daysBetween = Calendar.current.dateComponents([.day], from: previous, to: date).day ?? 0
                if daysBetween == 1 {
                    currentStreak += 1
                } else if daysBetween > 1 {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            bestStreak = max(bestStreak, currentStreak)
            previousDate = date
        }
        
        // MARK: - Completed Trackers
        let totalCompleted = records.count
        
        // MARK: - Average Trackers Per Day (ДЕТАЛЬНАЯ ОТЛАДКА)
        let uniqueDaysCount = uniqueDates.count
        let average: Int
        
        print("=== ДЕТАЛЬНЫЙ РАСЧЕТ СРЕДНЕГО ЗНАЧЕНИЯ ===")
        print("Всего записей: \(totalCompleted)")
        print("Уникальных дней: \(uniqueDaysCount)")
        
        // Выводим все уникальные даты
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        print("Уникальные даты:")
        for date in uniqueDates {
            print("  - \(dateFormatter.string(from: date))")
        }
        
        if uniqueDaysCount > 0 {
            let exactAverage = Double(totalCompleted) / Double(uniqueDaysCount)
            average = Int(exactAverage.rounded())
            print("Точное среднее: \(exactAverage)")
            print("Округленное среднее: \(average)")
        } else {
            average = 0
            print("Нет уникальных дней - среднее: 0")
        }
        print("========================================")
        
        // MARK: - Ideal Days
        var idealDaysCount = 0
        
        if !trackers.isEmpty {
            let recordsByDay = Dictionary(grouping: records) { record in
                Calendar.current.startOfDay(for: record.date)
            }
            
            for (day, dailyRecords) in recordsByDay {
                let weekday = getWeekday(from: day)
                
                let availableTrackersCount = trackers.filter { tracker in
                    tracker.schedule.contains(weekday)
                }.count
                
                let completedTrackersInDay = Set(dailyRecords.map { $0.id }).count
                
                if availableTrackersCount > 0 && completedTrackersInDay == availableTrackersCount {
                    idealDaysCount += 1
                }
            }
        }
        
        return Statistics(
            bestPeriod: bestStreak,
            idealDays: idealDaysCount,
            completedTrackers: totalCompleted,
            averageTrackersPerDay: average
        )
    }

    // MARK: - Helper Methods
    private func getWeekday(from date: Date) -> Weekdays {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date)
        
        // Преобразуем номер дня недели в наш enum Weekdays
        switch weekdayNumber {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
    
    // MARK: - Statistics Model
    private struct Statistics {
        let bestPeriod: Int
        let idealDays: Int
        let completedTrackers: Int
        let averageTrackersPerDay: Int
    }
    
    // MARK: - Placeholder Logic
    private func updatePlaceholderVisibility() {
        let hasRecords = !(trackerRecordStore?.records.isEmpty ?? true)
        placeholderImage.isHidden = hasRecords
        placeholderLabel.isHidden = hasRecords
        tableView.isHidden = !hasRecords
    }
    
    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        view.addSubview(placeholderImage)
        view.addSubview(placeholderLabel)
        
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Placeholder
            placeholderImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImage.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            placeholderImage.widthAnchor.constraint(equalToConstant: 80),
            placeholderImage.heightAnchor.constraint(equalToConstant: 80),
            
            placeholderLabel.topAnchor.constraint(equalTo: placeholderImage.bottomAnchor, constant: 8),
            placeholderLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
        
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableViewHeightConstraint.isActive = true
        
        // Изначально скрываем плейсхолдер
        placeholderImage.isHidden = true
        placeholderLabel.isHidden = true
    }
    
    private func updateTableHeight() {
        let totalHeight = CGFloat(items.count * 90 + (items.count - 1) * 16)
        tableViewHeightConstraint.constant = totalHeight
    }
    
    private func setupTableView() {
        tableView.register(StatisticsTableViewCell.self, forCellReuseIdentifier: "StatisticsCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    deinit {
        // Отписываемся от делегатов
        trackerRecordStore?.delegate = nil
        trackerStore?.delegate = nil
    }
}

// MARK: - Store Delegates
extension StatisticsViewController: TrackerRecordStoreDelegate, TrackerStoreDelegate {
    func didUpdateRecords() {
        print("📊 StatisticsViewController: записи обновились — пересчитываем статистику")
        loadStatistics()
    }
    
    func didUpdateTrackers() {
        print("📊 StatisticsViewController: трекеры обновились — пересчитываем статистику")
        loadStatistics()
    }
    
    func didUpdateCategories() {
        // Не нужно для статистики, но метод требуется протоколом
    }
}

// MARK: - UITableViewDataSource
extension StatisticsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StatisticsCell", for: indexPath) as? StatisticsTableViewCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.section]
        cell.configure(title: item.0, subtitle: item.1)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension StatisticsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section < items.count - 1 ? 16 : 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}
