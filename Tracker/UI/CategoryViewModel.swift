final class CategoryListViewModel {
    let store: TrackerCategoryStore
    
    var categories: [TrackerCategory] = [] {
        didSet { onUpdate?() }
    }
    
    var onUpdate: (() -> Void)?
    
    init(store: TrackerCategoryStore) {
        self.store = store
        loadCategories()
    }
    
    func loadCategories() {
        // Загружаем категории без дубликатов
        var unique = Set<String>()
        categories = store.categories.filter { category in
            let name = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if unique.contains(name.lowercased()) {
                return false
            } else {
                unique.insert(name.lowercased())
                return true
            }
        }
    }
    
    func addCategory(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Проверка на дубликаты перед добавлением
        if store.categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            loadCategories()
            return
        }
        
        let newCategory = TrackerCategory(name: trimmed, trackers: [])
        do {
            try store.add(newCategory)
            loadCategories()
        } catch {
            print("❌ Ошибка добавления категории: \(error)")
        }
    }
}




