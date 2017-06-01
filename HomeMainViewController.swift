//
//  HomeMainViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/12/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData

@objc
protocol CenterViewControllerDelegate {
    @objc optional func toggleLeftPanel()
    @objc optional func toggleRightPanel()
    @objc optional func collapseSidePanels()
}

class HomeMainViewController: UIViewController, HomeFeedLoadedDelegate, BubbleAPIDelegate {
    var titles: [String] = []
    var centerviewdelegate: CenterViewControllerDelegate?
    var pageMenu : CAPSPageMenu?
    var userEmail: String!
    var button: UIButton!
    var loadingView: UIActivityIndicatorView!
    var helperView: UIView!
    var controllerArray: [HomeFeedView] = []
    var isPageMenuSetupDone = false
    var channelIdFromNotification = ""
    var channelNameFromNotification = ""

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSharedUserData()
//        if let fid = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_FACEBOOK_ID) as? String {
//            if (fid == "") {
//                GIDSignIn.sharedInstance().signInSilently()
//            }
//        }
        
        self.isPageMenuSetupDone = false
        NotificationCenter.default.addObserver(self, selector: #selector(HomeMainViewController.receiveNotificationWhenInactive(notification:)), name: Notification.Name( NotificationKeys().programReminderNotificationKeyInactive), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeMainViewController.receiveNotificationWhenActive(notification:)), name: Notification.Name( NotificationKeys().programReminderNotificationKeyActive), object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(BluetoothSerialMain.applicationWillResignActive), name: Notification.Name(NotificationKeys().ApplicationWillResignActive), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeMainViewController.applicationWillEnterForeground), name: Notification.Name(NotificationKeys().ApplicationWillEnterForeground), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(HomeMainViewController.applicationDidEnterBackground), name: Notification.Name(NotificationKeys().ApplicationDidEnterBackground), object: nil)
        
        
        if (self.channelIdFromNotification != "") {
            openChannelPageFromNotification()
        }
        
        fetchAllRemoteCodes()
    }
    
    func fetchAllRemoteCodes() {
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_GET_STB_CODES
        params["email_id"] = UserData.sharedInstance.userEmail
        params["stbname"] = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) as! String?
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        bubbleAPI.post(params)
    }
    
    func logEventOnServer() {
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_EVENT_LOG
        params["email_id"] = UserData.sharedInstance.userEmail
        params["event"] = "SessionBegin"
        params["label"] = ""
        params["channelid"] = ""
        params["programid"] = ""
        params["source"] = "iOS"
        params["macid"] = UserData.sharedInstance.bubbleMAC
        bubbleAPI.post(params)
    }
    
    func saveTVRemoteCodesToEntity(_ json: [String: AnyObject]) {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate!
        appdelegate?.dataStoreController.inContext { context in
            guard let context = context else {
                return
            }
            guard let codeslist = json["usercodes"] as? NSArray else {
                return
            }
            for code in codeslist {
                let entity = NSEntityDescription.insertNewObject(forEntityName: "STBCodes", into: context)
                if let data = code as? [String] {
                    entity.setValue("TV", forKey: "medium")
                    entity.setValue(data[1], forKey: "remoteNumber")
                    entity.setValue(data[2], forKey: "protocol")
                    entity.setValue(data[3], forKey: "address")
                    entity.setValue(data[4], forKey: "hexcode")
                    entity.setValue(data[5], forKey: "bits")
                    entity.setValue(data[6], forKey: "rawcode")
                    entity.setValue(data[7], forKey: "rawlength")
                    entity.setValue(data[8], forKey: "frequency")
                }
            }
            
            do {
                try context.save()
            } catch {
                fatalError("error saving tv codes to entity")
            }
        }
    }
    
    func saveSTBRemoteCodesToEntity(_ json: [String: AnyObject]) {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate!
        appdelegate?.dataStoreController.inContext { context in
            guard let context = context else {
                return
            }
            guard let codeslist = json["stbcodes"] as? NSArray else {
                return
            }
            for code in codeslist {
                let entity = NSEntityDescription.insertNewObject(forEntityName: "STBCodes", into: context)
                if let data = code as? [String] {
                    entity.setValue("STB", forKey: "medium")
                    entity.setValue(data[0], forKey: "remoteNumber")
                    entity.setValue(data[1], forKey: "protocol")
                    entity.setValue(data[2], forKey: "address")
                    entity.setValue(data[3], forKey: "hexcode")
                    entity.setValue(data[4], forKey: "bits")
                    entity.setValue(data[5], forKey: "rawcode")
                    entity.setValue(data[6], forKey: "rawlength")
                    entity.setValue(data[7], forKey: "frequency")
                }
            }
            
            do {
                try context.save()
            } catch {
                fatalError("error saving stb codes to entity")
            }
        }
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if (methodName == GlobalConstants.HttpMethodName.BUBBLE_GET_STB_CODES) {
                if status == 0 {
                    deleteAllRemoteCodes()
                    saveSTBRemoteCodesToEntity(responseJSON)
                    saveTVRemoteCodesToEntity(responseJSON)
                    logEventOnServer()
                }
            }
        }
    }
    
    func deleteAllRemoteCodes() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                return
            }
            let requestChannelData = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
            let batchDeleteChannels = NSBatchDeleteRequest(fetchRequest: requestChannelData)
            
            do {
                try context.execute(batchDeleteChannels)
            } catch {
                fatalError()
            }
        }
    }
    
    func onNetworkError(methodName: String) {
        //do nothing
    }
    
    func receiveNotificationWhenInactive(notification: Notification) {
        if let userinfo = notification.userInfo {
            if let channame = userinfo["channelName"] as? String, let chanid = userinfo["channelId"] as? String {
                self.channelIdFromNotification = chanid
                self.channelNameFromNotification = channame
                openChannelPageFromNotification()
            }
        }
    }
    
    func receiveNotificationWhenActive(notification: Notification) {
        if let userinfo = notification.userInfo {
            if let channame = userinfo["channelName"] as? String, let chanid = userinfo["channelId"] as? String, let progname = userinfo["programName"] as? String {
                
                let alert = UIAlertController(title: "Program Starting", message: "\(progname) starting now on \(channame)", preferredStyle: .alert)
                let watchNowAction = UIAlertAction(title: "Watch Now", style: .default) {
                    (_)-> Void in
                    self.channelNameFromNotification = channame
                    self.channelIdFromNotification = chanid
                    self.openChannelPageFromNotification()
                }
                
                alert.addAction(watchNowAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
//    func ApplicationWillResignActive() {
//        
//    }
    
    func applicationWillEnterForeground() {
        if pageMenu == nil { return }
        resetPageMenu()
    }
    
    func applicationDidEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
    }
    
    func openChannelPageFromNotification() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        if (self.channelIdFromNotification != "") {
            goToChannelPage()
        }
    }
    
    func goToChannelPage() {
        let nextOnThisChannelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "nextPrograms") as! NextProgramsViewController
        nextOnThisChannelVC.channelId = self.channelIdFromNotification
        nextOnThisChannelVC.channelNameString = self.channelNameFromNotification
        self.channelIdFromNotification = ""
        self.channelNameFromNotification = ""
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationController?.pushViewController(nextOnThisChannelVC, animated: true)
    }
    
    func feedLoaded() {
        if let _ = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.MAIN_HELPER) {} else {
            setupHelperOverlay()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.navigationBar.topItem?.title = "Playing Now"
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.BubbleOffWhite2(),
            NSFontAttributeName: UIFont(name: "Quicksand-Bold", size: 19)!
        ]
        
//        let attrs = [
//            NSForegroundColorAttributeName: UIColor.red,
//            NSFontAttributeName: UIFont(name: "Quicksand-Bold", size: 24)!
//        ]
//        centerNavigationController.navigationBar.titleTextAttributes = attrs
        
        //self.navigationController?.navigationBar.topItem?.title = "Playing Now"

//        self.navigationController?.navigationBar.barTintColor = UIColor.init(rgb: 0x111125)
//        
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
        

        if(!self.isPageMenuSetupDone) {
        // Instantiating Storyboard ViewControllers

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            var categories: Array<String>
            if let lastCategory = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RECENT_CATEGORIES) as? Array<String>{
                categories = lastCategory
            } else {
                categories = GlobalConstants.ProgramCategories.Categories
            }
            for cat in categories {
                let controller = storyboard.instantiateViewController(withIdentifier: "mainFeedScene") as? HomeFeedView
                controller!.title = cat
                controller?.homeFeedDelegate = self
                self.controllerArray.append(controller!)
            }
            
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
            
            pageMenu = CAPSPageMenu(viewControllers: self.controllerArray, frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
            
            self.addChildViewController(pageMenu!)
            self.view.addSubview(pageMenu!.view)
            pageMenu!.didMove(toParentViewController: self)
            
            self.button = UIButton(frame: CGRect(x: 100, y: 400, width: 80, height: 80))
            self.button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
            self.button.setBackgroundImage(UIImage(named: "fab"), for: .normal)
            self.button.layer.shadowColor = UIColor.black.cgColor
            self.button.layer.shadowOffset = CGSize(width: 5.0, height: 4.0)
            self.button.layer.shadowOpacity = 0.4
            self.view.addSubview(self.button)
            
            self.button.translatesAutoresizingMaskIntoConstraints = false
            self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottomMargin, multiplier: 1, constant: -20))
            
            self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60))
            
            self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60))
            
            self.isPageMenuSetupDone = true

        }
    }
    
    func tapHelperScreen(recognizer: UITapGestureRecognizer) {
        self.helperView.isHidden = true
        self.helperView.removeFromSuperview()
    }
    
    func setupHelperOverlay() {
        self.helperView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        self.helperView.backgroundColor = UIColor.clear
        self.helperView.isUserInteractionEnabled = true
        
        let helperTapGesture = UITapGestureRecognizer(target: self, action: #selector(HomeMainViewController.tapHelperScreen(recognizer:)))
        self.helperView.addGestureRecognizer(helperTapGesture)
        
        self.view.addSubview(self.helperView)
        self.helperView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: helperView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        let backgroundview = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        backgroundview.backgroundColor = UIColor.BubbleDarkIndigo()
        backgroundview.alpha = 0.6
        backgroundview.isUserInteractionEnabled = false
        self.helperView.addSubview(backgroundview)
        backgroundview.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.leading, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: backgroundview, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.helperView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0))
        
        let uicircleview = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        uicircleview.image = UIImage(named: "circle")
        uicircleview.isUserInteractionEnabled = false
        self.helperView.addSubview(uicircleview)
        uicircleview.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .trailing, relatedBy: .equal, toItem: self.helperView, attribute: .trailing, multiplier: 1, constant: -20))
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .bottom, relatedBy: .equal, toItem: self.helperView, attribute: .bottom, multiplier: 1, constant: -20))
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70))
        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70))
        
        let arrowView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        arrowView.image = UIImage(named: "helperArrow1")
        arrowView.isUserInteractionEnabled = false
        self.helperView.addSubview(arrowView)
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView, attribute: .trailing, relatedBy: .equal, toItem: uicircleview, attribute: .leading, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView, attribute: .bottom, relatedBy: .equal, toItem: uicircleview, attribute: .top, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 100))
        self.helperView.addConstraint(NSLayoutConstraint(item: arrowView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 160))
        
        let textView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        textView.image = UIImage(named: "helperText1")
        textView.isUserInteractionEnabled = false
        self.helperView.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.helperView.addConstraint(NSLayoutConstraint(item: textView, attribute: .centerX, relatedBy: .equal, toItem: self.helperView, attribute: .centerX, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: textView, attribute: .bottom, relatedBy: .equal, toItem: arrowView, attribute: .top, multiplier: 1, constant: 0))
        self.helperView.addConstraint(NSLayoutConstraint(item: textView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 300))
        self.helperView.addConstraint(NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 180))
        UserDefaults.standard.set(true, forKey: GlobalConstants.UserDefaults.MAIN_HELPER)

    }
    
    
    func deleteAllProgramData() {
        //                //** NEW **//
        
        for vc in self.controllerArray {
            vc.invalidateTimer()
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                return
            }
            let requestNow = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNow")
            let requestNext = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNext")
            let requestLater = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsLater")
            let requestHDMap = NSFetchRequest<NSFetchRequestResult>(entityName: "HDMap")
            
            let batchDeleteNow = NSBatchDeleteRequest(fetchRequest: requestNow)
            let batchDeleteNext = NSBatchDeleteRequest(fetchRequest: requestNext)
            let batchDeleteLater = NSBatchDeleteRequest(fetchRequest: requestLater)
            let batchDeleteHDMap = NSBatchDeleteRequest(fetchRequest: requestHDMap)
            
            do {
                try context.execute(batchDeleteNow)
                try context.execute(batchDeleteNext)
                try context.execute(batchDeleteLater)
                try context.execute(batchDeleteHDMap)
                
                //                        DispatchQueue.main.async {
                //                            self.resetPageMenu()
                //                        }
            } catch {
                fatalError()
            }
        }
        
        //                //** NEW ** //
    }
    
    func resetPageMenu() {
        pageMenu!.view.removeFromSuperview()
        self.button.removeFromSuperview()
        
        
        var controllerArray: [HomeFeedView] = []
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //        let controller1 = storyboard.instantiateViewControllerWithIdentifier("mainFeedScene") as? HomeFeedView
        //        controller1!.title = "Movies"
        //        let controller2 = storyboard.instantiateViewControllerWithIdentifier("mainFeedScene") as? HomeFeedView
        //        controller2!.title = "Entertainment"
        //        controllerArray.append(controller1!)
        //        controllerArray.append(controller2!)
        var categories: Array<String>
        if let lastCategory = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RECENT_CATEGORIES) as? Array<String>{
            categories = lastCategory
        } else {
            categories = GlobalConstants.ProgramCategories.Categories
        }
        for cat in categories {
            let controller = storyboard.instantiateViewController(withIdentifier: "mainFeedScene") as? HomeFeedView
            controller!.title = cat
            controllerArray.append(controller!)
        }
        
        //        let parameters: [CAPSPageMenuOption] = [
        //            .MenuItemSeparatorWidth(4.3),
        //            .UseMenuLikeSegmentedControl(true),
        //            .MenuItemSeparatorPercentageHeight(0.1)
        //        ]
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
            .addBottomMenuHairline(true),
            .menuItemSeparatorWidth(2.0),
            .bottomMenuHairlineColor(UIColor.BubbleDarkIndigo())
        ]
        
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.width, height: self.view.frame.height), pageMenuOptions: parameters)
        
        self.addChildViewController(pageMenu!)
        self.view.addSubview(pageMenu!.view)
        pageMenu!.didMove(toParentViewController: self)
        
        self.button = UIButton(frame: CGRect(x: 100, y: 400, width: 50, height: 50))
        self.button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.button.setBackgroundImage(UIImage(named: "fab"), for: .normal)
        self.button.layer.shadowColor = UIColor.black.cgColor
        self.button.layer.shadowOffset = CGSize(width: 5.0, height: 4.0)
        self.button.layer.shadowOpacity = 0.4
        self.view.addSubview(self.button)
        
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailingMargin, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.bottomMargin, multiplier: 1, constant: -20))
        self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60))
        
        self.view.addConstraint(NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60))
        
        self.isPageMenuSetupDone = true
    }
    
    
    func buttonAction() {
        self.navigationController?.navigationBar.topItem?.title = ""
        let remoteViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "remotecontainerview")
        self.navigationController?.pushViewController(remoteViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.view.layoutIfNeeded()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.topItem?.title = "Playing Now"
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.BubbleOffWhite2(),
            NSFontAttributeName: UIFont(name: "Quicksand-Bold", size: 19)!
        ]
        self.navigationController?.navigationBar.barTintColor = UIColor.init(rgb: 0x111125)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    
    @IBAction func menuClicked(_ sender: UIBarButtonItem) {
        centerviewdelegate?.toggleLeftPanel?()
    }
    
    
    @IBAction func languageClicked(_ sender: UIBarButtonItem) {
        centerviewdelegate?.toggleRightPanel?()
        
    }
    
    // MARK: - Container View Controller
    override var shouldAutomaticallyForwardAppearanceMethods : Bool {
        return true
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }
    
    func setupSharedUserData() {
        let defaults = UserDefaults.standard
        userEmail = defaults.string(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
        let sharedData = UserData.sharedInstance
        sharedData.userEmail = userEmail
        if let hdstring = defaults.value(forKey: GlobalConstants.UserDefaults.USER_IS_HD_KEY) as? String {
            sharedData.isHD = (hdstring == "1") ? true: false
        } else {
            sharedData.isHD = true
        }
        if let bubblemac = defaults.value(forKey: GlobalConstants.UserDefaults.BUBBLE_MAC_ID) as? String {
            sharedData.bubbleMAC = bubblemac
        } else {
            sharedData.bubbleMAC = ""
        }
    }
    
    func getUserEmail() -> String {
        return userEmail
    }
}

extension HomeMainViewController: SidePanelViewControllerDelegate {
    func menuSelected(_ menu: Menu, isLanguage: Bool) {
        if(isLanguage) {
            var isDiffLang = false
            if let currentLang = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RECENT_LANGUAGE) as? String{
                if(menu.title == currentLang) {
                    isDiffLang = false
                } else {
                    isDiffLang = true
                }
            } else {
                isDiffLang = true
            }
            if(isDiffLang) {
                UserDefaults.standard.set(menu.title, forKey: GlobalConstants.UserDefaults.RECENT_LANGUAGE)
                let langCategory = LanguageCategories()
                UserDefaults.standard.set(langCategory.returnCategories(language: menu.title), forKey: GlobalConstants.UserDefaults.RECENT_CATEGORIES)
                for vc in self.controllerArray {                    
                    vc.invalidateTimer()
                }
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.dataStoreController.inContext {
                    context in
                    
                    guard let context = context else {
                        return
                    }
                    let requestNow = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNow")
                    let requestNext = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNext")
                    let requestLater = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsLater")
                    let requestHDMap = NSFetchRequest<NSFetchRequestResult>(entityName: "HDMap")
                    
                    let batchDeleteNow = NSBatchDeleteRequest(fetchRequest: requestNow)
                    let batchDeleteNext = NSBatchDeleteRequest(fetchRequest: requestNext)
                    let batchDeleteLater = NSBatchDeleteRequest(fetchRequest: requestLater)
                    let batchDeleteHDMap = NSBatchDeleteRequest(fetchRequest: requestHDMap)
                    
                    do {
                        try context.execute(batchDeleteNow)
                        try context.execute(batchDeleteNext)
                        try context.execute(batchDeleteLater)
                        try context.execute(batchDeleteHDMap)
                        
                        DispatchQueue.main.async {
                            self.resetPageMenu()
                        }
                    } catch {
                        fatalError()
                    }
                }
            }
        }
        
        centerviewdelegate?.collapseSidePanels?()
        if(!isLanguage) {
            if(menu.title == GlobalConstants.LeftPaneMenu.SETUP) {
                self.navigationController?.navigationBar.topItem?.title = ""
                let configController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main")
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(configController, animated: true)
            } else if (menu.title == GlobalConstants.LeftPaneMenu.FAQ) {
                self.navigationController?.navigationBar.topItem?.title = ""
                let configController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "faqController")
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(configController, animated: true)
            } else if (menu.title == GlobalConstants.LeftPaneMenu.OPERATOR) {
                self.navigationController?.navigationBar.topItem?.title = ""
                let configController: ChooseSTB = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chooseSTBScene") as! ChooseSTB
                configController.homeMainInstance = self
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(configController, animated: true)
            } else if (menu.title == GlobalConstants.LeftPaneMenu.CONFIGURE_TV) {
                self.navigationController?.navigationBar.topItem?.title = ""
                let configController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chooseTVViewController")
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(configController, animated: true)
            } else if (menu.title == GlobalConstants.LeftPaneMenu.GET_UNO) {                
                self.navigationController?.navigationBar.topItem?.title = ""
                let getUnoController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "getbubbleuno")
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(getUnoController, animated: true)
            } else if (menu.title == GlobalConstants.LeftPaneMenu.TALK_TO_US) {
                self.navigationController?.navigationBar.topItem?.title = ""
                let contactUsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "talktous")
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(contactUsController, animated: true)
            } else if (menu.title == GlobalConstants.LeftPaneMenu.LOGOUT) {
                let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout from Bubble?", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Logout", style: .default) { [weak self]
                    (_)-> Void in
                    
                    guard let selfhomemain = self else {
                        return
                    }
                    let logoutObject = LogoutObject(rootVC: selfhomemain, containerVC: selfhomemain.parent?.parent as! ContainerViewController)
                    logoutObject.logoutApplication()
                }
                alert.addAction(settingsAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)                
            } else if (menu.title == GlobalConstants.LeftPaneMenu.ABOUT_US) {
                self.navigationController?.navigationBar.topItem?.title = ""
                let aboutUsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "aboutus")
                //self.present(configController, animated: true)
                self.navigationController?.pushViewController(aboutUsController, animated: true)
            }
            
        }
    }
}
