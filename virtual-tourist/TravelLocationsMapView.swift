//
//  TravelLocationsMapView.swift
//  virtual-tourist
//
//  Created by Ha Na Gill on 3/22/17.
//  Copyright © 2017 Ha Na Gill. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapView: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    @IBOutlet weak var editModeLabel: UILabel!
    var pins = [Pin]()
    var isEditMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        editModeLabel.isHidden = true
        let longPressed = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        longPressed.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressed)
        fetchPinLocations()
    }
    
    @IBAction func editMode(_ sender: Any) {
        isEditMode = !isEditMode
        
        if isEditMode {
            editButton.title = "Done"
            mapView.frame.origin.y -= 40
            editModeLabel.isHidden = false
        }else {
            editButton.title = "Edit"
            mapView.frame.origin.y = 0
            editModeLabel.isHidden = true
        }
    }
    
    
    func dropPin(gestureRecognizer:UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == UIGestureRecognizerState.ended {
            let location = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(location, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            print("**annotation**")
            print(annotation.coordinate)
            savePinLocations(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)
            performUIUpdatesOnMain {
                self.fetchPinLocations()
            }
        }
    }
    
    func savePinLocations(lat:Double,lon:Double){
        let context = CoreDataStack.persistentContainer.viewContext
        let pin:Pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: context ) as! Pin
        pin.latitude = lat
        pin.longitude = lon
        CoreDataStack.saveContext()
        
        self.pins.append(pin)
        print(pins)
    }
    
    func fetchPinLocations(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            print("number of results: \(searchResults.count)")
            var annotations = [MKPointAnnotation]()
            for result in searchResults as [Pin]{
                let lat = CLLocationDegrees(result.latitude)
                let long = CLLocationDegrees(result.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
                
            }
            self.mapView.addAnnotations(annotations)
            print("fetched pins to the map view.")
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Pin Tapped")
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        if isEditMode {
            let lat = view.annotation?.coordinate.latitude
            let lon = view.annotation?.coordinate.longitude
            print("selected pin lat:\(lat) lon:\(lon)")
            //Q: How to delete the pin?
            // pins array is empty.
            for pin in pins {
                if pin.latitude == lat!, pin.longitude == lon! {
                    print("found pin info")
                }
            }
        } else {
        print("segue to the photo album")
        //Q: PerformSeque to the photoAlbumView
        //performSegue(withIdentifier: "PhotoAlbumView", sender: self)
            
        }
    }
    
    func removePin(gesture: UIGestureRecognizer) {
        
        if gesture.state == UIGestureRecognizerState.ended {
            
            //CoreDataStack.getContext().delete(selectedPin)
            print("Pin Removed")
        }
    }
    
    
//    private func presentPhotoAlbumView() {
//        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoAlbumView")
//        self.present(controller, animated: true, completion: nil)
//    }
    


}
