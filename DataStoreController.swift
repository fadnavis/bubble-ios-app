//
//  DataStoreController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/26/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import CoreData
import Dispatch

class DataStoreController {
    
    private var _managedObjectContext: NSManagedObjectContext
    
    var managedObjectContext: NSManagedObjectContext? {
        guard let coordinator = _managedObjectContext.persistentStoreCoordinator else {
            return nil
        }
        if coordinator.persistentStores.isEmpty {
            return nil
        }
        return _managedObjectContext
    }
    
    let managedObjectModel: NSManagedObjectModel
    let persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    var error: NSError?
    
    func inContext(_ callback: @escaping (NSManagedObjectContext?) -> Void) {
        // Dispatch the request to our serial queue first and then back to the context queue.
        // Since we set up the stack on this queue it will have succeeded or failed before
        // this block is executed.
        queue.async {
            guard let context = self.managedObjectContext else {
                callback(nil)
                return
            }
            
            context.perform {
                callback(context)
            }
        }
    }
    
    private let queue = DispatchQueue(label: "DataStoreControllerSerialQueue", attributes: [], target: nil)
    
    init(modelUrl: URL, storeUrl: URL, concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) {
        
        guard let modelAtUrl = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing managed object model from URL: \(modelUrl)")
        }
        managedObjectModel = modelAtUrl
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        _managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        _managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        
        //let dispatch_queue_attr = dispatch_queue_attr_make_with_qos_class(DispatchQueue.Attributes(), DispatchQoS.QoSClass.userInitiated, 0)
        //queue = DispatchQueue(label: "DataStoreControllerSerialQueue", attributes: dispatch_queue_attr)
        
        queue.async {
            do {
                try self.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
            } catch let error as NSError {
                self.error = error
            } catch {
                fatalError()
            }
        }
    }
}
