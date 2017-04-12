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
    
    var isEditMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        editModeLabel.isHidden = true
        let longPressed = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gestureRecognizer:)))
        longPressed.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressed)
        loadAnnotations()
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
            print("new pin dropped. lat:\(annotation.coordinate.latitude), lat:\(annotation.coordinate.latitude)")
            savePinLocations(lat: annotation.coordinate.latitude, lon: annotation.coordinate.longitude)
            performUIUpdatesOnMain {
                self.loadAnnotations()
            }
        }
    }
    
    func savePinLocations(lat:Double,lon:Double){
        let context = CoreDataStack.getContext()
        let pin:Pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: context ) as! Pin
        pin.latitude = lat
        pin.longitude = lon
        CoreDataStack.saveContext()
    }
    
    func loadAnnotations(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            print("number of locations: \(searchResults.count)")
            var annotations = [MKPointAnnotation]()
            for result in searchResults as [Pin]{
                let lat = CLLocationDegrees(result.latitude)
                let long = CLLocationDegrees(result.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
                //pins.append(result)
            }
            performUIUpdatesOnMain {
                self.mapView.addAnnotations(annotations)
                print("annotations added to the map view.")
            }
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
        mapView.deselectAnnotation(view.annotation, animated: true)
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation?.coordinate.longitude
        print("selected pin's lat:\(lat), lon:\(lon)")
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            for pin in searchResults as [Pin] {
                if pin.latitude == lat!, pin.longitude == lon! {
                    let selectedPin = pin
                    print("Found pin info.")
                    if isEditMode {
                        //Delete selectedPin
                        performUIUpdatesOnMain {
                            //fetchRequest.predicate = NSPredicate(format: "longitude == %@", "Pins")
                            CoreDataStack.getContext().delete(selectedPin)
                            CoreDataStack.saveContext()
                            self.mapView.removeAnnotation(view.annotation!)
                            print("Deleted the selected pin.")
                        }
                    } else {
                        //Perform segue to the photo album
                        print("Perform segue to the photo album.")
                        performUIUpdatesOnMain {
                            self.performSegue(withIdentifier: "PhotoAlbumView", sender: selectedPin)
                        }
                    }
                }
            }
        }catch {
            print("Error: \(error)")
        }
        
    }
    
    func bboxString(longitude:Double, latitude:Double) -> String {
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoAlbumView" {
            let controller = segue.destination as! PhotoAlbumViewController
            let selectedPin = sender as! Pin
            controller.selectedPin = selectedPin
            controller.selectedPinLocation = bboxString(longitude:selectedPin.longitude , latitude: selectedPin.latitude)
        }
    }


}
