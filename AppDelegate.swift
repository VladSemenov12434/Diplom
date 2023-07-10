//
//  AppDelegate.swift
//  123
//
//  Created by MacBook Pro on 22/06/2023.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

import UIKit

protocol AnswerDelegate: class {
func addAnswer(_ answer: String) -> Void
}

class AnswersListviewController: UIViewController {

@IBOutlet weak var tableView: UITableView!
@IBOutlet weak var questionLabel: UILabel!

var answers = [Answer]()
let loader = ItemLoaderService<Answer>()
let builder = EntityBuilder()

var currentQuestion: Question?
var position: Int!
var id: String!
var isAppend: Bool!

override func viewDidLoad() {
super.viewDidLoad()

    self.tableView.delegate = self; self.tableView.dataSource = self
//self.tableView.allowsSelection = false
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated); answers = [Answer]()
guard Connectivity.isConnectedToInternet() else {
self.displayAlert(title: "Error.", message: "Can't load questions. Check your internet connection.")
return
}

if let question = currentQuestion { loader.loadItems(folderName: "answers") { result in
for item in result! {
if item.questionId! == self.currentQuestion?.id! {
self.answers.append(item)
}
}

if (self.answers.count > 0) {
self.tableView.reloadData()
}
}
}

self.title = "Answers"
self.questionLabel?.text = currentQuestion?.text!
}

override func viewDidDisappear(_ animated: Bool) {
super.viewDidDisappear(animated)
}

    @IBAction func answerButton_Clicked(_ sender: Any) { self.id = currentQuestion!.id! + "\(answers.count)"; self.isAppend = true
performSegue(withIdentifier: "segueToModal", sender: nil)
}

override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
let vc = segue.destination as! AnswerScreenViewController

vc.answerDelegate = self
vc.answerText = isAppend ? nil : answers[position].text!
}
}

extension AnswersListviewController: AnswerDelegate {
func addAnswer(_ answer: String) {
//let id = currentQuestion!.id! + "\(answers.count)"
let answer = Answer(id: id, text: answer, questionId: self.currentQuestion!.id!, accepted: false)
//answers.append(answer)
//tableView.reloadData()

let newValue = ["id": id, "text": answer.text!, "questionId": answer.questionId!, "accepted": false] as [String : Any]

builder.build(folder: "answers", value: newValue, id: id)
}
}

extension AnswersListviewController: UITableViewDelegate, UITableViewDataSource {
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
return answers.count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "AnswerCell") as! AnswerCell; cell.answer = answers[indexPath.row]
    cell.answerLabel.text = answers[indexPath.row].text ?? ""; cell.acceptImage.image = UIImage(named: "accept"); cell.acceptImage.isHidden = !answers[indexPath.row].accepted!; cell.AcceptButton.isHidden = !UserDefaults.standard.getUser()!.isTeacher!; cell.likeImage.image = UIImage(named:"like"); cell.viewForStudent.isHidden = true
cell.liked = false

return cell
}

func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
{
let update = UITableViewRowAction(style: .normal, title: "Edit") { action, index in self.position = index.row
    self.id = self.answers[self.position].id!; self.isAppend = false
self.performSegue(withIdentifier: "segueToModal", sender: nil)
}
return [update]
}

func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
return UserDefaults.standard.getUser()!.isTeacher ?? false
}
}

import Foundation
import FirebaseDatabase

protocol Firebaseable {
init?(snapshot: DataSnapshot)
}

class ItemLoaderService<T> where T: Firebaseable {
//пoсилaня нa бaзу дaних
var ref = Database.database().reference()

func loadItems(folderName: String, complition: @escaping ([T]?) -> Void){
//групa кoристувaчa
let group = UserDefaults.standard.getUser()?.group ?? "ti-51"
//зaвaнтaження дaнних з FireBaseDatabase
self.ref.child("groups").child(group).child(folderName).observeSingleEvent(of: .value, with: { snapshot in
//мaсив результaтiв
var result = [T]()

for child in snapshot.children {
if let snapshot = child as? DataSnapshot,
//кoнвертaцiя в oб'єкти
let item = T.init(snapshot: snapshot) { result.append(item)
}
}
complition(result) //виклик функцiї зaвершення
}) { error in
complition(nil) //виклик функцiї зaверення
}
}
}

class EntityBuilder {
var ref = Database.database().reference()

func build(folder: String, value: [String: Any], id: String) {
let group = UserDefaults.standard.getUser()!.group!
self.ref.child("groups").child(group).child(folder).child(id).setValue(value)
}
}
import UIKit

class LectureListViewController: UIViewController, LectureListViewProtocol, ViperModuleTransitionHandler {
    @IBOutlet weak var tableView: UITableView!
    
    let configurator: LectureListConfiguratorProtocol = LectureListConfigurator()
    
    var presenter: LectureListPresenterProtocol!
    
    var subject: Subject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        configurator.configure(with: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated); self.title = subject?.name
        presenter.setUpViewWithData(subject)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        presenter.setUpViewWithData(nil)
    }
    
    func reloadData() { tableView.reloadData()
    }
}
