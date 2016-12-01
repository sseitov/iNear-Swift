//
//  ContactsController.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import Firebase

class ContactsController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle("Contacts")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if FIRAuth.auth()?.currentUser == nil {
            performSegue(withIdentifier: "Login", sender: self)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath)
        return cell
    }
    
    @IBAction func addContact(_ sender: Any) {
        let alert = EmailInput.getEmail(cancelHandler: {
        }, acceptHandler: { email in
        })
        alert?.showInView(self.view)
    }

    // MARK: - Navigation
/*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Login" {
            let nav = segue.destination as! UINavigationController
            if let controller = nav.topViewController as? LoginController {
                controller.delegate = self
            }
        }
    }
 */
}
