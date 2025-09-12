//
//  CreateNewHabbit.swift
//  Tracker
//
//  Created by Волошин Александр on 9/8/25.
//

import UIKit

class CreateNewHabbitViewController: UIViewController {
    
    private lazy var habbitButton: UIButton = {
        let button = UIButton()
        button.setTitle("Привычка", for: .normal)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.addTarget(self, action: #selector(createHabbit), for: .touchUpInside)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    
    
    func setupUI() {
        view.backgroundColor = UIColor(named : "ypGrey")
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
                navigationController?.pushViewController(createHabitVC, animated: true)
        

    }
}
