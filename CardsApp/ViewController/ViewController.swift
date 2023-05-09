//
//  ViewController.swift
//  CardsApp
//
//  Created by Yulia Ignateva on 19.04.2023.
//

import UIKit

class ViewController: UIViewController, ModelDelegate, ViewDelegate {
    var model: Model? = nil
    var mainPageView: MainPageView? = nil
    var newWordView: NewWordView? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let model = Model()
        self.model = model
        model.delegate = self
        
        model.viewDidLoad()
    }
    
    func showMainPageView() {
        let mainPageView = MainPageView()
        self.mainPageView = mainPageView
        mainPageView.delegate = self
        
        navigationController?.isNavigationBarHidden = true
        
        view.addSubview(mainPageView)
        
        mainPageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainPageView.topAnchor.constraint(equalTo: view.topAnchor),
            mainPageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mainPageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainPageView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    func didTapNewWordButton() {
        model?.didTapNewWordButton()
    }
    
    func showNewWordView() {
        let newWordTextFieldDelegate = NewWordTextFieldDelegate()
        let translationTextFieldDelegate = TranslationTextFieldDelegate()
        let contextTextViewDelegate = ContextTextViewDelegate()
        
        let newWordView = NewWordView(
            newWordTextFieldDelegate: newWordTextFieldDelegate,
            translationTextFieldDelegate: translationTextFieldDelegate,
            contextTextViewDelegate: contextTextViewDelegate)
        self.newWordView = newWordView
        newWordView.delegate = self
        
        contextTextViewDelegate.didAttach(to: newWordView.context.textView)
        
        newWordTextFieldDelegate.delegate = model
        translationTextFieldDelegate.delegate = model
        contextTextViewDelegate.delegate = model
        
        navigationController?.isNavigationBarHidden = false
        let backButton = UIBarButtonItem(image: UIImage(named: "BackButton"), style: .plain, target: self, action: #selector(didTapBackButton))
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
        
        view.addSubview(newWordView)
        
        newWordView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newWordView.topAnchor.constraint(equalTo: view.topAnchor),
            newWordView.leftAnchor.constraint(equalTo: view.leftAnchor),
            newWordView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            newWordView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
    }
    
    @objc private func didTapBackButton() {
        model?.didTapBackButton()
    }
    
    func didTapTrainingButton() {
        model?.didTapTrainingButton()
    }
    
    func showTrainingView() {
        print("tapped")
    }
    
    func didTapSaveButton() {
        model?.didTapSaveButton()
    }
    
    func showSavingError() {
        let alert = UIAlertController(title: nil, message: "Ошибка сохранения данных", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
