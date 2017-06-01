//
//  ChooseSTB.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/8/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData

class ChooseSTB: UIViewController, UITableViewDataSource, UITableViewDelegate, BubbleAPIDelegate {
    
    var stbcodemap: [Int : String] = Dictionary<Int, String>()
    var stbnamemap: [Int: String] = Dictionary<Int, String>()
    var userEmail: String?
    var userSTB: String?
    var isFirstLaunch: Bool?
    var isHDString: String!
    var homeMainInstance : HomeMainViewController?
    
    @IBOutlet weak var hdSwitch: UISwitch!
    @IBOutlet weak var stbTableView: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stbTableView.register(UITableViewCell.self, forCellReuseIdentifier: "stbnames")
        stbTableView.delegate = self
        stbTableView.dataSource = self
        hdSwitch.addTarget(self, action: #selector(ChooseSTB.hdSwitchChanged(switchState:)), for: UIControlEvents.valueChanged)

        fetchAllOperators()
        readuserDefaults()
        //request stb names from server
    }
    
    func hdSwitchChanged(switchState: UISwitch) {
        if switchState.isOn {
            isHDString = "1"
        } else {
            isHDString = "0"
        }
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if(methodName == GlobalConstants.HttpMethodName.BUBBLE_API_ALL_OPERATORS) {
            guard let status = responseJSON["status"] as? Int else {
                return
            }
            if(status == GlobalConstants.BubbleAPIStatus.STATUS_ERROR) {
            } else {
                guard let stbnames = responseJSON["operator"] as? [String: String] else {
                    return
                }
                var i = 0
                for (key,value) in (Array(stbnames).sorted{$0.1<$1.1}) {
                    stbcodemap[i] = key
                    stbnamemap[i] = value
                    i += 1
                }
//                for (key,value) in stbnames {
//                    stbcodemap[i] = key
//                    stbnamemap[i] = value
//                    i += 1
//                }
                
                stbTableView.reloadData()
                setViews()
            }
        } else if (methodName == GlobalConstants.HttpMethodName.BUBBLE_API_SET_USER_STB) {
            guard let status = responseJSON["status"] as? Int else {
                return
            }
            if(status == GlobalConstants.BubbleAPIStatus.STATUS_ERROR) {
            } else {
                //user stb has been set, now move on 
                UserDefaults.standard.set(userSTB!, forKey: GlobalConstants.UserDefaults.USER_STB_KEY)
                UserDefaults.standard.set(isHDString, forKey: GlobalConstants.UserDefaults.USER_IS_HD_KEY)
                let sharedData = UserData.sharedInstance
                sharedData.isHD = (isHDString == "1") ? true: false
                deleteAllSTBCodes()
                saveRemoteCodesToEntity(responseJSON)
                if let first = isFirstLaunch {
                    if(first == true) {
                        // go to set up Bubble Uno Scene (should never enter here, just for readability)
                    } else {
                        //go to home page
                        if let hmv = homeMainInstance {
                            hmv.deleteAllProgramData()
                            hmv.resetPageMenu()
                        }
                        goToHomePage()
                    }
                } else {
                    // go to set up Bubble Uno Scene (BUT GOING TO HOME PAGE FOR NOW)
                    //goToHomePage()
                    goToSetupPage()
                }
            }
        } else if(methodName == GlobalConstants.HttpMethodName.BUBBLE_API_SIGN_UP) {
            guard let status = responseJSON["status"] as? Int else {
                return
            }
            if(status == GlobalConstants.BubbleAPIStatus.STATUS_OK) {
                if let uniqueCustomerId = responseJSON["emailid"] as? String {
                    UserDefaults.standard.set(uniqueCustomerId, forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
                    UserDefaults.standard.set(userSTB!, forKey: GlobalConstants.UserDefaults.USER_STB_KEY)
                    UserDefaults.standard.set(isHDString, forKey: GlobalConstants.UserDefaults.USER_IS_HD_KEY)
                    let sharedData = UserData.sharedInstance
                    sharedData.userEmail = uniqueCustomerId
                    sharedData.isHD = (isHDString == "1") ? true: false
                    saveRemoteCodesToEntity(responseJSON)
                    
                    goToSetupPage()
                    
                }
            }
        }
    }
    
    
    func onNetworkError(methodName: String) {
        let alert = UIAlertController(title: "Connectivity Issue", message: "Are you connected to the internet? Try again", preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) {
            (_) -> Void in
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func deleteAllSTBCodes() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                return
            }
            let requestSTBCodes = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
            let mediumPredicate = NSPredicate(format: "medium = %@", argumentArray: ["STB"])
            requestSTBCodes.predicate = mediumPredicate
            
            let batchDeleteSTBCodes = NSBatchDeleteRequest(fetchRequest: requestSTBCodes)
            
            do {
                try context.execute(batchDeleteSTBCodes)
            } catch {
                fatalError()
            }
        }
    }
    
    func saveRemoteCodesToEntity(_ json: [String: AnyObject]) {
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (stbnamemap.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stbnames")
        cell!.textLabel?.text = stbnamemap[(indexPath as NSIndexPath).row] as String?
        cell!.textLabel?.font = UIFont(name: "Quicksand-Regular", size: 17.0)
        return cell!
    }
    
    func readuserDefaults() {
        let defaults = UserDefaults.standard
        userEmail = defaults.object(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY) as? String
        userSTB = defaults.object(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) as? String
        isFirstLaunch = defaults.object(forKey: GlobalConstants.UserDefaults.USER_IS_FIRST_LAUNCH) as? Bool
        isHDString = defaults.value(forKey: GlobalConstants.UserDefaults.USER_IS_HD_KEY) as? String ?? "1"
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        if(userSTB == nil) {
            self.navigationController?.navigationBar.topItem?.title = "Choose your DTH"
            self.navigationController?.navigationBar.titleTextAttributes = [
                NSForegroundColorAttributeName: UIColor.BubbleOffWhite2(),
                NSFontAttributeName: UIFont(name: "Quicksand-Bold", size: 19)!
            ]
            self.navigationController?.navigationBar.barTintColor = UIColor.init(rgb: 0x111125)
            
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.barStyle = UIBarStyle.black
            self.navigationController?.navigationBar.tintColor = UIColor.white
            doneButton.isEnabled = false
        }
    }
    
    func fetchAllOperators() {
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_ALL_OPERATORS
        let apiCall = CallBubbleApi()
        apiCall.delegate = self
        apiCall.post(params)
    }
    
    func setViews() {
        if(userSTB == nil) {
            doneButton.isEnabled = false
            hdSwitch.setOn(true, animated: false)
            hdSwitch.isHidden = false
        } else {
            doneButton.isEnabled = true
            let i = stbcodemap.filter {
                return $0.1 == userSTB!
                //return $0.1.contains(userSTB!)
                }.map {
                    return $0.0
                }[0]
            
            let rowToSelect : IndexPath = IndexPath(row: i, section: 0)
            stbTableView.selectRow(at: rowToSelect, animated: true, scrollPosition: UITableViewScrollPosition.none)
            self.tableView(stbTableView, didSelectRowAt: rowToSelect)
            if (isHDString == "1") {
                hdSwitch.setOn(true, animated: false)
            } else {
                hdSwitch.setOn(false, animated: false)
            }
            hdSwitch.isHidden = false
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        userSTB = stbcodemap[(indexPath as NSIndexPath).row]! as String
        if (userSTB == "VIDEOCON_D2H") {
            showVideoconAlert()
        }
        doneButton.isEnabled = true
    }
    
    func showVideoconAlert() {
        let alert = UIAlertController(title: "Videocon d2h", message: "Bubble Uno is only supported for IR based remotes and does not support RF based models of your Videocon D2H set-top box.\n\nGenerally all non-HD and latest HD Videocon D2H models are IR based. If you are not sure about your set-top box model, please contact your operator or write to us at support@bubble.uno", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func goToHomePage() {
        if self.navigationController == nil {
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as UIViewController
            
            self.present(viewController, animated: true, completion: nil)
        } else {
            self.navigationController!.popViewController(animated: true)
        }
    }
    
    func goToSetupPage() {
        let viewContoller: UIViewController = UIStoryboard(name: "WelcomeBubbleUno", bundle: nil).instantiateViewController(withIdentifier: "welcomeBubbleUno")
        
        self.present(viewContoller, animated: true, completion: nil)
    }
    
    @IBAction func onDoneClicked(_ sender: UIButton) {
        if UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) == nil {
            signUpNewUser()
        } else {
            saveUserSTBToServer()
        }
    }
    
    func signUpNewUser() {
        if let stb = userSTB {
            var params: [String: String] = [:]
            params["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_SIGN_UP
            params["stbname"] = stb
            params["is_hd"] = isHDString
            params["platform"] = "iOS"
            params["platformversion"] = UIDevice.current.systemVersion
            params["devicemodelname"] = UIDevice.current.model
            let bubbleAPI = CallBubbleApi()
            bubbleAPI.delegate = self
            bubbleAPI.post(params)
        }
    }
    
    func saveUserSTBToServer() {
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_SET_USER_STB
        params["emailid"] = userEmail!
        params["stbname"] = userSTB!
        params["is_hd"] = isHDString
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        bubbleAPI.post(params)
    }
}
