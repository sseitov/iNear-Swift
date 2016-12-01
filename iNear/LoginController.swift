//
//  LoginController.swift
//  iNear
//
//  Created by Сергей Сейтов on 15.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class LoginController: UIViewController, TextFieldContainerDelegate {

    @IBOutlet weak var userID: TextFieldContainer!
    @IBOutlet weak var password: TextFieldContainer!
    @IBOutlet weak var logo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle("Authorization")
        logo.setupCircle()
        
        userID.textType = .emailAddress
        userID.returnType = .next
        userID.placeholder = "Email"
        userID.delegate = self
        if let user = UserDefaults.standard.value(forKey: "currentUser") as? String {
            userID.setText(user)
        }
        
        password.textType = .default
        password.secure = true
        password.returnType = .go
        password.placeholder = "Password"
        password.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func textChange(_ sender:TextFieldContainer, text:String?) -> Bool {
        return true
    }
    
    func textDone(_ sender:TextFieldContainer, text:String?) {
        sender.activate(false)
        if sender == userID {
            password.activate(true)
        }
    }
    
    func checkFields() -> Bool {
        if userID.text().isEmpty {
            showMessage("Input email.", messageType: .error, messageHandler: {
                self.userID.activate(true)
            })
            return false
        } else if password.text().isEmpty {
            showMessage("Input password.", messageType: .error, messageHandler: {
                self.password.activate(true)
            })
            return false
        } else {
            return true
        }
    }
    
    @IBAction func signUp(_ sender: Any) {
        TextFieldContainer.deactivateAll()
        if !checkFields() {
            return
        }
        
        SVProgressHUD.show(withStatus: "SignUp...")
        FIRAuth.auth()?.createUser(withEmail: self.userID.text(), password: self.password.text()) { (user, error) in
            if error != nil {
                SVProgressHUD.dismiss()
                self.showMessage(error!.localizedDescription, messageType: .error)
            } else {
                Model.shared.setEmailUser(user!, email: self.userID.text(), result: { success in
                    if success {
                        UserDefaults.standard.set(self.userID.text(), forKey: "currentUser")
                        UserDefaults.standard.synchronize()
                        user?.sendEmailVerification(completion: { verifyError in
                            SVProgressHUD.dismiss()
                            if verifyError != nil {
                                self.showMessage(verifyError!.localizedDescription, messageType: .error)
                            } else {
                                self.showMessage("You must confirm your registration. Check your mail box.", messageType: .information)
                            }
                        })
                    } else {
                        SVProgressHUD.dismiss()
                        self.showMessage("Error setup user.", messageType: .error)
                    }
                })
            }
        }
    }
    
    @IBAction func signIn() {
        TextFieldContainer.deactivateAll()
        if !checkFields() {
            return
        }
        SVProgressHUD.show(withStatus: "SignIn...")
        FIRAuth.auth()?.signIn(withEmail: userID.text(), password: password.text()) { (user, error) in
            if error != nil {
                SVProgressHUD.dismiss()
                self.showMessage(error!.localizedDescription, messageType: .error)
            } else {
                if user!.isEmailVerified {
                    let cashedUser = Model.shared.createUser(user!.uid)
                    Model.shared.fetchUser(cashedUser, result: { success in
                        SVProgressHUD.dismiss()
                        if success {
                            UserDefaults.standard.set(self.userID.text(), forKey: "currentUser")
                            UserDefaults.standard.synchronize()
                            Model.shared.saveContext()
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.showMessage("Error get user profile.", messageType: .error)
                        }
                    })
                } else {
                    SVProgressHUD.dismiss()
                    self.showMessage("You must confirm your registration. Check your mail box.", messageType: .information)
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
