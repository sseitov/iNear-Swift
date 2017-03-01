//
//  ProfileController.swift
//  iNear
//
//  Created by Сергей Сейтов on 21.11.16.
//  Copyright © 2016 Сергей Сейтов. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import SDWebImage

class ProfileController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate, TextFieldContainerDelegate {
    
    @IBOutlet weak var photoView: UIImageView!
    
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var socialType: UILabel!
    
    @IBOutlet weak var authView: UIView!
    @IBOutlet weak var usrField: TextFieldContainer!
    @IBOutlet weak var pwdField: TextFieldContainer!
    
    var owner:User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoView.setupCircle()
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self

        owner = currentUser()
        
        usrField.textType = .emailAddress
        usrField.placeholder = "email address"
        usrField.returnType = .next
        usrField.delegate = self
        
        pwdField.placeholder = "password"
        pwdField.returnType = .go
        pwdField.secure = true
        pwdField.delegate = self
        
        if owner != nil {
            setupBackButton()
            authView.alpha = 0
            userView.alpha = 1
            setupTitle("My Account")
            userEmail.text = owner!.email
            userName.text = owner!.name
            switch owner!.socialType {
            case .facebook:
                socialType.text = "Login over Facebook"
            case .google:
                socialType.text = "Signed over Google+"
            default:
                socialType.text = ""
            }
            photoView.image = owner!.getImage()
        } else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.hidesBackButton = true
            authView.alpha = 1
            userView.alpha = 0
            setupTitle("Authentication")
        }
    }
    
    func textDone(_ sender:TextFieldContainer, text:String?) {
        if sender == usrField {
            if usrField.text().isEmail() {
                pwdField.activate(true)
            } else {
                showMessage("Email should have xxxx@domain.prefix format.", messageType: .error, messageHandler: {
                    self.usrField.activate(true)
                })
            }
        } else {
            if pwdField.text().isEmpty {
                showMessage("Password field required.", messageType: .error, messageHandler: {
                    self.pwdField.activate(true)
                })
            } else if usrField.text().isEmpty {
                usrField.activate(true)
            } else {
                emailAuth(user: usrField.text(), password: pwdField.text())
            }
        }
    }
    
    func textChange(_ sender:TextFieldContainer, text:String?) -> Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if owner != nil {
            if LocationManager.shared.myTrack() != nil {
                let btn = UIBarButtonItem(title: "Track", style: .plain, target: self, action: #selector(ProfileController.showTrack))
                btn.tintColor = UIColor.white
                navigationItem.setRightBarButton(btn, animated: true)
            } else {
                navigationItem.setRightBarButton(nil, animated: true)
            }
        } else {
            navigationItem.setRightBarButton(nil, animated: true)
        }
    }
    
    func showTrack() {
        performSegue(withIdentifier: "showTrack", sender: nil)
    }
    
    override func goBack() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signOut(_ sender: Any) {
        Model.shared.signOut()
        UIView.animate(withDuration: 0.3, animations: {
            self.userView.alpha = 0
        }, completion: { _ in
            self.setupTitle("Authentication")
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.hidesBackButton = true
            UIView.animate(withDuration: 0.3, animations: {
                self.authView.alpha = 1
            })
        })
    }
    
    // MARK: - Email Auth
    
    func emailSignUp(user:String, password:String) {
        SVProgressHUD.show(withStatus: "SignUp...")
        FIRAuth.auth()?.createUser(withEmail: user, password: password, completion: { firUser, error in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showMessage((error as! NSError).localizedDescription, messageType: .error)
            } else {
                Model.shared.setEmailUser(firUser!, email: user)
                self.goBack()
            }
        })
    }
    
    func emailAuth(user:String, password:String) {
        SVProgressHUD.show(withStatus: "Login...")
        FIRAuth.auth()?.signIn(withEmail: user, password: password, completion: { firUser, error in
            let err = error as? NSError
            if err != nil {
                SVProgressHUD.dismiss()
                if let reason = err!.userInfo["error_name"] as? String  {
                    if reason == "ERROR_USER_NOT_FOUND" {
                        let alert = self.createQuestion("User \(user) not found. Do you want to sign up?", acceptTitle: "SignUp", cancelTitle: "Cancel", acceptHandler: {
                            self.emailSignUp(user: user, password: password)
                        })
                        alert?.show()
                    } else {
                        self.showMessage(err!.localizedDescription, messageType: .error)
                    }
                } else {
                    self.showMessage(err!.localizedDescription, messageType: .error)
                }
            } else {
                SVProgressHUD.dismiss()
                Model.shared.setEmailUser(firUser!, email: user)
                self.goBack()
            }
        })
    }
    
    // MARK: - Google+ Auth
    
    @IBAction func facebookSignIn(_ sender: Any) { // read_custom_friendlists
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile","email"], from: self, handler: { result, error in
            if error != nil {
                self.showMessage("Facebook authorization error.", messageType: .error)
                return
            }
            
            SVProgressHUD.show(withStatus: "Login...") // interested_in
            let params = ["fields" : "name,email,first_name,last_name,birthday,picture.width(480).height(480)"]
            let request = FBSDKGraphRequest(graphPath: "me", parameters: params)
            request!.start(completionHandler: { _, result, fbError in
                if fbError != nil {
                    SVProgressHUD.dismiss()
                    self.showMessage(fbError!.localizedDescription, messageType: .error)
                } else {
                    let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                    FIRAuth.auth()?.signIn(with: credential, completion: { firUser, error in
                        if error != nil {
                            SVProgressHUD.dismiss()
                            self.showMessage((error as NSError?)!.localizedDescription, messageType: .error)
                        } else {
                            if let profile = result as? [String:Any] {
                                Model.shared.setFacebookUser(firUser!, profile: profile, completion: {
                                    SVProgressHUD.dismiss()
                                    self.goBack()
                                })
                            } else {
                                self.showMessage("Can not read user profile.", messageType: .error)
                                try? FIRAuth.auth()?.signOut()
                            }
                        }
                    })
                }
            })
        })
    }
    
    // MARK: - Google+ Auth
    
    @IBAction func googleSitnIn(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            showMessage(error.localizedDescription, messageType: .error)
            return
        }
        let authentication = user.authentication
        let credential = FIRGoogleAuthProvider.credential(withIDToken: (authentication?.idToken)!,
                                                          accessToken: (authentication?.accessToken)!)
        SVProgressHUD.show(withStatus: "Login...")
        FIRAuth.auth()?.signIn(with: credential, completion: { firUser, error in
            if error != nil {
                SVProgressHUD.dismiss()
                self.showMessage((error as NSError?)!.localizedDescription, messageType: .error)
            } else {
                Model.shared.setGoogleUser(firUser!, googleProfile: user.profile, completion: {
                    SVProgressHUD.dismiss()
                    self.goBack()
                })
            }
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        try? FIRAuth.auth()?.signOut()
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTrack" {
            let controller = segue.destination as! TrackController
            controller.user = currentUser()
        }
    }

}
