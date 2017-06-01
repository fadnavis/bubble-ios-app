//
//  RemoteContainerViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 1/30/17.
//  Copyright © 2017 Harsh Fadnavis. All rights reserved.
//

import Foundation
import CoreData

class RemoteContainerViewController: UIViewController {
    //var tvdetailed : Bool?
    var pageMenu : CAPSPageMenu?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Remote Controls"
        createRemoteTabs()
    }
    
    func createRemoteTabs() {
        if let tvdetailed = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_TV_REMOTES_DETAILED) as? Bool {
            if tvdetailed == true {
                let mainstoryboard = UIStoryboard(name: "Main", bundle: nil)
                let stbcontroller = mainstoryboard.instantiateViewController(withIdentifier: "remoteView") as? RemoteViewController
                stbcontroller?.title = "STB Remote"
                let tvcontroller = mainstoryboard.instantiateViewController(withIdentifier: "tvremoteview") as? TVRemoteViewController
                tvcontroller?.title = "TV Remote"
                
                let parameters: [CAPSPageMenuOption] = [
                    .scrollMenuBackgroundColor(UIColor.white),
                    .viewBackgroundColor(UIColor.BubbleDarkIndigo()),
                    .selectionIndicatorColor(UIColor.BubbleDarkIndigo()),
                    .menuItemFont(UIFont(name: "Quicksand-Bold", size: 15.0)!),
                    .menuHeight(40.0),
                    .menuItemWidth(90.0),
                    .menuItemWidthBasedOnTitleTextWidth(true),
                    .centerMenuItems(false),
                    .selectedMenuItemLabelColor(UIColor.BubbleDarkIndigo()),
                    .unselectedMenuItemLabelColor(UIColor.BubbleGray()),
                    .menuItemSeparatorWidth(2.0),
                    .addBottomMenuHairline(true),
                    .bottomMenuHairlineColor(UIColor.BubbleDarkIndigo())
                ]
                
                pageMenu = CAPSPageMenu(viewControllers: [stbcontroller!,tvcontroller!], frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
                
                self.addChildViewController(pageMenu!)
                self.view.addSubview(pageMenu!.view)
                pageMenu!.didMove(toParentViewController: self)
            } else {
                let mainstoryboard = UIStoryboard(name: "Main", bundle: nil)
                let stbcontroller = mainstoryboard.instantiateViewController(withIdentifier: "remoteView") as? RemoteViewController
                let parameters: [CAPSPageMenuOption] = [
                    .scrollMenuBackgroundColor(UIColor.white),
                    .viewBackgroundColor(UIColor.BubbleDarkIndigo()),
                    .selectionIndicatorColor(UIColor.BubbleDarkIndigo()),
                    .menuItemFont(UIFont(name: "Quicksand-Bold", size: 15.0)!),
                    .menuHeight(40.0),
                    .menuItemWidth(90.0),
                    .menuItemWidthBasedOnTitleTextWidth(true),
                    .centerMenuItems(false),
                    .selectedMenuItemLabelColor(UIColor.BubbleDarkIndigo()),
                    .unselectedMenuItemLabelColor(UIColor.BubbleGray()),
                    .menuItemSeparatorWidth(2.0),
                    .addBottomMenuHairline(true),
                    .bottomMenuHairlineColor(UIColor.BubbleDarkIndigo())
                ]
                
                pageMenu = CAPSPageMenu(viewControllers: [stbcontroller!], frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
                
                self.addChildViewController(pageMenu!)
                self.view.addSubview(pageMenu!.view)
                pageMenu!.didMove(toParentViewController: self)
            }
        } else {
            let mainstoryboard = UIStoryboard(name: "Main", bundle: nil)
            let stbcontroller = mainstoryboard.instantiateViewController(withIdentifier: "remoteView") as? RemoteViewController
            let parameters: [CAPSPageMenuOption] = [
                .scrollMenuBackgroundColor(UIColor.white),
                .viewBackgroundColor(UIColor.BubbleDarkIndigo()),
                .selectionIndicatorColor(UIColor.BubbleDarkIndigo()),
                .menuItemFont(UIFont(name: "Quicksand-Bold", size: 15.0)!),
                .menuHeight(40.0),
                .menuItemWidth(90.0),
                .menuItemWidthBasedOnTitleTextWidth(true),
                .centerMenuItems(false),
                .selectedMenuItemLabelColor(UIColor.BubbleDarkIndigo()),
                .unselectedMenuItemLabelColor(UIColor.BubbleGray()),
                .menuItemSeparatorWidth(2.0),
                .addBottomMenuHairline(true),
                .bottomMenuHairlineColor(UIColor.BubbleDarkIndigo())
            ]
            
            pageMenu = CAPSPageMenu(viewControllers: [stbcontroller!], frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
            
            self.addChildViewController(pageMenu!)
            self.view.addSubview(pageMenu!.view)
            pageMenu!.didMove(toParentViewController: self)
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "Remote Controls"
    }
    
//    func fetchAllRemoteCodes() {
//        var params: [String: String] = [:]
//        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_GET_STB_CODES
//        params["email_id"] = UserData.sharedInstance.userEmail
//        params["stbname"] = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) as! String?
//        let bubbleAPI = CallBubbleApi()
//        bubbleAPI.delegate = self
//        bubbleAPI.post(params)
//    }
//    
//    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
//        if let status = responseJSON["status"] as? Int {
//            if (methodName == GlobalConstants.HttpMethodName.BUBBLE_GET_STB_CODES) {
//                if status == 0 {
//                    deleteAllRemoteCodes()
//                    saveSTBRemoteCodesToEntity(responseJSON)
//                    saveTVRemoteCodesToEntity(responseJSON)
//                }
//            }
//        }
//    }
//    
//    func onNetworkError(methodName: String) {
//        //
//    }
    
//    func deleteAllRemoteCodes() {
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.dataStoreController.inContext {
//            context in
//            
//            guard let context = context else {
//                return
//            }
//            let requestChannelData = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
//            let batchDeleteChannels = NSBatchDeleteRequest(fetchRequest: requestChannelData)
//            
//            do {
//                try context.execute(batchDeleteChannels)
//            } catch {
//                fatalError()
//            }
//        }
//    }
//    
//    func saveTVRemoteCodesToEntity(_ json: [String: AnyObject]) {
//        let appdelegate = UIApplication.shared.delegate as! AppDelegate!
//        appdelegate?.dataStoreController.inContext { context in
//            guard let context = context else {
//                return
//            }
//            guard let codeslist = json["usercodes"] as? NSArray else {
//                return
//            }
//            for code in codeslist {
//                let entity = NSEntityDescription.insertNewObject(forEntityName: "STBCodes", into: context)
//                if let data = code as? [String] {
//                    entity.setValue("TV", forKey: "medium")
//                    entity.setValue(data[1], forKey: "remoteNumber")
//                    entity.setValue(data[2], forKey: "protocol")
//                    entity.setValue(data[3], forKey: "address")
//                    entity.setValue(data[4], forKey: "hexcode")
//                    entity.setValue(data[5], forKey: "bits")
//                    entity.setValue(data[6], forKey: "rawcode")
//                    entity.setValue(data[7], forKey: "rawlength")
//                    entity.setValue(data[8], forKey: "frequency")
//                }
//            }
//            
//            do {
//                try context.save()
//            } catch {
//                fatalError("error saving tv codes to entity")
//            }
//        }
//    }
//    
//    func saveSTBRemoteCodesToEntity(_ json: [String: AnyObject]) {
//        let appdelegate = UIApplication.shared.delegate as! AppDelegate!
//        appdelegate?.dataStoreController.inContext { context in
//            guard let context = context else {
//                return
//            }
//            guard let codeslist = json["stbcodes"] as? NSArray else {
//                return
//            }
//            for code in codeslist {
//                let entity = NSEntityDescription.insertNewObject(forEntityName: "STBCodes", into: context)
//                if let data = code as? [String] {
//                    entity.setValue("STB", forKey: "medium")
//                    entity.setValue(data[0], forKey: "remoteNumber")
//                    entity.setValue(data[1], forKey: "protocol")
//                    entity.setValue(data[2], forKey: "address")
//                    entity.setValue(data[3], forKey: "hexcode")
//                    entity.setValue(data[4], forKey: "bits")
//                    entity.setValue(data[5], forKey: "rawcode")
//                    entity.setValue(data[6], forKey: "rawlength")
//                    entity.setValue(data[7], forKey: "frequency")
//                }
//            }
//            
//            do {
//                try context.save()
//            } catch {
//                fatalError("error saving stb codes to entity")
//            }
//        }
//    }
}
