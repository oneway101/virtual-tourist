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
    var imageUrls:[URL]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        photoCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        //let selectedPinLocation = bboxString(longitude: selectedPin.longitude, latitude: selectedPin.latitude)
        print(selectedPinLocation)
        getPhotos()
    }
    
    func getPhotos(){
        FlickrClient.sharedInstance.getImagesFromFlickr(selectedPinLocation) { (results, error) in
            guard error == nil else {
                print(error)
                return
            }
            if let photosArray = results {
                
                if photosArray.count == 0 {
                    print("No photos in photosArray.")
                    return
                }
                print("\(photosArray.count) photos in phtosArray.")
                for photo in photosArray {
                    
                    guard let imageUrlString = photo[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        print("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photosArray)")
                        return
                    }
                    if let imageUrl = URL(string: imageUrlString) {
                        self.imageUrls.append(imageUrl)
                    }
                }
            }
        }
    }

    @IBAction func newCollection(_ sender: Any) {
        
    }

    // MARK: UICollectionViewDataSource


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoAlbumCell
        
        for url in imageUrls {
            let context = CoreDataStack.getContext()
            let photo:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context ) as! Photo
            let downloadedImage = cell.photoImageView.downloadedFrom(url: url)
            photo.imageString = downloadedImage
            CoreDataStack.saveContext()

        }
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
