//
//  FetchEPGData.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/2/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData

class FetchEPGData {
    var moc: NSManagedObjectContext!
    var backgroundMOC: NSManagedObjectContext!
    var postTimer = [String : Timer]()
    var nextFetchTime: Date?
    var paramLanguage: String!
    var fetchTask: URLSessionTask?
    struct ProgObject {
        var programName : String = ""
        var programId : String = ""
        var genre : String = ""
        var category : String = ""
        var channelname : String = ""
        var startTime : String = ""
        var duration : String = ""
        var channelid : String = ""
        var channelnum : String = ""
        var isFav : String = ""
        var imdb : String = ""
    }
    
    
    func cancelURLTask() {
        if(fetchTask?.state == .running) {
            fetchTask?.cancel()
        }
    }
    
    
    func post(_ params : Dictionary<String, String>) {
        
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            //            self.moc = appDelegate.dataController.managedObjectContext
            //            self.backgroundMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            //            self.backgroundMOC.parentContext = self.moc
            let bubbleDateFormat = DateFormatter()
            bubbleDateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            
            //print("POSTING")
            let category = params["category"]! as String
            self.paramLanguage = params["language"]! as String
            
            let url: String = GlobalConstants.BubbleAPI.BUBBLE_POST_API
            var urlRequest = URLRequest(url: URL(string: url)! )
            urlRequest.httpMethod = GlobalConstants.HttpMethod.METHOD_POST
            let session = URLSession.shared
            //            var paramstest: [String: String] = [:]
            //            paramstest["method"] = "get_user_current_programs"
            //            paramstest["email_id"] = "harsh.fad@gmail.com"
            //            paramstest["curtime"] = "2016-09-03 19:30:00"
            //            paramstest["language"] = "English"
            
            var paramString = ""
            
            for (key, value) in params {
                if(!paramString.isEmpty) {
                    paramString += "&"
                }
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                paramString += "\(escapedKey!)=\(escapedValue!)"
            }
            
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = paramString.data(using: String.Encoding.utf8)
            
            
            self.fetchTask = session.dataTask(with: urlRequest, completionHandler: { [weak self]
                (data, response, error) -> () in
                
                //print("RECEIVED DATA FROM SERVER")
                guard let responseData = data else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys().NetworkErrorKey + params["category"]!), object: self)
                    }
                    return
                }
                guard error == nil else {
                    return
                }
                
                guard let `self` = self else { return }
                
                do {
                    guard let receivedJSON = try JSONSerialization.jsonObject(with: responseData, options:[]) as? [String: AnyObject] else {
                        return
                    }
                    
                    
                    guard let programslist = receivedJSON["channelprograms"] as? [String : [AnyObject]] else {
                        return
                    }
                    
                    
                    
                    
                    //self.backgroundMOC.perform {
                    
                    var startDate: Date?
                    self.nextFetchTime = nil
                    
                    var hdmap = [Int: [String:[String]]]()
                    var counter = 1
                    var rowNumber = 1
                    var finalmap = [Int: [Int]]()
                    for (_, value) in programslist {
                        
                        
                        let progarray = self.parseJson(value)
                        var hdKey: Int!
                        
                        for (index,element) in progarray.enumerated() {
                            
                            var matchFound = false
                            
                            if(index == 0) {
                                for (key,channelelement) in hdmap {
                                    for (innerkey, innervalue) in channelelement {
                                        //will enter only once
                                        if(innerkey == element.programName) {
                                            if(innervalue.count == 1) {
                                                var ch_name = innervalue[0]
                                                if(ch_name.contains(" HD")) {
                                                    ch_name = ch_name.replacingOccurrences(of: " HD", with: "")
                                                    if(ch_name == element.channelname) {
                                                        //found a match - HD channel already exists
                                                        matchFound = true
                                                        hdKey = key
                                                        finalmap[key]![0] = rowNumber
                                                    }
                                                } else {
                                                    var tmpchnlname = element.channelname
                                                    tmpchnlname = tmpchnlname.replacingOccurrences(of: " HD", with: "")
                                                    if(ch_name == tmpchnlname) {
                                                        //found a match - non HD channel already exists
                                                        matchFound = true
                                                        hdKey = key
                                                        finalmap[key]![1] = rowNumber
                                                        
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if(!matchFound) {
                                    hdKey = counter
                                    hdmap[hdKey] = [element.programName: [element.channelname]]
                                    if(element.channelname.contains(" HD")) {
                                        finalmap[counter] = [0,rowNumber]
                                    } else {
                                        finalmap[counter] = [rowNumber,0]
                                    }
                                    counter += 1
                                }
                            }
                            
                            let entity: NSManagedObject
                            switch (index) {
                            case 0: entity = NSEntityDescription.insertNewObject(forEntityName: "ProgramsNow", into: self.backgroundMOC) //
                                
                            case 1: entity = NSEntityDescription.insertNewObject(forEntityName: "ProgramsNext", into: self.backgroundMOC) //
                                
                            case 2: entity = NSEntityDescription.insertNewObject(forEntityName: "ProgramsLater", into: self.backgroundMOC) //
                                
                            default: entity = NSManagedObject()
                            }
                            
                            
                            entity.setValue(element.programId, forKey: "programId")
                            entity.setValue(element.programName, forKey: "programName")
                            entity.setValue(element.genre, forKey: "genre")
                            entity.setValue(element.category, forKey: "category")
                            entity.setValue(element.channelid, forKey: "channelId")
                            entity.setValue(element.startTime, forKey: "startTime")
                            entity.setValue(element.duration, forKey: "duration")
                            entity.setValue(element.channelname, forKey: "channelName")
                            entity.setValue(element.channelnum, forKey: "channelNum")
                            entity.setValue(element.imdb, forKey: "imdbRating")
                            entity.setValue(hdKey, forKey: "hdKey")
                            entity.setValue(rowNumber, forKey: "primaryKey")
                            
                            
                            if(index == 0) {
                                let startdatestring = element.startTime
                                let durationInt = Double(element.duration)
                                startDate = bubbleDateFormat.date(from: startdatestring)
                                let tmpTime = startDate!.addingTimeInterval(durationInt! * 60)
                                if(self.nextFetchTime == nil) {
                                    self.nextFetchTime = tmpTime
                                } else {
                                    if(tmpTime.compare(self.nextFetchTime!) == ComparisonResult.orderedAscending) {
                                        self.nextFetchTime = tmpTime
                                    }
                                }
                            }
                            if(index == 2) {
                                rowNumber += 1
                            }
                        }
                    }
                    
                    for (key,value) in finalmap {
                        let hdentity = NSEntityDescription.insertNewObject(forEntityName: "HDMap", into: self.backgroundMOC)
                        hdentity.setValue(key, forKey: "primaryKey")
                        hdentity.setValue(params["category"], forKey: "category")
                        hdentity.setValue(value[1], forKey: "hdRow")
                        hdentity.setValue(value[0], forKey: "sdRow")
                    }
                    
                    do {
                        try self.backgroundMOC.save()
                        self.moc.performAndWait {
                            do {
                                try self.moc.save()
                            } catch {
                                fatalError("Failure to save context: \(error)")
                            }
                        }
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
//                    do {
//                        try self.moc.save()
//                    } catch {
//                        fatalError("error saving stb codes to entity")
//                    }
                    
                    if (!(self.postTimer[category] == nil)) {
                        self.postTimer[category]!.invalidate()
                    }
                    
                    DispatchQueue.main.async {
                        //print("DISPATCHING QUEUE NOW TO HOMEFEED")
                        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys().dataRefreshNotificationKey + params["category"]!), object: self)
                        if let secondsBeforeNewPost = (Calendar.current as NSCalendar).components(.second, from: Date(), to: self.nextFetchTime!, options: []).second {
                            //print("SCHEDULING NEW POST AFTER \(secondsBeforeNewPost) SECONDS")
                            
                            self.postTimer[category] = Timer.scheduledTimer(timeInterval: Double(secondsBeforeNewPost), target: self, selector: #selector(FetchEPGData.postAgain), userInfo: ["category" : params["category"]! as String, "email" : params["emailid"]! as String,"language" : params["language"]! as String], repeats: false)
                        }
                        
                        //}
                        
                    }
                } catch {
                }
                })
            
            appDelegate.dataStoreController.inContext { context in
                guard let context = context else {
                    return
                }
                
                //self.moc = context
                
                //self.deletePrograms(category, context: context)
                //self.fetchTask?.resume()
                
                
                //print("ENTERING TEH DELETEING BLOCK")
                
                // Do stuff with context
                self.moc = context
                self.backgroundMOC = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                self.backgroundMOC.parent = context
                
                self.backgroundMOC.perform {
                    
                    do {
                        if let lang = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RECENT_LANGUAGE) as? String {
                            if lang != self.paramLanguage {
                                return
                            }
                        }
                        self.deletePrograms(category, context: self.backgroundMOC)
                        self.fetchTask?.resume()
//                        self.moc.performAndWait {
//                            do {
//                                try self.moc.save()
//                            } catch {
//                                fatalError("Failure to save context: \(error)")
//                            }
//                        }
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
                //self.fetchTask?.resume()
            }
        }
        
    }
    
    
    @objc func postAgain(_ val: Timer) {
        //print("POATING AGAIN")
        
        var paramstest: [String: String] = [:]
        paramstest["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_CURRENT_PROGRAMS
        paramstest["emailid"] = (val.userInfo! as AnyObject).object(forKey: "email") as? String
        let bubbleDateFormat = DateFormatter()
        bubbleDateFormat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT
        let currenttime = bubbleDateFormat.string(from: Date())
        paramstest["starttime"] = currenttime
        let endtime = bubbleDateFormat.string(from: Date().addingTimeInterval(60*60*4))
        paramstest["endtime"] = endtime
        paramstest["language"] = (val.userInfo! as AnyObject).object(forKey: "language") as? String
        paramstest["category"] = (val.userInfo! as AnyObject).object(forKey: "category") as? String
        self.post(paramstest)
    }
    
    func invalidateTimer(category: String!) {
        if (self.postTimer[category]?.isValid == true) {
            self.postTimer[category]!.invalidate()
        }
    }
    
    func deletePrograms(_ category : String, context: NSManagedObjectContext) {
        
        let categoryPredicate = NSPredicate(format: "category = %@", category)
        
//        let requestNow = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNow")
//        let requestNext = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNext")
//        let requestLater = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsLater")
//        let requestHDMap = NSFetchRequest<NSFetchRequestResult>(entityName: "HDMap")
//        
//        requestNow.predicate = categoryPredicate
//        requestNext.predicate = categoryPredicate
//        requestLater.predicate = categoryPredicate
//        requestHDMap.predicate = categoryPredicate
//        
//        let batchDeleteNow = NSBatchDeleteRequest(fetchRequest: requestNow)
//        let batchDeleteNext = NSBatchDeleteRequest(fetchRequest: requestNext)
//        let batchDeleteLater = NSBatchDeleteRequest(fetchRequest: requestLater)
//        let batchDeleteHDMap = NSBatchDeleteRequest(fetchRequest: requestHDMap)
//        
//        do {
//            try context.execute(batchDeleteNow)
//            try context.execute(batchDeleteNext)
//            try context.execute(batchDeleteLater)
//            try context.execute(batchDeleteHDMap)
//            
//        } catch {
//            print("error deleting data")
//        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNow")
        request.includesPropertyValues = false
        //let categoryPredicate = NSPredicate(format: "category = %@", category)
        request.predicate = categoryPredicate
        
        let requestNext = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNext")
        requestNext.predicate = categoryPredicate
        requestNext.includesPropertyValues = false
        
        let requestLater = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsLater")
        requestLater.predicate = categoryPredicate
        requestLater.includesPropertyValues = false
        
        let hdmaprequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HDMap")
        hdmaprequest.predicate = categoryPredicate
        hdmaprequest.includesPropertyValues = false
        
        
        //print("deleting all category data \(category)")
        do {
            if let incidents = try self.backgroundMOC.fetch(request) as? [NSManagedObject] {
                //if incidents.count > 0 {
                for result in incidents{
                    self.backgroundMOC.delete(result)
                    //print("NSManagedObject \(i) has been Deleted")
                }
                //}
            }
            
            if let incidentsNext = try backgroundMOC.fetch(requestNext) as? [NSManagedObject] {
                
                //if incidentsNext.count > 0 {
                for resultNext in incidentsNext{
                    backgroundMOC.delete(resultNext)
                    //print("NSManagedObject \(i) has been Deleted")
                }
                //}
            }
            if let incidentsLater = try backgroundMOC.fetch(requestLater) as? [NSManagedObject] {
                //if incidentsLater.count > 0 {
                for resultLater in incidentsLater{
                    backgroundMOC.delete(resultLater)
                    //print("NSManagedObject \(i) has been Deleted")
                }
                //}
            }
            if let hdmapdata = try backgroundMOC.fetch(hdmaprequest) as? [NSManagedObject] {
                //if hdmapdata.count > 0 {
                for resultmap in hdmapdata{
                    backgroundMOC.delete(resultmap)
                    //print("NSManagedObject \(i) has been Deleted")
                }
                //}
            }
            
            do {
                try self.backgroundMOC.save()
                self.moc.performAndWait {
                    do {
                        try self.moc.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
            } catch {
                fatalError("Failure to save context: \(error)")
            }
            
        } catch {
            fatalError()
        }
    }
    
    func parseJson(_ anyObj:[AnyObject]) -> Array<ProgObject>{
        
        var list:Array<ProgObject> = []
        
        
        var b:ProgObject = ProgObject()
        
        for json in anyObj {
            if let json = json as? [String] {
                b.programId = json[0] // to get rid of null
                b.programName  =  json[1]
                b.genre  =  json[2]
                b.category  =  json[3]
                b.channelid  =  json[4]
                b.startTime  =  json[5]
                b.duration  =  json[6]
                b.channelname  =  json[7]
                b.channelnum  =  json[9]
                b.imdb  =  json[8]
                
                list.append(b)
            }
        }// for
        
        return list
        
    }//func
    
    
}
