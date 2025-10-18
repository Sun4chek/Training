//
//  NewCategoryViewController.swift
//  Tracker
//
//  Created by Волошин Александр on 10/18/25.
//

import UIKit

final class NewCategoryViewController: UIViewController {
    
    private let viewModel: NewCategoryViewModel
    var onCategoryCreated: ((String) -> Void)?
    
    private let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Введите название категории"
        tf.font = UIFont.systemFont(ofSize: 17)
        tf.backgroundColor = .secondarySystemBackground
        tf.layer.cornerRadius = 16
        tf.setLeftPaddingPoints(12)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private lazy var okButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.backgroundColor = .systemGray3 // ❌ неактивна изначально
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.titleLabel?.font = UIFont(name: "SFProText-Medium", size: 16)
        button.isEnabled = false
        button.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init(viewModel: NewCategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Новая категория"
        setupUI()
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    private func setupUI() {
        view.addSubview(textField)
        view.addSubview(okButton)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 60),
            
            okButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            okButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            okButton.heightAnchor.constraint(equalToConstant: 60),
            okButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func textFieldDidChange() {
        let hasText = !(textField.text?.isEmpty ?? true)
        okButton.isEnabled = hasText
        okButton.backgroundColor = hasText ? .ypBlack : .systemGray3
    }
    
    @objc private func okButtonTapped() {
        guard let name = textField.text, !name.isEmpty else { return }
        viewModel.createCategory(name: name)
        onCategoryCreated?(name)
        dismiss(animated: true)
    }
}

// MARK: - Padding Extension
private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
}

