//
//  CreateNewHabbit.swift
//  Tracker
//
//  Created by Волошин Александр on 9/8/25.
//

import UIKit

class CreateNewHabbitViewController: UIViewController {
    
    weak var delegate: HabbitRegisterViewControllerDelegate?
    
    private lazy var habbitButton: UIButton = {
        let button = UIButton()
        button.setTitle("Привычка", for: .normal)
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
        navigationItem.title = "Создание трекера"
        
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
