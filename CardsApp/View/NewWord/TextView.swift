//
//  NewWordTextField.swift
//  CardsApp
//
//  Created by Yulia Ignateva on 19.04.2023.
//

import UIKit

final class TextView: UIView {
    private let placeholder: String
    private let textField = UITextView()
    
    init(placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        
        backgroundColor = .white
        
        configureTextView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureTextView() {
        textField.placeholder = placeholder
        textField.font = .systemFont(ofSize: 18)
        textField.textColor = .black
        textField.textAlignment = .left
        textField.layer.cornerRadius = 14.5
        textField.layer.masksToBounds = true
        
        addSubview(textField)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leftAnchor.constraint(equalTo: leftAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.rightAnchor.constraint(equalTo: rightAnchor)
        ])
    }
}