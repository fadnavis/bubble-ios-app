//
//  Logout.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/27/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import Foundation
import CoreData

class LogoutObject {
    var coredataDeleted = false
    var rootViewController: HomeMainViewController!
    var containerController: ContainerViewController?
    
    init(rootVC: HomeMainViewController, containerVC : ContainerViewController) {
        self.rootViewController = rootVC
        self.containerController = containerVC
    }
    
    func logoutApplication() {
        deleteCoreData()
    }
    
    func deleteEverythingElse() {
        deleteUserDefaults()
        logoutSocialMedia()
        killTimersAndTasks()
        removeViewControllers()
        goToLoginPage()
    }
    
    private func goToLoginPage() {
        let viewController:UIViewController = UIStoryboard(name: "LoginScene", bundle: nil).instantiateViewController(withIdentifier: "loginScene") as UIViewController
        
        containerController?.present(viewController, animated: true, completion: nil)
    }
    
    private func killTimersAndTasks() {
        for vc in rootViewController.controllerArray {
            vc.invalidateTimer()
            vc.fetchPrograms.cancelURLTask()
        }
    }
    
    private func removeViewControllers() {
        containerController?.removeLeftPanelViewController()
        containerController?.removeRightPaneLViewController()
        containerController?.removeCenterViewController()
    }
    
    private func showFailAlert() {
        let alert = UIAlertController(title: "Cannot logout", message: "Cannot logout of Bubble. Some error ocurred. Try again or contact us right away", preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        rootViewController.present(alert, animated: true, completion: nil)
    }
    
    private func deleteCoreData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                DispatchQueue.main.async {
                    self.showFailAlert()
                }
                return
            }
            let requestNow = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNow")
            let requestNext = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsNext")
            let requestLater = NSFetchRequest<NSFetchRequestResult>(entityName: "ProgramsLater")
            let requestHDMap = NSFetchRequest<NSFetchRequestResult>(entityName: "HDMap")
            let channelDataRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChannelData")
            let stbCodesRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
            
            let batchDeleteNow = NSBatchDeleteRequest(fetchRequest: requestNow)
            let batchDeleteNext = NSBatchDeleteRequest(fetchRequest: requestNext)
            let batchDeleteLater = NSBatchDeleteRequest(fetchRequest: requestLater)
            let batchDeleteHDMap = NSBatchDeleteRequest(fetchRequest: requestHDMap)
            let batchDeleteChannelData = NSBatchDeleteRequest(fetchRequest: channelDataRequest)
            let batchDeleteSTB = NSBatchDeleteRequest(fetchRequest: stbCodesRequest)
            
            do {
                try context.execute(batchDeleteNow)
                try context.execute(batchDeleteNext)
                try context.execute(batchDeleteLater)
                try context.execute(batchDeleteHDMap)
                try context.execute(batchDeleteChannelData)
                try context.execute(batchDeleteSTB)
                
            } catch {
                DispatchQueue.main.async {
                    self.showFailAlert()
                }
            }
            
            DispatchQueue.main.async {
                //self?.deleteEverythingElse()
                
                UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                UserDefaults.standard.synchronize()
                
                let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
                fbLoginManager.logOut()
                
                for vc in (self.rootViewController.controllerArray) {
//                    if let fp = vc.fetchPrograms {
//                        
//                    }
                    vc.invalidateTimer()
                    vc.fetchPrograms.cancelURLTask()
                }
                
                self.containerController?.removeLeftPanelViewController()
                self.containerController?.removeRightPaneLViewController()
                self.containerController?.removeCenterViewController()
                
                let viewController:UIViewController = UIStoryboard(name: "LoginScene", bundle: nil).instantiateViewController(withIdentifier: "loginScene") as UIViewController
                
                self.containerController?.present(viewController, animated: true, completion: nil)
                
                let app = UIApplication.shared
                for notification in app.scheduledLocalNotifications! {
                    app.cancelLocalNotification(notification)                    
                }
            }
        }
    }
    
    private func deleteUserDefaults() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
    
    private func logoutSocialMedia() {
        let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
        fbLoginManager.logOut()
        
        //logout Google
        GIDSignIn.sharedInstance().signOut()
    }
}
