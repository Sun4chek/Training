//
//  CoreDataStack.swift
//  Tracker
//
//  Created by Волошин Александр on 10/13/25.
//

import CoreData
import UIKit

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer
    var context: NSManagedObjectContext { persistentContainer.viewContext }

    private init() {
        persistentContainer = NSPersistentContainer(name: "Tracker")
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("❌ Ошибка инициализации Core Data: \(error)")
            }
        }
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ Ошибка сохранения контекста: \(error)")
            }
        }
    }
}
