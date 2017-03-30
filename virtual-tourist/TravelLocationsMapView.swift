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
    
    var pins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let holdTouch = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        holdTouch.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(holdTouch)
        fetchPinLocations()
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
            pinView!.canShowCallout = true
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
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "PhotoAlbumView", sender: view)
        }

    }
    
//    func removePin(gesture: UIGestureRecognizer) {
//        
//        if gesture.state == UIGestureRecognizerState.ended {
//            
//            CoreDataStack.getContext().delete(selectedPin)
//            print("Annotation Removed")
//        }
//    }

    private func presentPhotoAlbumView() {
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoAlbumView")
        self.present(controller, animated: true, completion: nil)
    }
    


}
