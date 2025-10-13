//
//  TrackerRecordStore.swift
//  Tracker
//
//  Created by Волошин Александр on 10/09/25.
//

import UIKit
import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func didUpdateRecords()
}

final class TrackerRecordStore: NSObject {
    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData>
    weak var delegate: TrackerRecordStoreDelegate?
    
    // MARK: - Initф

    convenience override init() {
        // Пытаемся безопасно получить AppDelegate и context
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            do {
                try self.init(context: context)
            } catch {
                fatalError("❌ Ошибка инициализации TrackerStore с основным контекстом: \(error)")
            }
        } else {
            // fallback — создаем in-memory Core Data (например, при тестах или SwiftUI)
            let container = NSPersistentContainer(name: "Tracker")
            container.loadPersistentStores { _, error in
                if let error = error {
                    print("⚠️ Ошибка загрузки in-memory хранилища: \(error)")
                }
            }
            let context = container.viewContext
            do {
                try self.init(context: context)
            } catch {
                fatalError("❌ Ошибка инициализации TrackerStore с in-memory контекстом: \(error)")
            }
        }
    }

    
    init(context: NSManagedObjectContext) throws {
        self.context = context
        
        let fetchRequest: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        self.fetchedResultsController = controller
        super.init()
        
        controller.delegate = self
        try controller.performFetch()
    }
    
    // MARK: - Records
    var records: [TrackerRecord] {
        fetchedResultsController.fetchedObjects?.compactMap { convertToRecord(from: $0) } ?? []
    }
    
    // MARK: - Convert CoreData -> Model
    private func convertToRecord(from coreData: TrackerRecordCoreData) -> TrackerRecord? {
        guard let id = coreData.id, let date = coreData.date else { return nil }
        return TrackerRecord(id: id, date: date)
    }
    
    // MARK: - Add Record (mark as completed)
    func addRecord(for tracker: Tracker, date: Date) throws {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let recordCD = TrackerRecordCoreData(context: context)
        recordCD.id = tracker.id
        recordCD.date = startOfDay
        
        // Устанавливаем связь с TrackerCoreData
        let trackerRequest: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        trackerRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        if let trackerCD = try context.fetch(trackerRequest).first {
            recordCD.tracker = trackerCD
        }
        
        try context.save()
    }
    
    // MARK: - Delete Record (unmark)
    func deleteRecord(for tracker: Tracker, date: Date) throws {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
                format: "id == %@ AND (date >= %@) AND (date < %@)",
                tracker.id as CVarArg, startOfDay as NSDate, endOfDay as NSDate
            )
        
        let records = try context.fetch(request)
        records.forEach { context.delete($0) }
        try context.save()
    }
    
    // MARK: - Check if tracker completed
    func isTrackerCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }


        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(
            format: "id == %@ AND (date >= %@) AND (date < %@)",
            tracker.id as CVarArg, startOfDay as NSDate, endOfDay as NSDate
        )

        let count = (try? context.count(for: request)) ?? 0
        return count > 0
    }

}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateRecords()
    }
}

