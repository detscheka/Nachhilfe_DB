//
//  MyAccountVC.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 15.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapKit

class MyAccountVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate, chnageLocationDelegate {
    
    var currentUser: String!
    let locationManager = CLLocationManager()
    var mapView = MKMapView()
    var annotation = MKPointAnnotation()
    var ref = DatabaseReference()
    var usersReference = DatabaseReference()
    
    @IBOutlet weak var ratingStackView: UIStackView!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var nameLabelTop: UILabel!
    @IBOutlet weak var userLocationButton: UIButton!
    @IBOutlet weak var separatorView2: UIView!

    @IBOutlet weak var tableViewContainerView: UIView!
    @IBOutlet weak var ratingStar1: UIImageView!
    @IBOutlet weak var ratingStar2: UIImageView!
    @IBOutlet weak var ratingStar3: UIImageView!
    @IBOutlet weak var ratingStar4: UIImageView!
    @IBOutlet weak var ratingStar5: UIImageView!
    @IBOutlet weak var ratingsButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLayout()
        prepareLocationManager()
        prepareFirebase()
        loadRatings()
        
        print(currentUser)
        loadProfilePicture()
        applyTags()
        readUserInfo()
        
    }
    
    func loadRatings()
    {
        ratingStar1.alpha = 0.3
        ratingStar2.alpha = 0.3
        ratingStar3.alpha = 0.3
        ratingStar4.alpha = 0.3
        ratingStar5.alpha = 0.3
        
        var rating : Double = 0.0
        var noRatings : Int = 0
        
        usersReference.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            var str = value?["NoRatings"] as? [String]
            
            if str != nil {
                noRatings = Int((str![0]))!
                let label = "\(noRatings) ratings available"
                self.ratingsButton.setTitle(label, for: .normal)
            } else {
                let label = "0 ratings available"
                self.ratingsButton.setTitle(label, for: .normal)
            }
            
                str = value?["Rating"] as? [String]
            if str != nil {
                rating = Double((str![0]))!
                
                if rating >= 1.0
                {
                    self.ratingStar1.alpha = 1.0
                }
                
                if rating >= 2.0
                {
                    self.ratingStar2.alpha = 1.0
                }
                
                if rating >= 3.0
                {
                    self.ratingStar3.alpha = 1.0
                }
                
                if rating >= 4.0
                {
                    self.ratingStar4.alpha = 1.0
                }
                
                if rating >= 5.0
                {
                    self.ratingStar5.alpha = 1.0
                }
            }
        })
    }
    
    func updateFirebaseUserCoordinates(Lat: Double, Long: Double)
    {
        let values = ["Lat": Lat, "Long": Long]
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err!)
                return
            }
            print("User coordinates were updated!")
        })
    }
    
    func didSendLocationData(Lat: Double, Long: Double) {
        print("Data received from changeLocationVC")
        convertCoordinateToTown(latitude: Lat, longitude: Long)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showChangeUserLocationSeg"
        {
            let dest = segue.destination as! UINavigationController
            let vc = dest.topViewController as! ChangeCurrentLocationVCViewController
            //let vc : ChangeCurrentLocationVCViewController = segue.destination as! ChangeCurrentLocationVCViewController
            vc.delegate = self
        }
    }
    
    func prepareLocationManager()
    {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        locationManager.stopUpdatingLocation()
    }
    
    func prepareFirebase()
    {
        ref = Database.database().reference(fromURL: "https://nachhilfe-d92d2.firebaseio.com/")
        usersReference = ref.child("users").child(self.currentUser)
    }
    
    func convertCoordinateToTown(latitude: Double, longitude: Double)
    {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        var postalCode : String!
        var city : String!
        
        updateFirebaseUserCoordinates(Lat: latitude, Long: longitude)
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            city = placeMark.addressDictionary!["City"] as! String
            postalCode = placeMark.addressDictionary!["ZIP"] as! String
            
            let title = "\(postalCode!), \(city!)"
            self.userLocationButton.setTitle(title, for: .normal)
            let buttonImg = UIImage(named: "woman")
            print("Coordinates changed to: \(title)")
            
            // Find GPS Icon for further usage
            self.userLocationButton.setImage(buttonImg, for: .normal)
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("User updated coordinates: ")
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        convertCoordinateToTown(latitude: locValue.latitude, longitude: locValue.longitude)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func readUserInfo()
    {
        usersReference.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let username = value?["name"] as? String ?? ""
            self.nameLabelTop.text = username
        })
    }
    
    func applyTags()
    {
        imageButton.tag = 1
        userLocationButton.tag = 2
    }
    
    func configureLayout()
    {
        // Separator
        self.separatorView.frame = CGRect(x: 0, y: self.imageButton.frame.midY + 200, width: self.imageButton.frame.midX * 3, height: 1)

        self.userLocationButton.frame = CGRect(x: self.mainView.frame.midX - self.userLocationButton.frame.width, y: self.imageButton.frame.midY + 130, width: 300, height: 60)
        
        self.ratingStackView.frame = CGRect(x: self.mainView.frame.midX - self.ratingStackView.frame.width/2 + 18, y: self.separatorView.frame.midY + 50, width: self.mainView.frame.width - 50, height: 35)
        self.ratingStackView.isHidden = false
        
        self.ratingsButton.frame = CGRect(x: self.mainView.frame.midX - self.ratingsButton.frame.width, y: self.ratingStackView.frame.midY - 80, width: 300, height: 60)
        
        self.separatorView2.frame = CGRect(x: 0, y: self.ratingStackView.frame.midY + 60, width: self.imageButton.frame.midX * 3, height: 1)
        
        self.tableViewContainerView.center = CGPoint.init(x: self.tableViewContainerView.frame.width/2, y: self.separatorView2.frame.minY + self.tableViewContainerView.frame.height/2 + 10)
    }
    
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        switch (sender.tag)
        {
        case 1:
            print("Button pressed: choose image")
            chooseImage()
            
        case 2:
            print("Button pressed: change location")
            
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
