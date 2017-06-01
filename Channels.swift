//
//  ChannelData.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/18/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import Foundation
import CoreData


class Channels: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    @NSManaged var channelId: String?
    @NSManaged var channelName: String?
    @NSManaged var channelNumber: String?
    @NSManaged var channelCategory: String?    
}
