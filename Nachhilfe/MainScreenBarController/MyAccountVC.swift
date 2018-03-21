//
//  MyAccountVC.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 15.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import Firebase

class MyAccountVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var currentUser: String!
    
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var nameLabelTop: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLayout()
        print(currentUser)
        loadProfilePicture()
        applyTags()
        readUserInfo()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func readUserInfo()
    {
        let ref = Database.database().reference(fromURL: "https://nachhilfe-d92d2.firebaseio.com/")
        let usersReference = ref.child("users").child(currentUser)
        
        usersReference.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let username = value?["name"] as? String ?? ""
            self.nameLabelTop.text = username
        })
    }
    
    func applyTags()
    {
        imageButton.tag = 1
    }
    
    func configureLayout()
    {
        // Separator
        self.separatorView.frame = CGRect(x: 0, y: self.imageButton.frame.midY + 200, width: self.imageButton.frame.midX * 3, height: 1)


        
    }
    
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        switch (sender.tag)
        {
        case 1:
            print("Button pressed: choose image")
            chooseImage()
            
        default:
            print("No corresponding button tag found!")
            return
        }
    }
    
    func chooseImage()
    {
        let actionSheet = UIAlertController(title: "Photo Source", message: "Choose a source", preferredStyle: .actionSheet)
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {(action: UIAlertAction) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                imagePicker.sourceType = .camera
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                print("Camera not available")
            }
        } ))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {(action: UIAlertAction) in imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
        }  ))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        imageButton.setBackgroundImage(image, for: .normal)
        
        picker.dismiss(animated: true, completion: nil)
        
        updatePhotoAfterPicking()
    }
    
    func updatePhotoAfterPicking()
    {
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: "gs://nachhilfe-d92d2.appspot.com")
        let profilePicRef = storageRef.child(currentUser+"/profile_pic.jpg")
        
        var img = imageButton.backgroundImage(for: .normal)
        
        img = resizeImage(image: img!, targetSize: CGSize(width: 600.0, height: 600.0))
        
        if img != nil {
            let imgData = UIImagePNGRepresentation(img!) as! NSData
            _ = profilePicRef.putData(imgData as Data, metadata: nil) {
                metadata, error in
                
                if (error == nil)
                {
                    _ = metadata!.downloadURL
                }
                else
                {
                    print("Error in downloading image")
                    print(error!)
                }
            }
        }
        print("Uploaded image to Firebase after picking!")
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func loadProfilePicture()
    {
        let storage = Storage.storage()
        let storageRef = storage.reference(forURL: "gs://nachhilfe-d92d2.appspot.com")
        let profilePicRef = storageRef.child(currentUser+"/profile_pic.jpg")

        var userImg : UIImage? = nil
        var imageFB : UIImage? = nil
        
        let myGroup = DispatchGroup()
        myGroup.enter()
        profilePicRef.getData(maxSize: 1 * 1024 * 1024, completion: { (data, error) in
            if (error == nil) {
                DispatchQueue.main.async {
                    imageFB = UIImage(data: data!)
                }
            } else {
                print("There is no image to download yet. Using the standard ghost picture.")
                print(error!)
            }
            myGroup.leave()
        })
        
        myGroup.notify(queue: .main) {
            userImg = imageFB
            if userImg == nil {
                /* If there is no profile pic available */
                userImg = UIImage(named: "not_profile_pic")
            }
            
            self.imageButton.frame = CGRect(x: self.view.center.x/2 - self.imageButton.frame.width/2, y: 100, width: 160, height: 160)
            self.imageButton.layer.cornerRadius = 0.5 * self.imageButton.bounds.size.width
            self.imageButton.layer.borderColor = UIColor.lightGray.cgColor
            self.imageButton.layer.borderWidth = 1.0
            self.imageButton.clipsToBounds = true
            self.imageButton.setBackgroundImage(userImg, for: .normal)
            self.imageButton.center = CGPoint(x: self.view.frame.width / 2, y: 150)
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}


extension UIImage {
    var circle: UIImage {
        let square = size.width < size.height ? CGSize(width: size.width, height: size.width) : CGSize(width: size.height, height: size.height)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}
