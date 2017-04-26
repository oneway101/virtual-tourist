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

private let reuseIdentifier = "PhotoAlbumCell"

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var selectedPin:Pin!
    var photoData:[Photo] = [Photo]()
    var selectedIndexPaths = [NSIndexPath]()
    var deletePhoto = false
    var currentPage = 0
    
    
    private let persistentContainer = NSPersistentContainer(name: "Photo")
    
    // MARK: Core Data FetchResultController
//   lazy var fetchedResultsController: NSFetchedResultsController = {        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "photo", ascending: false)]
//        fetchRequest.predicate = NSPredicate(format: "pin == %@", selectedPin!)
//        let context = CoreDataStack.getContext()
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
//        fetchedResultsController.delegate = self
//        return fetchedResultsController
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Register cell classes
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        addSelectedAnnotation()
        print("selected pin location: \(selectedPin)")
        
        fetchPhotos()
        
        // MARK: Set spacing between items
        let space: CGFloat = 3.0
        let viewWidth = self.view.frame.width
        let dimension: CGFloat = (viewWidth-(2*space))/3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func fetchPhotos(){
        
        // check that photos for the pin are there in core data or not?
        // fetchrequest -> Photo , pin (if photo exist on selected pin)
        // collectionview.reloadata
        // if not, then call getImagesFromFlickr
        
        //MARK: Fetch Request
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", selectedPin!)
        let context = CoreDataStack.getContext()
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        if let data = fetchedResultsController.fetchedObjects, data.count > 0 {
            print("core data count: \(data.count)")
            photoData = data
            self.photoCollectionView.reloadData()
        } else {
            getPhotosFromFlickr(page:currentPage)
        }
    }
    
    //MARK: get new photos from flickr
    func getPhotosFromFlickr(page:Int){
        FlickrClient.sharedInstance.getImagesFromFlickr(selectedPin,currentPage) { (results, error) in
            
            guard error == nil else {
                self.displayAlert(title: "Could not get photos from flickr", message: error?.localizedDescription)
                return
            }
            // add results to photoData and reload collectionview
            performUIUpdatesOnMain {
                if results != nil {
                    self.photoData = results!
                    
                    print("photo data: \(self.photoData.count)")
                    self.photoCollectionView.reloadData()
                }
            }
        }
    }

    @IBAction func newCollection(_ sender: Any) {
        
        if deletePhoto {
            newCollectionButton.titleLabel?.text = "New Collection"
            removeSelectedPhotos()
            self.photoCollectionView.reloadData()
            deletePhoto = false
        } else {
            for photo in photoData {
                CoreDataStack.getContext().delete(photo)
            }
            CoreDataStack.saveContext()
            currentPage += 1
            getPhotosFromFlickr(page: currentPage)
            
        }
    }
    
    func removeSelectedPhotos() {
        if selectedIndexPaths.count > 0 {
            for indexPath in selectedIndexPaths {
                let photo = photoData[indexPath.row]
                CoreDataStack.getContext().delete(photo)
                self.photoData.remove(at: indexPath.row)
                self.photoCollectionView.deleteItems(at: [indexPath as IndexPath])
                print("photo deleted")
            }
            CoreDataStack.saveContext()
        }
        selectedIndexPaths = [NSIndexPath]()
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoAlbumCell
        
        if photoCell != nil {
            //print("\(photoCell)")
        }
        
        let photo = photoData[indexPath.row]
        // if photo.imageData exists fetch
        
        // else get imageData from photoData urlString
        // photo.urlString -> imageData
        // photo.imageData = imageData
        // assign UIImage to cell.photoImageView.image (asynchronous)
        
        if photo.imageData != nil {
            photoCell!.photoImageView.image = UIImage(data: photo.imageData as! Data)
        } else {
        
            FlickrClient.sharedInstance.getDataFromUrl(photo.urlString!) { (results, error) in
                guard let imageData = results else {
                    self.displayAlert(title: "Image data error", message: error)
                    return
                }
                photo.imageData = imageData as NSData?
                performUIUpdatesOnMain {
                photoCell!.photoImageView.image = UIImage(data: photo.imageData as! Data)
                }
                
            }
        }
        
        return photoCell!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCell
        
        let index = selectedIndexPaths.index(of: indexPath as NSIndexPath)
        print("index \(index)")
        
        if let index = index {
            selectedIndexPaths.remove(at: index)
            selectedCell.photoImageView.alpha = 1.0
        } else {
            selectedIndexPaths.append(indexPath as NSIndexPath)
            selectedCell.photoImageView.alpha = 0.25
        }
        print("selectedIndexPaths: \(selectedIndexPaths)")
        
        if selectedIndexPaths.count > 0 {
            deletePhoto = true
            newCollectionButton.setTitle("Delete", for: .normal)
        } else {
            deletePhoto = false
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
        
    }
    
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
