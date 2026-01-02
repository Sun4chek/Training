//
//  Untitled 2.swift
//  Tracker
//
//  Created by Волошин Александр on 9/26/25.
//

import UIKit
import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func didUpdateCategories()
}

final class TrackerCategoryStore : NSObject {
    private let context: NSManagedObjectContext
    private let fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData>
    weak var delegate: TrackerCategoryStoreDelegate?
    
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


    init(context: NSManagedObjectContext)  throws{
        self.context = context
        
        
        
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]
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
    
    var categories: [TrackerCategory] {
        guard
            let object = self.fetchedResultsController.fetchedObjects,
            let category = try? object.map({ try convertToCategory(from: $0) })
        else {
            return []
        }
        return category
    }

    // MARK: - Преобразование CoreData -> Модель
    private func convertToCategory(from coreData: TrackerCategoryCoreData) throws -> TrackerCategory {
        guard let name = coreData.name else {
            throw NSError(domain: "TrackerStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ошибка преобразования данных"])
        }
        
        // Получаем трекеры через связь
        let trackersSet = coreData.trackers as? Set<TrackerCoreData> ?? []
        let trackers: [Tracker] = trackersSet.compactMap { trackerCD in
            guard let id = trackerCD.id,
                  let name = trackerCD.name,
                  let emoji = trackerCD.emoji,
                  let color = trackerCD.color as? UIColor,
                  let schedule = trackerCD.schedule as? [Weekdays] else {
                print("❌ Ошибка преобразования трекера в категории '\(name)'")
                return nil
            }
            return Tracker(id: id, name: name, color: color, emoji: emoji, schedule: schedule)
        }
        
        print("🔄 Категория '\(name)' содержит \(trackers.count) трекеров")
        for tracker in trackers {
            print("   - \(tracker.name)")
        }
        
        return TrackerCategory(name: name, trackers: trackers)
    }
    
    // MARK: - Create / Delete
    func add(_ category: TrackerCategory)  throws{
        let trCategory = TrackerCategoryCoreData(context: context)
        trCategory.name = category.name
        try context.save()
    }

    func delete(_ category: TrackerCategory) throws {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", category.name)
        do {
            let results = try context.fetch(request)
            results.forEach { context.delete($0) }
            try context.save()
        } catch {
            print(" Ошибка delete TrackerCategory: \(error)")
        }
    }
    
    func addTrackerToCategory(_ tracker: Tracker, to categoryName: String) throws {
        let request = NSFetchRequest<TrackerCategoryCoreData>(entityName: "TrackerCategoryCoreData")
        request.predicate = NSPredicate(format: "name == %@", categoryName)
        
        do {
            let results = try context.fetch(request)
            let cdCategory: TrackerCategoryCoreData
            if let existing = results.first {
                cdCategory = existing
            } else {
                cdCategory = TrackerCategoryCoreData(context: context)
                cdCategory.name = categoryName
            }
            
            let cdTracker = TrackerCoreData(context: context)
            cdTracker.id = tracker.id
            cdTracker.name = tracker.name
            cdTracker.color = tracker.color
            cdTracker.emoji = tracker.emoji
            cdTracker.schedule = tracker.schedule as NSObject
            
            var trackersSet = cdCategory.trackers as? Set<TrackerCoreData> ?? []
            trackersSet.insert(cdTracker)
            cdCategory.trackers = trackersSet as NSSet
            
            try context.save()
            
        }
        catch {
            print(" Ошибка добавления трекера в категорию: \(error)")
        }
        
        
        
    }

}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateCategories()

    }
}
