import UIKit

final class CategoryListViewController: UIViewController {
    
    // MARK: - Binding
    var onCategorySelected: ((String) -> Void)?
    
    // MARK: - Properties
    private let viewModel: CategoryListViewModel
    private var selectedCategoryName: String?
    
    private var options: [TrackerCategory] = []
    
    // MARK: - UI
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(SettingsCell.self, forCellReuseIdentifier: "SettingsCell")
        table.separatorStyle = .singleLine
        table.layer.cornerRadius = 16
        table.backgroundColor = .secondarySystemBackground
        table.clipsToBounds = true
        table.allowsSelection = true
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        return table
    }()
    
    
  
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        let addCategory = NSLocalizedString("addCategory", comment: "")
        button.setTitle(addCategory, for: .normal)
        button.backgroundColor = .ypBlack
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    
    
    // MARK: - Init
    init(selectedCategory: String? = nil, store: TrackerCategoryStore) {
        self.selectedCategoryName = selectedCategory
        self.viewModel = CategoryListViewModel(store: store)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let category = NSLocalizedString("category", comment: "")
        view.backgroundColor = .systemBackground
        navigationItem.title = category
        navigationItem.hidesBackButton = true
        setupUI()
        setupBindings()
        viewModel.loadCategories()
    }
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -24),
            
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupBindings() {
        viewModel.onUpdate = { [weak self] in
            self?.options = self?.viewModel.categories ?? []
            self?.tableView.reloadData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func addCategoryTapped() {
        let newCategoryVM = NewCategoryViewModel(store: viewModel.store)
        let newCategoryVC = NewCategoryViewController(viewModel: newCategoryVM)
        
        newCategoryVC.onCategoryCreated = { [weak self] name in
            self?.viewModel.addCategory(name: name)
        }
        
        present(newCategoryVC, animated: true)
    }
}

// MARK: - UITableViewDataSource


extension CategoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let category = options[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "SettingsCell", for: indexPath
        ) as? SettingsCell else {
            return UITableViewCell()
        }
        
        let isSelected = category.name == selectedCategoryName
        let accessory: SettingsCellAccessory = .checkmark(isSelected)
        cell.configure(title: category.name, accessory: accessory)
        cell.backgroundColor = .secondarySystemBackground
        cell.contentView.backgroundColor = .secondarySystemBackground
        return cell
    }
    
    // убираем линию перед первой ячейкой
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
}

// MARK: - UITableViewDelegate
extension CategoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCategoryName = options[indexPath.row].name
        tableView.reloadData()
        
        guard let selected = selectedCategoryName else { return }
        onCategorySelected?(selected)
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}
