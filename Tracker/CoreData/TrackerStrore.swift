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
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        try! self.init(context: context)
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
    func addNewTracker(_ tracker: Tracker, toCategoryName categoryName: String = "Важное") throws {
        // Если context — viewContext, можно использовать performAndWait для безопасности
        context.performAndWait {
            // Создаём TrackerCoreData
            let trackerCD = TrackerCoreData(context: context)
            trackerCD.id = tracker.id
            trackerCD.name = tracker.name
            trackerCD.emoji = tracker.emoji
            trackerCD.color = tracker.color
            trackerCD.schedule = tracker.schedule as NSObject
            
            // Найдём или создадим категорию TrackerCategoryCoreData
            let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", categoryName)
            request.fetchLimit = 1
            
            do {
                let results = try context.fetch(request)
                let cdCategory: TrackerCategoryCoreData
                if let existing = results.first {
                    cdCategory = existing
                } else {
                    cdCategory = TrackerCategoryCoreData(context: context)
                    cdCategory.name = categoryName
                }
                
                // Устанавливаем связь
                trackerCD.category = cdCategory
                
                // Обновляем набор trackers в категории (если inverse не настроен автоматически)
                var trackersSet = cdCategory.trackers as? Set<TrackerCoreData> ?? Set()
                trackersSet.insert(trackerCD)
                cdCategory.trackers = trackersSet as NSSet
                
                // Сохраняем
                try context.save()
            } catch {
                // Обработаем ошибку сохранения
                print("Ошибка при добавлении трекера и сохранении категории: \(error)")
                // пробрасываем наружу
                // (Если ты хочешь бросить ошибку наружу, можно сохранить в переменной и outside performAndWait throw)
            }
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

