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
        
        password.textType = .default
        password.secure = true
        password.returnType = .go
        password.placeholder = "Password"
        password.delegate = self

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FIRAuth.auth()!.currentUser != nil && FIRAuth.auth()!.currentUser!.isEmailVerified {
            dismiss(animated: true, completion: nil)
        }
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
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage(error!.localizedDescription, messageType: .error)
            } else {
                user?.sendEmailVerification(completion: { verifyError in
                    self.showMessage("You must confirm your registration. Check your mail box.", messageType: .information)
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
                Model.shared.fetchUser(user!.uid, result: { fetchError, profile in
                    if fetchError == nil {
                        let newUser = Model.shared.createUser(user!.uid, email: self.userID.text())
                        if let nickName = profile!["nickName"] as? String {
                            newUser.nickName = nickName
                        }
                        if let imageURL = profile!["image"] as? String {
                            let ref = Model.shared.storageRef.child(imageURL)
                            ref.data(withMaxSize: INT64_MAX, completion: { data, error in
                                SVProgressHUD.dismiss()
                                newUser.image = data as NSData?
                                self.dismiss(animated: true, completion: nil)
                            })
                        } else {
                            SVProgressHUD.dismiss()
                            self.dismiss(animated: true, completion: nil)
                        }
                        Model.shared.saveContext()
                    } else {
                        SVProgressHUD.dismiss()
                        self.showMessage(fetchError!.localizedDescription, messageType: .error)
                    }
                })
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
