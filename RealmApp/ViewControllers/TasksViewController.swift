//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    private let storageManager = StorageManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.title
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        content.text = task.title
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    
    @objc private func addButtonPressed() {
        showAlert()
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var taskList: Results<Task>!
        
        if indexPath.section == 0 {
            taskList = currentTasks
        } else {
            taskList = completedTasks
        }
        
        let task = taskList[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, _ in
            storageManager.delete(task)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            showAlert(with: task) {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            
            isDone(true)
        }
        
        let doneActonTitle = task.isComplete ? "Undone" : "Done"
        let doneAction = UIContextualAction(style: .normal, title: doneActonTitle) { [unowned self] _, _, isDone in
            storageManager.done(task)
            
            let sourceIndexPath = indexPath
            
            let row = task.isComplete ? completedTasks.count - 1 : currentTasks.count - 1
            let section = task.isComplete ? 1 : 0
            let destinationIndexPath = IndexPath(row: row, section: section)
            
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
            
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
}

extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
           let alertBuilder = AlertControllerBuilder(
               title: task != nil ? "Edit Task" : "New Task",
               message: "What do you want to do?"
           )
           
           alertBuilder
               .setTextFields(title: task?.title, note: task?.note)
               .addAction(
                   title: task != nil ? "Update Task" : "Save Task",
                   style: .default
               ) { [weak self] taskTitle, taskNote in
                   if let task, let completion {
                       self?.storageManager.edit(task, newTitle: taskTitle, newNote: taskNote)
                       completion()
                       return
                   }
                   self?.save(task: taskTitle, withNote: taskNote)
               }
               .addAction(title: "Cancel", style: .destructive)
           
           let alertController = alertBuilder.build()
           present(alertController, animated: true)
       }
    
    private func save(task: String, withNote note: String) {
        storageManager.save(task, withNote: note, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
}
