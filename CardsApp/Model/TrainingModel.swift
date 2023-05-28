//
//  TrainingModel.swift
//  CardsApp
//
//  Created by Yulia Ignateva on 25.05.2023.
//

import UIKit
import CoreData

final class TrainingModel {
    weak var delegate: TrainingModelDelegate?
    
    private let coreDataContext = CoreData.shared.viewContext
    private var savedWords: [Words] {
        return fetchData(coreDataContext)
    }
    private var trainingWords = Set<String>()
    private var trainingWord: String? = nil
    private var translationTrainingWord: String? = nil
    private var contextTrainingWord: String? = nil
    private var lastShowWordTranslation: Bool? = nil
    
    func viewDidLoad() {
        trainingWords = formTrainingWords(from: savedWords)
        
        if trainingWords.isEmpty && savedWords.isEmpty {
            delegate?.showNoSavedWordsError()
        } else if trainingWords.isEmpty && !savedWords.isEmpty {
            delegate?.showNoTodayTrainingWords()
        } else {
            showTrainingWord()
        }
    }
    
    func didTapOnTrainingView() {
        delegate?.showWordDetailsView()
    }
    
    func didTapBackButton() {
        delegate?.notifyCompletion()
    }
    
    func didTapKnownWordButton() {
        var word: Words? = nil
        
        for savedword in savedWords {
            if savedword.word == trainingWord {
                word = savedword
                break
            }
        }
        
        guard let word = word else { return }
        guard let lastShowTranslation = lastShowWordTranslation else { return }
        
        do {
            word.guess += 1
            word.date = Date()
            word.lastShowTranslation = lastShowTranslation
            
            if lastShowTranslation {
                word.showTranslation += 1
            } else {
                word.showOriginal += 1
            }
            
            if word.guess > 25 {
                coreDataContext.delete(word)
            }
            
            try coreDataContext.save()
            
            trainingWord = nil
            translationTrainingWord = nil
            contextTrainingWord = nil
            lastShowWordTranslation = nil
            
            guard !trainingWords.isEmpty else {
                delegate?.showFinishTraining()
                return
            }
            showTrainingWord()
        } catch {
            delegate?.showSavingChangesError()
        }
    }
    
    func didTapUnknownWordButton() {
        var word: Words? = nil
        
        for savedword in savedWords {
            if savedword.word == trainingWord {
                word = savedword
                break
            }
        }
        
        guard let word = word else { return }
        guard let lastShowTranslation = lastShowWordTranslation else { return }
        
        do {
            word.date = Date()
            word.lastShowTranslation = lastShowTranslation
            
            if lastShowTranslation {
                word.showTranslation += 1
            } else {
                word.showOriginal += 1
            }
            
            try coreDataContext.save()
            
            trainingWord = nil
            translationTrainingWord = nil
            contextTrainingWord = nil
            lastShowWordTranslation = nil
            
            guard !trainingWords.isEmpty else {
                delegate?.showFinishTraining()
                return
            }
            
            showTrainingWord()
        } catch {
            delegate?.showSavingChangesError()
        }
    }
    
    private func showTrainingWord() {
        let displayedWord = trainingWords.removeFirst()
        var displayedWordWithDetails: Words? = nil
        
        for word in savedWords {
            if word.word == displayedWord || word.translation == displayedWord {
                displayedWordWithDetails = word
                break
            }
        }
        
        guard let trainingWord = displayedWordWithDetails else { return } //здесь нужно ошибку какую-то выдать?

        // ставим флажок как показывается слово: перевод или оригинал
        if displayedWord == trainingWord.word {
            lastShowWordTranslation = false
        } else if displayedWord == trainingWord.translation {
            lastShowWordTranslation = true
        }
        
        self.trainingWord = trainingWord.word
        self.translationTrainingWord = trainingWord.translation
        self.contextTrainingWord = trainingWord.context
        
        delegate?.showTrainingView(for: trainingWord.word, translation: trainingWord.translation, context: trainingWord.context ?? "", showTranslation: lastShowWordTranslation!)
    }
    
    private func fetchData(_ context: NSManagedObjectContext) -> [Words] {
        var wordsData = [Words]()
        
        do {
            wordsData = try context.fetch(Words.fetchRequest())
        } catch {
            print("error") // показать алерт с ошибкой
        }
        
        return wordsData
    }
    
    private func formTrainingWords(from words: [Words]) -> Set<String> {
        var trainingWords = Set<String>()
        var unknownWords = 0
        var littleKnownWords = 0
        var knownWords = 0
        var translations = [Words]()
        var originalWords = [Words]()

        //добавляем слова в массив слов
        for word in words {
            if check(of: word) {
                if word.guess <= 3 && unknownWords <= 6 {
                    if word.lastShowTranslation {
                        originalWords.append(word)
                    } else {
                        translations.append(word)
                    }
                    unknownWords += 1
                } else if word.guess > 3 && word.guess <= 17 && littleKnownWords <= 18 {
                    if word.lastShowTranslation {
                        originalWords.append(word)
                    } else {
                        translations.append(word)
                    }
                    littleKnownWords += 1
                } else if word.guess > 17 && word.guess <= 25 && knownWords <= 6 {
                    if word.lastShowTranslation {
                        originalWords.append(word)
                    } else {
                        translations.append(word)
                    }
                    knownWords += 1
                }
            }
        }
        
        // проверяем достаточное ли количество известных слов, если нет, то сначала добавляем из малоизвестных, потом из неизвестных
        if knownWords != 6 {
            var requiredBalance = 6 - knownWords
            for word in words {
                if requiredBalance != 0 {
                    if check(of: word) {
                        if word.guess > 3 && word.guess <= 17 {
                            guard !translations.contains(where: { word1 in return word == word1 }) && !originalWords.contains(where: { word1 in return word == word1 }) else { continue }
                            if word.lastShowTranslation {
                                originalWords.append(word)
                            } else {
                                translations.append(word)
                            }
                            requiredBalance -= 1
                        }
                    }
                }
            }
            if requiredBalance != 0 {
                for word in words {
                    if requiredBalance != 0 {
                        if check(of: word) {
                            if word.guess <= 3 {
                                guard !translations.contains(where: { word1 in return word == word1 }) && !originalWords.contains(where: { word1 in return word == word1 }) else { continue }
                                if word.lastShowTranslation {
                                    originalWords.append(word)
                                } else {
                                    translations.append(word)
                                }
                                requiredBalance -= 1
                            }
                        }
                    }
                }
            }
        }
        
    //    // проверяем достаточное ли количество неизвестных слов, если нет, то сначала добавляем из малоизвестных, потом из известных
        if unknownWords != 6 {
            var requiredBalance = 6 - unknownWords
            for word in words {
                if requiredBalance != 0 {
                    if check(of: word) {
                        if word.guess > 3 && word.guess <= 17 {
                            guard !translations.contains(where: { word1 in return word == word1 }) && !originalWords.contains(where: { word1 in return word == word1 }) else { continue }
                            if word.lastShowTranslation {
                                originalWords.append(word)
                            } else {
                                translations.append(word)
                            }
                            requiredBalance -= 1
                        }
                    }
                }
            }
            if requiredBalance != 0 {
                for word in words {
                    if requiredBalance != 0 {
                        if check(of: word) {
                            if word.guess > 17 && word.guess <= 25 {
                                guard !translations.contains(where: { word1 in return word == word1 }) && !originalWords.contains(where: { word1 in return word == word1 }) else { continue }
                                if word.lastShowTranslation {
                                    originalWords.append(word)
                                } else {
                                    translations.append(word)
                                }
                                requiredBalance -= 1
                            }
                        }
                    }
                }
            }
            
            if littleKnownWords != 6 {
                var requiredBalance = 6 - littleKnownWords
                for word in words {
                    if requiredBalance != 0 {
                        if check(of: word) {
                            if word.guess <= 3 {
                                guard !translations.contains(where: { word1 in return word == word1 }) && !originalWords.contains(where: { word1 in return word == word1 }) else { continue }
                                if word.lastShowTranslation {
                                    originalWords.append(word)
                                } else {
                                    translations.append(word)
                                }
                                requiredBalance -= 1
                            }
                        }
                    }
                }
                if requiredBalance != 0 {
                    for word in words {
                        if requiredBalance != 0 {
                            if check(of: word) {
                                if word.guess > 17 && word.guess <= 25 {
                                    guard !translations.contains(where: { word1 in return word == word1 }) && !originalWords.contains(where: { word1 in return word == word1 }) else { continue }
                                    if word.lastShowTranslation {
                                        originalWords.append(word)
                                    } else {
                                        translations.append(word)
                                    }
                                    requiredBalance -= 1
                                }
                            }
                        }
                    }
                }
            }
        }
        
    // проверяем баланс переводов и оригинальных слов в массивe
        let normalBalance = Int(Double(originalWords.count + translations.count) * 0.6)
        if originalWords.count < normalBalance {
            var requiredBalance = normalBalance - originalWords.count
            var sortedTranslations = translations.sorted(by: { (word1, word2) -> Bool in
                return word1.showTranslation > word2.showTranslation
            })
            
            while requiredBalance != 0 {
                let word = sortedTranslations.removeFirst()
                originalWords.append(word)
                requiredBalance -= 1
                
                for index in 0..<translations.count {
                    if translations[index] == word {
                        translations.remove(at: index)
                        break
                    }
                }
            }
        } else if originalWords.count > normalBalance {
            var requiredBalance = originalWords.count - normalBalance
            var sortedOriginalWords = originalWords.sorted(by: { (word1, word2) -> Bool in
                return word1.showOriginal > word2.showOriginal
            })
            while requiredBalance != 0 {
                let word = sortedOriginalWords.removeFirst()
                translations.append(word)
                requiredBalance -= 1
                
                for index in 0..<originalWords.count {
                    if originalWords[index] == word {
                        originalWords.remove(at: index)
                        break
                    }
                }
            }
        }
        
        for word in translations {
            trainingWords.insert(word.translation)
        }
        
        for word in originalWords {
            trainingWords.insert(word.word)
        }
        
        return trainingWords
    }
    
    //метод, чтобы снизить количество угаданных случаев у слова, если человек давно не выполнял тренировку
    private func reduceSuccessRate(of word: Words) -> Bool {
        let addedWords = fetchData(coreDataContext)
        var success = false
        
        for addedWord in addedWords { // в списке ищем нужно слово
            if addedWord.word == word.word {
                do {
                    word.guess -= 2
                    try coreDataContext.save()
                    success = true
                } catch {
                    success = false
                }
                break
            }
        }
        return success
    }
    
    private func consistDateIn(interval minDays: Int, _ maxDays: Int, for word: Words) -> Bool {
        var minDate: Date {
            return Calendar.current.date(byAdding: .day, value: minDays, to: word.date!)!
        }
        var maxDate: Date {
            return Calendar.current.date(byAdding: .day, value: maxDays, to: word.date!)!
        }
        if Date().isBetween(minDate, maxDate) {
            return true
        } else if Date() > maxDate {
            if word.guess > 3 && word.guess <= 17 {
                if reduceSuccessRate(of: word) == false {
                    delegate?.showSavingChangesError()
                }
                return true
            } else {
                return true
            }
        }
        return false
    }
    
    private func check(of word: Words) -> Bool {
        if word.guess <= 3 {
            guard word.date != nil else { return true }
            var wordDate: Date {
                return Calendar.current.date(byAdding: .day, value: 1, to: word.date!)!
            }
            if Date().componentize() == wordDate.componentize() {
                return true
            }
        }
        
        if word.guess > 3 && word.guess <= 8 {
            return consistDateIn(interval: 2, 5, for: word)
        }
        
        if word.guess > 8 && word.guess <= 12 {
            return consistDateIn(interval: 3, 6, for: word)
        }
        
        if word.guess > 12 && word.guess <= 17 {
            return consistDateIn(interval: 7, 10, for: word)
        }
        
        if word.guess > 17 && word.guess <= 21 {
            return consistDateIn(interval: 15, 18, for: word)
        }
        
        if word.guess > 21 && word.guess <= 25 {
            return consistDateIn(interval: 30, 34, for: word)
        }
        return false
    }
}