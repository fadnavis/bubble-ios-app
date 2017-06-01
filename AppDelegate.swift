//
//  AppDelegate.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/1/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //var dataController: DataController!
    var dataStoreController: DataStoreController!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //dataController = DataController()
        
        let libraryDirectoryUrl = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let storeUrl = libraryDirectoryUrl.appendingPathComponent("Bubble")
        
        guard let modelUrl = Bundle.main.url(forResource: "Bubble", withExtension: "momd") else {
            fatalError("Error loading Core Data model")
        }
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.BubbleOffWhite2(), NSFontAttributeName: UIFont(name: "Quicksand-Regular", size: 15)!], for: .normal)
        
        dataStoreController = DataStoreController(modelUrl: modelUrl, storeUrl: storeUrl)
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        GIDSignIn.sharedInstance().clientID = GlobalConstants.SocialMediaIds.GOOGLE_CLIENT_ID
        
        if let _ = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY) as? String {
            if (FBSDKAccessToken.current() == nil) {
                if GIDSignIn.sharedInstance().hasAuthInKeychain() {
                    GIDSignIn.sharedInstance().signInSilently()
                }
            }
        }
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        if let options = launchOptions {
            if let localNotification = options[UIApplicationLaunchOptionsKey.localNotification] as? UILocalNotification {
                if let userinfocontent = localNotification.userInfo as? [String: String] {
                    let channelId = userinfocontent["channelId"]
                    let channelName = userinfocontent["channelName"]
                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as! ContainerViewController
                    viewController.channelIdFromNotification = channelId!
                    viewController.channelNameFromNotification = channelName!
                    self.window?.rootViewController = viewController
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return ( FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation) ||
            GIDSignIn.sharedInstance().handle(url,
                sourceApplication: sourceApplication,
                annotation: annotation))
    }

    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        if(recentChannels.count > 0) {
            let defaults = UserDefaults.standard
            defaults.set(recentChannels, forKey: GlobalConstants.UserDefaults.RECENT_CHANNEL_ID)
            defaults.set(recentChannelNumbers, forKey: GlobalConstants.UserDefaults.RECENT_CHANNEL_NUMS)
        }
        
//        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys().ApplicationWillResignActive), object: self, userInfo: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: Notification.Name(NotificationKeys().ApplicationDidEnterBackground), object: self, userInfo: nil)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        let defaults = UserDefaults.standard
        if let recentchans = defaults.value(forKey: GlobalConstants.UserDefaults.RECENT_CHANNEL_ID) as? Array<String> {
            recentChannels = recentchans
        } 
        if let recentchannums = defaults.value(forKey: GlobalConstants.UserDefaults.RECENT_CHANNEL_NUMS) as? Array<String> {
            recentChannelNumbers = recentchannums
        }
        NotificationCenter.default.post(name: Notification.Name(NotificationKeys().ApplicationWillEnterForeground), object: self, userInfo: nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        if let userinfocontent = notification.userInfo as? [String: String] {
            let channelId = userinfocontent["channelId"]
            let channelName = userinfocontent["channelName"]
            let programName = userinfocontent["programName"]
            if ( application.applicationState == UIApplicationState.active) {
                
                // App is foreground and notification is recieved,
                // Show a alert.
                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys().programReminderNotificationKeyActive), object: self, userInfo: ["channelId": channelId!,"channelName": channelName!, "programName": programName ?? ""])
                
            }
            else if( application.applicationState == UIApplicationState.background) {
                // App is in background and notification is received,
                // You can fetch required data here don't do anything with UI.
            }
            else if( application.applicationState == UIApplicationState.inactive) {
                // App came in foreground by used clicking on notification,
                // Use userinfo for redirecting to specific view controller.
//                if let vc = window?.rootViewController as? ContainerViewController {
//                    if let homemain = vc.homeMainViewController {
//                        homemain.channelIdFromNotification = channelId!
//                        homemain.channelNameFromNotification = channelName!
//                    }
//                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationKeys().programReminderNotificationKeyInactive), object: self, userInfo: ["channelId": channelId!,"channelName": channelName!])
                
            }
        }
    }
    
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        
        if identifier == "watchnowbubble" {
//            if let userinfocontent = notification.userInfo as? [String: String] {
//                let channelId = userinfocontent["channelId"]
//                let channelName = userinfocontent["channelName"]
//                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as! ContainerViewController
//                viewController.channelIdFromNotification = channelId!
//                viewController.channelNameFromNotification = channelName!
//                self.window?.rootViewController = viewController
//            }
        }
        
        completionHandler()
    }
    
    func goToHomePage() {
        
    }
    
}

