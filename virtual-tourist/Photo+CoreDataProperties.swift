//
//  Photo+CoreDataProperties.swift
//  virtual-tourist
//
//  Created by Ha Na Gill on 3/29/17.
//  Copyright © 2017 Ha Na Gill. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var bbox: String?
    @NSManaged public var pins: NSSet?

}

// MARK: Generated accessors for pins
extension Photo {

    @objc(addPinsObject:)
    @NSManaged public func addToPins(_ value: Pin)

    @objc(removePinsObject:)
    @NSManaged public func removeFromPins(_ value: Pin)

    @objc(addPins:)
    @NSManaged public func addToPins(_ values: NSSet)

    @objc(removePins:)
    @NSManaged public func removeFromPins(_ values: NSSet)

}
