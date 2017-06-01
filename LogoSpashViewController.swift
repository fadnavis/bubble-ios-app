//
//  LogoSpashViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/6/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class LogoSpashViewController: UIViewController, BubbleAPIDelegate {

    var useremail: String?
    var buildversion: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        buildversion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        useremail = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY) as? String
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        if let version = buildversion {
            defaults.set(version, forKey: GlobalConstants.UserDefaults.CURRENT_VERSION)
            //checkVersionUpdate(current: version)
            if let _ = defaults.object(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) {
                //do all the initialization before going to home page
                goToHomePage()
            } else {
                goToChooseSTBPage()
            }
//            if useremail == nil {
//                goToChooseSTBPage()
////                if let _ = defaults.object(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) {
////                    //do all the initialization before going to home page
////                    goToHomePage()
////                } else {
////                    goToChooseSTBPage()
////                }
//            } else {
//                checkVersionUpdate(current: version)
//            }
        } else {
            if let _ = defaults.object(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) {
                //do all the initialization before going to home page
                goToHomePage()
            } else {
                goToChooseSTBPage()
            }
        }
    }
    
    func checkVersionUpdate(current: String) {
        var params :  [String: String] = [:]
        let bubbleApi = CallBubbleApi()
        bubbleApi.delegate = self
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_VERIFY_VERSION
        params["emailid"] = useremail
        params["platform"] = "IOS"
        params["currentversion"] = current
        bubbleApi.post(params)
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                if let latestversion = responseJSON["version"] as? String, let ismandatory = responseJSON["isupdaterequired"] as? String {
                    if let version = buildversion {
                        if latestversion == version {
                            proceedWithoutVerification()
                        } else {
                            proceedToAppUpdate(force: ismandatory == "1" ? true:false)
                        }
                    } else {
                        proceedWithoutVerification()
                    }
                }
            } else {
                proceedWithoutVerification()
            }
        } else {
            proceedWithoutVerification()
        }
    }
    
    func onNetworkError(methodName: String) {
        proceedWithoutVerification()
    }
    
    func proceedWithoutVerification() {
        if let _ = UserDefaults.standard.object(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) {
            //do all the initialization before going to home page
            goToHomePage()
        } else {
            goToChooseSTBPage()
        }
    }
    
    func proceedToAppUpdate(force: Bool) {
        let viewController:VersionUpdateViewController = UIStoryboard(name: "VersionUpdate", bundle: nil).instantiateViewController(withIdentifier: "versionupdate") as! VersionUpdateViewController
        viewController.isForced = force        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToLoginPage() {
        let viewController:UIViewController = UIStoryboard(name: "LoginScene", bundle: nil).instantiateViewController(withIdentifier: "loginScene") as UIViewController
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToHomePage() {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as UIViewController
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToChooseSTBPage() {
        let viewContoller: UIViewController = UIStoryboard(name: "ChooseSTB", bundle: nil).instantiateViewController(withIdentifier: "stbNavigationScene")
        
        self.present(viewContoller, animated: true, completion: nil)
    }
    
    func isUserLoggedIn() -> Bool {
        let defaults = UserDefaults.standard
        guard let userEmail = defaults.object(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY) as? String else {
            return false
        }
        if let _ = FBSDKAccessToken.current() {
            if(userEmail != "") {
                return true
            } else {
                return false
            }
        } else {
            if(GIDSignIn.sharedInstance().hasAuthInKeychain()) {
                if(userEmail != "") {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
