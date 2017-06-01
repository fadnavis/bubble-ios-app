//
//  LoginViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/7/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit

class LoginViewController: UIViewController, BubbleAPIDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    var userEmail: NSString?
    var userFirstName: NSString?
    var userLastName: NSString?
    var fbID: NSString?
    var gID: NSString?
    let bubbleAPI: CallBubbleApi  = CallBubbleApi()
    var appDelegate: AppDelegate?
    //var moc: NSManagedObjectContext!
    let fbLoginManager : FBSDKLoginManager = FBSDKLoginManager()
    @IBOutlet weak var loadingView: UIActivityIndicatorView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bubbleAPI.delegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().clientID = GlobalConstants.SocialMediaIds.GOOGLE_CLIENT_ID


        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        //self.moc = appDelegate.dataStoreController.managedObjectContext
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func TandC(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.openURL(URL(string: GlobalConstants.BubbleAPI.BUBBLE_TANDC)!)
    }
    
    
    @IBAction func privacyPolicy(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.openURL(URL(string: GlobalConstants.BubbleAPI.BUBBLE_PRIVACY)!)
    }
    
    @IBAction func loginToFacebook(_ sender: UITapGestureRecognizer) {
        
//        //save data locally
//        let userDefaults = NSUserDefaults.standardUserDefaults()
//        //userDefaults.setObject(self.userEmail!, forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
//        userDefaults.setObject("harsh.fad@gmail.com", forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
//        
//        //now login to Bubble server
//        var params: [String: String] = [:]
//        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_LOGIN
//        params["emailid"] = /*self.userEmail*/"harsh.fad@gmail.com"
//        self.bubbleAPI.post(params)
        
        let permisions = ["public_profile", "email"]
        fbLoginManager.loginBehavior = FBSDKLoginBehavior.systemAccount
        fbLoginManager.logIn(withReadPermissions: permisions, from: self) {
            (results,error) -> Void in
            if let err = error {
                self.logoutFacebook()
            } else {
            //fetch data
                if(FBSDKAccessToken.current() != nil) {
                    let parameters = ["fields": "id, email, first_name, last_name, picture.type(large)"]
                    FBSDKGraphRequest(graphPath: "me", parameters: parameters).start (completionHandler: { [unowned self]
                        (connection, userresult, error) -> Void in
                        if let er = error {
                        } else {
                            let userresult = userresult as! [NSString: AnyObject]
                            if let uemail = userresult["email"]  as? NSString {
                                self.userEmail = uemail
                            }
                            if let ufname = userresult["first_name"] as? NSString {
                                self.userFirstName = ufname
                            }
                            if let ulname = userresult["last_name"] as? NSString {
                                self.userLastName = ulname
                            }
                            
                            if let ufbid = userresult["id"] as? NSString {
                                self.fbID = ufbid
                            }
                            
                            let userDefaults = UserDefaults.standard
                            userDefaults.set(self.userEmail!, forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
                            //userDefaults.setObject("harsh.fad@gmail.com", forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
                            userDefaults.set(self.fbID, forKey: GlobalConstants.UserDefaults.USER_FACEBOOK_ID)
                            userDefaults.set("", forKey: GlobalConstants.UserDefaults.USER_GOOGLE_ID)
                            userDefaults.set(self.userFirstName, forKey: GlobalConstants.UserDefaults.USER_NAME)
                            
                            //now login to Bubble server
                            var params: [String: String] = [:]
                            params["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_LOGIN
                            params["emailid"] = self.userEmail as String!
                            self.bubbleAPI.delegate = self
                            self.bubbleAPI.post(params)
                            self.loadingView.startAnimating()
                        }
                        
                    })
                }
                //save data locally
                
            }
            
//            let bubbleDateFormat = NSDateFormatter()
//            bubbleDateFormat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT
//            let currenttime = bubbleDateFormat.stringFromDate(NSDate())
//            params["curtime"] = currenttime
//            params["language"] = "English"
        
         }
    }
    
    
    @IBAction func loginToGoogle(_ sender: UITapGestureRecognizer) {
        if(GIDSignIn.sharedInstance() == nil) {
        } else {
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
//    func sign(inWillDispatch signIn: GIDSignIn!, error: NSError!) {
//        
//    }
    
//    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
//        self.present(viewController, animated: true, completion: nil)
//    }
//    
//    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
//        self.dismiss(animated: true, completion: nil)
//    }
    
    
    public func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            // Perform any operations on signed in user here.
            self.userEmail = user.profile.email as NSString?
            self.userFirstName = user.profile.givenName as NSString?
            self.userLastName = user.profile.familyName as NSString?
            self.gID = user.userID as NSString?
//            let userId = user.userID                  // For client-side use only!
//            let idToken = user.authentication.idToken // Safe to send to the server
//            let fullName = user.profile.name
//            let givenName = user.profile.givenName
//            let familyName = user.profile.familyName
//            let email = user.profile.email
            let userDefaults = UserDefaults.standard
            userDefaults.set(self.userEmail!, forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY)
            userDefaults.set(self.gID, forKey: GlobalConstants.UserDefaults.USER_GOOGLE_ID)
            userDefaults.set("", forKey: GlobalConstants.UserDefaults.USER_FACEBOOK_ID)
            userDefaults.set(self.userFirstName, forKey: GlobalConstants.UserDefaults.USER_NAME)
            
            //now login to Bubble server
            var params: [String: String] = [:]
            params["method"] = GlobalConstants.HttpMethodName.BUBBLE_API_LOGIN
            params["emailid"] = self.userEmail as String!
            self.bubbleAPI.delegate = self
            self.bubbleAPI.post(params)
            loadingView.startAnimating()
            
        } else {
            logoutGoogle()
        }

    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        
        guard let status = responseJSON["status"] as? Int else {
            loadingView.stopAnimating()
            logout()
            return
        }
        
        if(methodName == GlobalConstants.HttpMethodName.BUBBLE_API_LOGIN) {
            if(status == GlobalConstants.BubbleAPIStatus.STATUS_ERROR) {
                loadingView.stopAnimating()
                logout()
            } else {
                loadingView.stopAnimating()
                let stb = responseJSON["stbname"] as? String
                let isHd = responseJSON["is_hd"] as? String
                if(stb != nil) {
                    //save STB name in local
                    let defaults = UserDefaults.standard
                    defaults.set(stb, forKey: GlobalConstants.UserDefaults.USER_STB_KEY)
                    defaults.set(isHd, forKey: GlobalConstants.UserDefaults.USER_IS_HD_KEY)
                    //save STB codes to Entity
                    deleteAllSTBCodes()
                    saveRemoteCodesToEntity(responseJSON)
                    
                    //go to home page straight away
                    if let _ = defaults.object(forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER) {
                        //do something here then go to home page
                        goToHomePage()
                    } else {
                        goToSetupBubbleUnoPage()
                    }
                    //goToChooseSTBPage()
                } else {
                    //go to choose STB page
                    goToChooseSTBPage()
                }
                
            }
        }
    }
    
    func onNetworkError(methodName: String) {
        logout()
        loadingView.stopAnimating()
    }
    
    private func deleteUserDefaults() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
    }
    
    func deleteAllSTBCodes() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                return
            }
            let requestSTBCodes = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
            
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
                    entity.setValue(data[2], forKey: "hexcode")
                    entity.setValue(data[3], forKey: "bits")
                    entity.setValue(data[4], forKey: "rawcode")
                    entity.setValue(data[5], forKey: "rawlength")
                    entity.setValue(data[6], forKey: "frequency")
                }
            }
            
            if let othercodeslist = json["usercodes"] as? NSArray {
                for othercodes in othercodeslist {
                    let entity = NSEntityDescription.insertNewObject(forEntityName: "STBCodes", into: context)
                    if let data = othercodes as? [String] {
                        entity.setValue(data[0], forKey: "medium")
                        entity.setValue(data[1], forKey: "remoteNumber")
                        entity.setValue(data[2], forKey: "protocol")
                        entity.setValue(data[3], forKey: "hexcode")
                        entity.setValue(data[4], forKey: "bits")
                        entity.setValue(data[5], forKey: "rawcode")
                        entity.setValue(data[6], forKey: "rawlength")
                        entity.setValue(data[7], forKey: "frequency")
                    }
                }
            }
            do {
                try context.save()
            } catch {
                fatalError("error saving stb codes to entity")
            }
        }
        
    }
    
    func logout() {
        logoutFacebook()
        logoutGoogle()
        deleteUserDefaults()
        deleteAllSTBCodes()
    }
    
    func logoutFacebook() {
        fbLoginManager.logOut()
    }
    
    func logoutGoogle() {
        GIDSignIn.sharedInstance().signOut()
    }
    
    func goToHomePage() {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as UIViewController
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToChooseSTBPage() {
        let viewContoller: UIViewController = UIStoryboard(name: "ChooseSTB", bundle: nil).instantiateViewController(withIdentifier: "stbNavigationScene")
        
        self.present(viewContoller, animated: true, completion: nil)
    }
    
    func goToSetupBubbleUnoPage() {
        let viewContoller: UIViewController = UIStoryboard(name: "WelcomeBubbleUno", bundle: nil).instantiateViewController(withIdentifier: "welcomeBubbleUno")
        
        self.present(viewContoller, animated: true, completion: nil)
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
