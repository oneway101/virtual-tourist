//
//  PhotoAlbumViewController.swift
//  virtual-tourist
//
//  Created by Ha Na Gill on 3/22/17.
//  Copyright © 2017 Ha Na Gill. All rights reserved.
//

import UIKit
import MapKit
import CoreData

private let reuseIdentifier = "Cell"

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var selectedPin:Pin!
    var selectedPinLocation:String!
    var photoData:[Photo]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Register cell classes
        photoCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        addSelectedAnnotation()
        print(selectedPinLocation)
        getPhotos()
    }
    
    func getPhotos(){
        
        // check that photos for the pin are there in core data or not?
        // fetchrequest -> Photo , pin (if photo exist on selected pin)
        // collectionview.reloadata
        // if not, then only call getImagesFromFlickr
        FlickrClient.sharedInstance.getImagesFromFlickr(selectedPinLocation) { (results, error) in
            
            guard error == nil else {
                self.displayAlert(title: "Could not get photos from flickr", message: error?.localizedDescription)
                return
            }
            // add results to photoData and reload collectionview
            performUIUpdatesOnMain {
                self.photoData = results
                print(self.photoData.count)
                self.photoCollectionView.reloadData()
            }
        }
    }
    
    

    @IBAction func newCollection(_ sender: Any) {
        
    }
    
    // MARK: UICollectionViewDataSource


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoAlbumCell
        
        let photo = photoData[indexPath.row]
        // if photo.imageData exists fetch
        
        // else get imageData from photoData urlString
        // photo.urlString -> imageData
        // photo.imageData = imageData
        // assign UIImage to cell.photoImageView.image (asynchronous)
        
        FlickrClient.sharedInstance.getDataFromUrl(photo.urlString!) { (results, error) in
            guard let imageData = results else {
                return
            }
            photo.imageData = imageData as NSData?
            performUIUpdatesOnMain {
                cell.photoImageView.image = UIImage(data: photo.imageData as! Data)
            }
            
        }
        
        
//        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
//        do{
//            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
//            for result in searchResults {
//                cell.photoImageView.image = UIImage(data: result.imageData as! Data)
//                print("Image fetched.")
//            }
//        } catch {
//            print("Error: \(error)")
//        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    //Mark: Show Selected Pin on MapView
    func addSelectedAnnotation(){
        let annotation = MKPointAnnotation()
        let lat = CLLocationDegrees(selectedPin.latitude)
        let lon = CLLocationDegrees(selectedPin.longitude)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        annotation.coordinate = coordinate
        
        //zoom into an appropriate region
        let span = MKCoordinateSpanMake(0.25, 0.25)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        performUIUpdatesOnMain {
            self.mapView.addAnnotation(annotation)
            self.mapView.setRegion(region, animated: true)
        }
    }

}

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
