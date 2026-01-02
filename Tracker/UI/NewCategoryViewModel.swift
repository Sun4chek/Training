//
//  Untitled.swift
//  Tracker
//
//  Created by Волошин Александр on 10/18/25.
//

import Foundation

final class NewCategoryViewModel {
    private let store: TrackerCategoryStore
    
    init(store: TrackerCategoryStore) {
        self.store = store
    }
    
    func createCategory(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newCategory = TrackerCategory(name: name, trackers: [])
        do {
            try store.add(newCategory)
        } catch {
            print("❌ Ошибка добавления категории: \(error)")
        }
    }
}
