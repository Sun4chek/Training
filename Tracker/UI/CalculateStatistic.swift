import Foundation
import CoreData

final class CalculateStatistics {
    
    private let trackerRecordStore: TrackerRecordStore
    private let trackerStore: TrackerStore
    
    init(trackerRecordStore: TrackerRecordStore, trackerStore: TrackerStore) {
        self.trackerRecordStore = trackerRecordStore
        self.trackerStore = trackerStore
    }
    
    struct Statistics {
        let bestPeriod: Int
        let idealDays: Int
        let completedTrackers: Int
        let averageTrackersPerDay: Int
    }
    
    func calculateStatistics() -> Statistics {
        // Используем только те методы, которые есть в ваших сторах
        let records = trackerRecordStore.records // используем свойство records, а не fetchAllRecords()
        let allTrackers = trackerStore.trackers // используем свойство trackers
        
        guard !records.isEmpty else {
            return Statistics(bestPeriod: 0, idealDays: 0, completedTrackers: 0, averageTrackersPerDay: 0)
        }
        
        // MARK: - Best Period (самая длинная последовательность дней с записями)
        let uniqueDates = Set(records.map { $0.date }).sorted()
        
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
        
        // MARK: - Average Trackers Per Day
        let uniqueDaysCount = uniqueDates.count
        let average = uniqueDaysCount > 0 ? totalCompleted / uniqueDaysCount : 0
        
        // MARK: - Ideal Days (дни когда выполнены все доступные трекеры)
        let allTrackersCount = allTrackers.count
        var idealDaysCount = 0
        
        if allTrackersCount > 0 {
            // Группируем записи по дням
            let recordsByDay = Dictionary(grouping: records) { record in
                Calendar.current.startOfDay(for: record.date)
            }
            
            for (_, dailyRecords) in recordsByDay {
                // Считаем уникальные выполненные трекеры за день
                let uniqueTrackersInDay = Set(dailyRecords.map { $0.id }).count
                if uniqueTrackersInDay == allTrackersCount {
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
}
