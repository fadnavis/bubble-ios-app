//
//  NextProgramsTableViewCell.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/15/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class NextProgramsTableViewCell: UITableViewCell, BubbleAPIDelegate {

    @IBOutlet weak var reminder: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var genre: UILabel!
    
    var reminderTime = Date()
    var programId: String!
    var channelId: String!
    var isReminderSet = false
    var programName: String!
    var channelName: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let reminderGesture = UITapGestureRecognizer(target: self, action: #selector(toggleReminder(recognizer:)))
        reminder.addGestureRecognizer(reminderGesture)
        reminder.isUserInteractionEnabled = true
    }
    
    func setTime(reminderTime: Date) {
        self.reminderTime = reminderTime
    }
    
    func setProgramInfo(progId: String, progName: String) {
        self.programId = progId
        self.programName = progName
    }
    
    func setChannelInfo(chanId: String, chanName: String) {
        self.channelId = chanId
        self.channelName = chanName
    }
    
    func setIsReminderSet() {
        self.isReminderSet = self.foundInLocalNotifications() ? true: false
    }
    
    func setClockView() {
        if self.isReminderSet == true {
            self.reminder.image = UIImage(named: "reminderSet")
        } else {
            self.reminder.image = UIImage(named: "reminder")
        }
    }

    func logEventOnServer() {
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_EVENT_LOG
        params["email_id"] = UserData.sharedInstance.userEmail
        params["event"] = "Reminder"
        params["label"] = ""
        params["channelid"] = self.channelId
        params["programid"] = self.programId
        params["source"] = "iOSSynopsisPage"
        params["macid"] = UserData.sharedInstance.bubbleMAC
        bubbleAPI.post(params)
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        //do nothing
    }
    
    func onNetworkError(methodName: String) {
        //do nothing
    }
    
    func setupNotificationSettings() -> Bool {
        let notificationSettings: UIUserNotificationSettings! = UIApplication.shared.currentUserNotificationSettings
        
        if (!notificationSettings.types.contains(.alert)) {
            // Specify the notification types.
            let notificationTypes: UIUserNotificationType = [.alert, .sound]
            
            // Specify the notification actions.
            let watchNowAction = UIMutableUserNotificationAction()
            watchNowAction.identifier = "watchnowbubble"
            watchNowAction.title = "Watch Now"
            watchNowAction.activationMode = UIUserNotificationActivationMode.foreground
            watchNowAction.isDestructive = false
            watchNowAction.isAuthenticationRequired = false
            
            let _ = NSArray(objects: watchNowAction)
            let _ = NSArray(objects: watchNowAction)
            
            // Specify the category related to the above actions.
            let watchNowReminderCategory = UIMutableUserNotificationCategory()
            watchNowReminderCategory.identifier = "ProgramReminderBubble"
//            watchNowReminderCategory.setActions(actionsArray as? [UIUserNotificationAction], for: UIUserNotificationActionContext.default)
//            watchNowReminderCategory.setActions(actionsArrayMinimal as?[UIUserNotificationAction], for: UIUserNotificationActionContext.minimal)
            
            
            let categoriesForSettings = NSSet(objects: watchNowReminderCategory)
            
            
            // Register the notification settings.
//            let newNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: categoriesForSettings)
            let newNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings as! Set<UIUserNotificationCategory>)
            UIApplication.shared.registerUserNotificationSettings(newNotificationSettings)
            return false
        }
        return true
    }

    
    
    func setReminder() {
        if(setupNotificationSettings()) {
            let isRegisteredForLocalNotifications = UIApplication.shared.currentUserNotificationSettings?.types.contains(UIUserNotificationType.alert) ?? false
            if isRegisteredForLocalNotifications == true {
                
                let localNotification = UILocalNotification()
                localNotification.fireDate = self.reminderTime
//                let calendar = Calendar.current
//                localNotification.fireDate = calendar.date(byAdding: .second, value: 60, to: Date())
                
                localNotification.alertBody = String("\(self.programName!)" + " starting now on " + "\(self.channelName!)")
                localNotification.alertAction = "ACtion"
                localNotification.category = "ProgramReminderBubble"
                let uid: String = self.programId + self.channelId + self.time.text!
                localNotification.userInfo = ["uid" : uid,"channelId" : self.channelId, "channelName" : self.channelName, "programName": self.programName]
                UIApplication.shared.scheduleLocalNotification(localNotification)
                self.reminder.image = UIImage(named: "reminderSet")
                self.isReminderSet = true
                logEventOnServer()
            } else {
                let alert = UIAlertController(title: "Allow Notifications", message: "Bubble needs permission to send notifications. Go to settings page and turn on notifications for Bubble", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Settings", style: .default) {
                    (_)-> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                if success == false {
                                    //tell user needs to open settings on his own
                                }
                            })
                        } else {
                            // Fallback on earlier versions
                            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                            if let url = settingsUrl {
                                UIApplication.shared.openURL(url as URL)
                            }
                        }
                    }
                }
                alert.addAction(settingsAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alert.addAction(cancelAction)
                if let tv = self.superview?.superview as? UITableView {
                    if let vc = tv.dataSource as? UIViewController {
                        vc.present(alert, animated: true, completion: nil)
                    }
                }
            }
        } else {
            if let _ = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.FIRST_NOTIFICATION) as? Bool {
                let alert = UIAlertController(title: "Allow Notifications", message: "Bubble needs permission to send notifications. Go to settings page and turn on notifications for Bubble", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Settings", style: .default) {
                    (_)-> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                if success == false {
                                    //tell user needs to open settings on his own
                                }
                            })
                        } else {
                            // Fallback on earlier versions
                            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                            if let url = settingsUrl {
                                UIApplication.shared.openURL(url as URL)
                            }
                        }
                    }
                }
                alert.addAction(settingsAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alert.addAction(cancelAction)
                if let tv = self.superview?.superview as? UITableView {
                    if let vc = tv.dataSource as? UIViewController {
                        vc.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                UserDefaults.standard.set(false, forKey: GlobalConstants.UserDefaults.FIRST_NOTIFICATION)
            }
        }
    }
    
    func foundInLocalNotifications() -> Bool {
        let app = UIApplication.shared
        for notification in app.scheduledLocalNotifications! {
            if let userinfoContent = notification.userInfo! as? [String: String] {
                let uid = userinfoContent["uid"]
                if uid == String(self.programId+self.channelId+self.time.text!) {
                    return true
                }
            }
        }
        return false
    }
    
    func removeReminder() {
        let app = UIApplication.shared
        for notification in app.scheduledLocalNotifications! {
            if let userinfoContent = notification.userInfo! as? [String: String] {
                let uid = userinfoContent["uid"]
                if uid == String(self.programId+self.channelId+self.time.text!) {
                    app.cancelLocalNotification(notification)
                    self.reminder.image = UIImage(named: "reminder")
                    self.isReminderSet = false
                }
            }
        }
    }
    
    func toggleReminder(recognizer: UITapGestureRecognizer) {
        if(self.isReminderSet == false) {
            self.setReminder()
        } else {
            self.removeReminder()
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
