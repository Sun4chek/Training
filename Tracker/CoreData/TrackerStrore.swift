//
//  Untitled.swift
//  Tracker
//
//  Created by Волошин Александр on 9/26/25.
//

import UIKit
import CoreData

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateTrackers()
}

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private let transformer = WeekdaysTransformer()
    private var fetchedResultsController: NSFetchedResultsController<TrackerCoreData>
    weak var delegate: TrackerStoreDelegate?
    
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
        
        
        
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
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
    
    
    var trackers : [Tracker] {
        guard
            let objects = self.fetchedResultsController.fetchedObjects,
            let trackers = try? objects.map({ try convertToTracker(from: $0) })
        else { return [] }
        return trackers
    }
    
    
    // MARK: - Преобразование CoreData -> Модель
    private func convertToTracker(from coreData: TrackerCoreData) throws -> Tracker {
        guard
            let id = coreData.id,
            let name = coreData.name,
            let emoji = coreData.emoji,
            let color = coreData.color as? UIColor,
            let schedule = coreData.schedule as? [Weekdays]
        else {
            throw NSError(domain: "TrackerStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ошибка преобразования данных"])
        }
        
        return Tracker(id: id, name: name, color: color, emoji: emoji, schedule: schedule)
    }
    
    
    
    
    // MARK: - Добавление нового трекера
    // Внутри TrackerStore
    func addNewTracker(_ tracker: Tracker, toCategoryName categoryName: String) throws {
        var saveError: Error?
        
        context.performAndWait {
            do {
                // 1. Создаём трекер
                let trackerCD = TrackerCoreData(context: context)
                trackerCD.id = tracker.id
                trackerCD.name = tracker.name
                trackerCD.emoji = tracker.emoji
                trackerCD.color = tracker.color
                trackerCD.schedule = tracker.schedule as NSObject
                
                // 2. Находим или создаем категорию
                let categoryRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
                categoryRequest.predicate = NSPredicate(format: "name == %@", categoryName)
                
                let categoryResults = try context.fetch(categoryRequest)
                let cdCategory: TrackerCategoryCoreData
                
                if let existingCategory = categoryResults.first {
                    cdCategory = existingCategory
                    print("✅ Найдена существующая категория: '\(categoryName)'")
                } else {
                    cdCategory = TrackerCategoryCoreData(context: context)
                    cdCategory.name = categoryName
                    print("✅ Создана новая категория: '\(categoryName)'")
                }
                
                // 3. Устанавливаем связь категория -> трекер
                trackerCD.category = cdCategory
                
                // 4. Также добавляем трекер в множество трекеров категории
                let currentTrackers = cdCategory.mutableSetValue(forKey: "trackers")
                currentTrackers.add(trackerCD)
                
                // 5. Сохраняем
                try context.save()
                print("✅ Трекер '\(tracker.name)' успешно сохранен в категорию '\(categoryName)'")
                
            } catch {
                print("❌ Ошибка сохранения трекера: \(error)")
                saveError = error
            }
        }
        
        // Пробрасываем ошибку наружу, если была
        if let saveError = saveError {
            throw saveError
        }
    }

    
    // MARK: - Удаление трекера
    func deleteTracker(_ tracker: Tracker) throws {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        if let object = try context.fetch(request).first {
            context.delete(object)
            try context.save()
        }
    }
    
    
    func updateTracker(_ tracker: Tracker) {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        do {
            if let cdTracker = try context.fetch(request).first {
                cdTracker.name = tracker.name
                cdTracker.color = tracker.color
                cdTracker.emoji = tracker.emoji
                cdTracker.schedule = tracker.schedule as NSObject
                try context.save()
            }
        } catch {
            print(" Ошибка update Tracker: \(error)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateTrackers(/*trackers*/)
    }
}

