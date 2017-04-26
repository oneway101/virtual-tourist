//
//  Photo+CoreDataProperties.swift
//  virtual-tourist
//
//  Created by Ha Na Gill on 4/24/17.
//  Copyright © 2017 Ha Na Gill. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var urlString: String?
    @NSManaged public var pin: Pin?

}
