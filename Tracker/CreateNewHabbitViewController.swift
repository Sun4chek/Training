import UIKit

class CreateNewHabbitViewController: UIViewController {
    
    weak var delegate: HabbitRegisterViewControllerDelegate?
    
    private lazy var habbitButton: UIButton = {
        let button = UIButton()
        let habbit = NSLocalizedString("Habbit", comment: "")
        button.setTitle(habbit, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.backgroundColor = UIColor(named : "ypBlack")
        button.tintColor = .white
        button.addTarget(self, action: #selector(createHabbit), for: .touchUpInside)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let createTracker = NSLocalizedString("createTracker", comment: "")
        navigationItem.title = createTracker
        
        setupUI()
    }

    func setupUI() {
        
        view.addSubview(habbitButton)
        
        NSLayoutConstraint.activate([
            habbitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            habbitButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            habbitButton.widthAnchor.constraint(equalToConstant: 335),
            habbitButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc func createHabbit() {
        let createHabitVC = HabbitRegisterViewController()
        createHabitVC.delegate = self.delegate
                navigationController?.pushViewController(createHabitVC, animated: true)
    }
}
