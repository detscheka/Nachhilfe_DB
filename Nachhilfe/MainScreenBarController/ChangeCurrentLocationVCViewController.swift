//
//  ChangeCurrentLocationVCViewController.swift
//  Nachhilfe
//
//  Created by Tschekalinskij, Alexander on 24.03.18.
//  Copyright © 2018 Tschekalinskij, Alexander. All rights reserved.
//

import UIKit
import MapKit

protocol chnageLocationDelegate
{
    func didSendLocationData(Lat: Double, Long: Double)
}

class ChangeCurrentLocationVCViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    
    var delegate : chnageLocationDelegate?
    var longPressRecognizer = UILongPressGestureRecognizer()
    var annotation = MKPointAnnotation()
    var lat : Double = 0.0
    var long : Double = 0.0
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Change current location"
        prepareLocationManager()
        createMapView()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("User updated coordinates: ")
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        convertCoordinateToTown(latitude: locValue.latitude, longitude: locValue.longitude)
    }
    
    func prepareLocationManager()
    {
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        locationManager.stopUpdatingLocation()
    }
    
    func createMapView()
    {
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ChangeCurrentLocationVCViewController.longPressed(_:)))
        self.mapView.addGestureRecognizer(longPressRecognizer)

        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        
        mapView.center = view.center
        
        // Change icon to gps get current location
        let image = UIImage(named: "location") as UIImage?
        let button   = UIButton(type: UIButtonType.custom) as UIButton
        button.frame = CGRect(origin: CGPoint(x:5, y: 25), size: CGSize(width: 35, height: 35))
        button.setImage(image, for: .normal)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(ChangeCurrentLocationVCViewController.centerMapOnUserButtonClicked), for:.touchUpInside)
        button.backgroundColor = UIColor.lightGray
        mapView.addSubview(button)
    }
    
    @objc func centerMapOnUserButtonClicked() {
        let myGroup = DispatchGroup()
        myGroup.enter()
        
        DispatchQueue.main.async {
            self.mapView.setUserTrackingMode(MKUserTrackingMode.follow, animated: true)
        }
        myGroup.leave()
        
        myGroup.notify(queue: .main) {
            let lat = self.mapView.centerCoordinate.latitude
            let long = self.mapView.centerCoordinate.longitude
            self.convertCoordinateToTown(latitude: lat, longitude: long)
        }
    }
    
    func convertCoordinateToTown(latitude: Double, longitude: Double)
    {
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        var postalCode : String!
        var city : String!
        
        self.lat = latitude
        self.long = longitude
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]
            
            city = placeMark.addressDictionary!["City"] as! String
            postalCode = placeMark.addressDictionary!["ZIP"] as! String
            
            let title = "\(postalCode!), \(city!)"
        })
    }
    
    @objc func longPressed(_ sender: UILongPressGestureRecognizer)
    {
        if sender.state == .ended {
            print("Long press detected - do nothing")
        } else if sender.state == .began {
            print("Long press Ended - get new location")
            mapView.removeAnnotation(annotation)
            let touchPoint = longPressRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            annotation.coordinate = newCoordinates
            mapView.addAnnotation(annotation)
            
            self.lat = newCoordinates.latitude
            self.long = newCoordinates.longitude
            
            convertCoordinateToTown(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
        }
    }
    
    @IBAction func DoneButtonPressed(_ sender: Any) {
        print("Done Button was pressed by user!")
        
        if delegate != nil {
            delegate?.didSendLocationData(Lat: self.lat, Long: self.long)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }


}
