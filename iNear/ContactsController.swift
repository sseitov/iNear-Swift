//
//  ContactsController.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class ContactsController: UITableViewController {
    
    var contacts:[User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle("Contacts")
        tableView.allowsSelectionDuringEditing = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if Model.shared.currentUser() == nil {
            performSegue(withIdentifier: "showProfile", sender: self)
        } else {
            Model.shared.startObservers()
            refresh()
            if IS_PAD() {
                if contacts.count > 0 {
                    let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
                    performSegue(withIdentifier: "showDetail", sender: cell)
                }
            }
        }
    }
    
    func refresh() {
        contacts = Model.shared.allUsers()
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath) as! ContactCell
        cell.user = contacts[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let user = contacts[indexPath.row]
            if let index = contacts.index(of: user) {
                tableView.beginUpdates()
                contacts.remove(at: index)
                Model.shared.deleteUser(user)
                tableView.deleteRows(at: [indexPath], with: .top)
                tableView.endUpdates()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = contacts[indexPath.row]
        SVProgressHUD.show(withStatus: "Refresh..")
        Model.shared.refreshUser(user, completion: {
            SVProgressHUD.dismiss()
            self.performSegue(withIdentifier: "showDetail", sender: user)
        })
    }
    
    @IBAction func addContact(_ sender: Any) {
        let alert = EmailInput.getEmail(cancelHandler: {
        }, acceptHandler: { email in
            SVProgressHUD.show(withStatus: "Search...")
            let ref = FIRDatabase.database().reference()
            ref.child("users").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: .value, with: { snapshot in
                if let values = snapshot.value as? [String:Any] {
                    for uid in values.keys {
                        if uid == Model.shared.currentUser()!.uid! {
                            continue
                        }
                        if let profile = values[uid] as? [String:Any] {
                            let user = Model.shared.createUser(uid)
                            user.setUserData(profile, completion:{
                                SVProgressHUD.dismiss()
                                self.refresh()
                            })
                            return
                        }
                    }
                    SVProgressHUD.dismiss()
                    self.showMessage("User not found.", messageType: .error)
                } else {
                    SVProgressHUD.dismiss()
                    self.showMessage("User not found.", messageType: .error)
                }
            })
        })
        alert?.show()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let nav = segue.destination as! UINavigationController
            if let controller = nav.topViewController as? ChatController {
                controller.user = sender as? User
            }
        }
    }
}
