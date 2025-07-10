//
//  ViewController.swift
//  Trivia
//
//  Created by Mari Batilando on 4/6/23.
//

import UIKit
import Foundation

class TriviaViewController: UIViewController {
  
  @IBOutlet weak var currentQuestionNumberLabel: UILabel!
  @IBOutlet weak var questionContainerView: UIView!
  @IBOutlet weak var questionLabel: UILabel!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var answerButton0: UIButton!
  @IBOutlet weak var answerButton1: UIButton!
  @IBOutlet weak var answerButton2: UIButton!
  @IBOutlet weak var answerButton3: UIButton!
  
  private var questions = [TriviaQuestion]()
  private var currQuestionIndex = 0
  private var numCorrectQuestions = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addGradient()
    questionContainerView.layer.cornerRadius = 8.0
    // TODO: FETCH TRIVIA QUESTIONS HERE
    apiRequest()
  }
  
  private func updateQuestion(withQuestionIndex questionIndex: Int) {
    currentQuestionNumberLabel.text = "Question: \(questionIndex + 1)/\(questions.count)"
    let question = questions[questionIndex]
    questionLabel.text = question.question
    categoryLabel.text = question.category
    let answers = ([question.correctAnswer] + question.incorrectAnswers).shuffled()
    if answers.count > 0 {
      answerButton0.setTitle(answers[0], for: .normal)
    }
    if answers.count > 1 {
      answerButton1.setTitle(answers[1], for: .normal)
      answerButton1.isHidden = false
    }
    if answers.count > 2 {
      answerButton2.setTitle(answers[2], for: .normal)
      answerButton2.isHidden = false
    }
      if answers.count > 3 {
        answerButton3.setTitle(answers[3], for: .normal)
        answerButton3.isHidden = false
      }
    if answers.count == 2 {
        answerButton2.isHidden = true
      answerButton3.isHidden = true
    }
  }
  
  private func updateToNextQuestion(answer: String) {
    if isCorrectAnswer(answer) {
      numCorrectQuestions += 1
    }
    currQuestionIndex += 1
    guard currQuestionIndex < questions.count else {
      showFinalScore()
      return
    }
    updateQuestion(withQuestionIndex: currQuestionIndex)
  }
  
  private func isCorrectAnswer(_ answer: String) -> Bool {
    return answer == questions[currQuestionIndex].correctAnswer
  }
  
  private func showFinalScore() {
    let alertController = UIAlertController(title: "Game over!",
                                            message: "Final score: \(numCorrectQuestions)/\(questions.count)",
                                            preferredStyle: .alert)
    let resetAction = UIAlertAction(title: "Restart", style: .default) { [unowned self] _ in
      currQuestionIndex = 0
      numCorrectQuestions = 0
        questions.removeAll()
        apiRequest()
      //updateQuestion(withQuestionIndex: currQuestionIndex)
    }
    alertController.addAction(resetAction)
    present(alertController, animated: true, completion: nil)
  }
  
  private func addGradient() {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = view.bounds
    gradientLayer.colors = [UIColor(red: 0.54, green: 0.88, blue: 0.99, alpha: 1.00).cgColor,
                            UIColor(red: 0.51, green: 0.81, blue: 0.97, alpha: 1.00).cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
    gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    view.layer.insertSublayer(gradientLayer, at: 0)
  }
  
  @IBAction func didTapAnswerButton0(_ sender: UIButton) {
    updateToNextQuestion(answer: sender.titleLabel?.text ?? "")
  }
  
  @IBAction func didTapAnswerButton1(_ sender: UIButton) {
    updateToNextQuestion(answer: sender.titleLabel?.text ?? "")
  }
  
  @IBAction func didTapAnswerButton2(_ sender: UIButton) {
    updateToNextQuestion(answer: sender.titleLabel?.text ?? "")
  }
  
  @IBAction func didTapAnswerButton3(_ sender: UIButton) {
    updateToNextQuestion(answer: sender.titleLabel?.text ?? "")
  }
    
    
    
    
    
    
    private func apiRequest(completion: ((TriviaQuestion) -> Void)? = nil) {
        let url = URL(string: "https://opentdb.com/api.php?amount=10")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                assertionFailure("Error: \(error!.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                assertionFailure("Invalid response")
                return
            }
            guard let data = data, httpResponse.statusCode == 200 else {
                assertionFailure("Invalid response status code: \(httpResponse.statusCode)")
                return
            }
            self.parse(data: data)
        }
        task.resume()
    }
    
    private func parse(data: Data) {
        let jsonDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        let results = jsonDictionary["results"] as! [Any]
        for i in results {
            if let item = i as? [String: Any] {
                let unStrippedCategory = item["category"] as! String
                let unStrippedQuestion = item["question"] as! String
                let unStrippedCorrectAnswer = item["correct_answer"] as! String
                let unStrippedIncorrectAnswers = item["incorrect_answers"] as! [String]
                
                let category = cleanQuestion(unStrippedCategory)
                var incorrectAnswers: [String] = []
                let question = cleanQuestion(unStrippedQuestion)
                let correctAnswer = cleanQuestion(unStrippedCorrectAnswer)
                
                for j in unStrippedIncorrectAnswers {
                    let incorrectAnswer = cleanQuestion(j)
                    incorrectAnswers.append(incorrectAnswer)
                }
                
                let struc = TriviaQuestion(category: category,
                                           question: question,
                                           correctAnswer: correctAnswer,
                                           incorrectAnswers: incorrectAnswers)
                questions.append(struc)
            }
        }
        DispatchQueue.main.async {
            self.updateQuestion(withQuestionIndex: 0)
        }
        //updateQuestion(withQuestionIndex: 0)
    }
    
    private func cleanQuestion(_ raw: String) -> String {
        return raw.decodedHTMLEntities
    }
    
}


extension String {
    var decodedHTMLEntities: String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        } else {
            return self
        }
    }
}
