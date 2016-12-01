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

class ProfileController: UIViewController, TextFieldContainerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var nickName: TextFieldContainer!
    @IBOutlet weak var updateButton: UIButton!
    
    var owner:User?
    var avatar:NSData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle("My Account")
        setupBackButton()
        
        logo.layer.masksToBounds = true
        logo.clipsToBounds = false
        logo.layer.cornerRadius = logo.frame.width / 2.0        
        logo.layer.shadowColor = UIColor.black.cgColor
        logo.layer.shadowOffset = CGSize(width: 5, height: 5)
        logo.layer.shadowOpacity = 0.3
        
        nickName.textType = .default
        nickName.returnType = .done
        nickName.autocapitalizationType = .words
        nickName.placeholder = "Nick Name"
        nickName.delegate = self

        updateButton.setupBorder(UIColor.white, radius: 20)
        
        owner = Model.shared.getUser(FIRAuth.auth()!.currentUser!.uid)
        if owner != nil {
            email.text = owner!.email
            if owner!.nickName != nil {
                nickName.setText(owner!.nickName!)
            }
            if owner!.imageData != nil {
                avatar = owner!.imageData
                logo.image = UIImage(data: avatar as! Data)
            }
        }
    }
    
    func textChange(_ sender:TextFieldContainer, text:String?) -> Bool {
        return true
    }
    
    func textDone(_ sender:TextFieldContainer, text:String?) {
        sender.activate(false)
    }
    
    @IBAction func touchDown(_ sender: Any) {
        self.logo.layer.shadowOffset = CGSize()
        self.logo.layer.shadowColor = UIColor.clear.cgColor
    }
    
    @IBAction func touchUp(_ sender: UIButton) {
        self.logo.layer.shadowOffset = CGSize(width: 5, height: 5)
        self.logo.layer.shadowColor = UIColor.black.cgColor
        updatePhoto(sender)
    }

    @IBAction func doSignOut(_ sender: Any) {
        do {
            try FIRAuth.auth()?.signOut()
            UserDefaults.standard.set(nil, forKey: "currentUser")
            _ = navigationController?.popViewController(animated: true)
        } catch {
            showMessage((error as NSError?)!.localizedDescription, messageType: .error)
        }
    }

    fileprivate func updatePhoto(_ sender:UIButton) {
        let removeCover:CompletionBlock? = avatar != nil ? {
            self.avatar = nil
            Model.shared.saveContext()
            self.logo.image = UIImage(named:"logo")
        } : nil
        var actions = ["From Camera Roll", "Use Camera"]
        if avatar != nil {
            actions.append("Remove Cover")
        }
        let actionView = ActionSheet.create(
            title: "Select Cover",
            actions: actions,
            handler1: {
                let imagePicker = UIImagePickerController()
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                imagePicker.modalPresentationStyle = .formSheet
                if let font = UIFont(name: "HelveticaNeue-CondensedBold", size: 15) {
                    imagePicker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.mainColor(), NSFontAttributeName : font]
                }
                imagePicker.navigationBar.tintColor = UIColor.mainColor()
                self.present(imagePicker, animated: true, completion: nil)
        }, handler2: {
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .camera
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }, handler3: removeCover)
        if(IS_PAD()) {
            actionView?.showInPopover(host: self, target: sender)
        } else {
            actionView?.show()
        }
    }
    
    // MARK: - UIImagePickerController delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: {
            if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.avatar = UIImageJPEGRepresentation(pickedImage, 0.5) as NSData?
                self.logo.image = UIImage(data: self.avatar as! Data)
                Model.shared.saveContext()
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func updateProfile(_ sender: Any) {
        if owner != nil {
            SVProgressHUD.show(withStatus: "Update...")
            owner?.nickName = nickName.text().isEmpty ? nil : nickName.text()
            owner?.imageData = avatar
            Model.shared.updateUser(owner!, success: { success in
                SVProgressHUD.dismiss()
                if !success {
                    self.showMessage("Error update profile data.", messageType: .error)
                } else {
                    Model.shared.saveContext()
                    self.goBack()
                }
            })
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
