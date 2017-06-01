//
//  AboutUsViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 11/24/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class AboutUsViewController: UIViewController {

    
    @IBOutlet weak var versionText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "About Us"
        if let buildversion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            if let userid = UserData.sharedInstance.userEmail {
                let lastsix = userid.substring(from: userid.index(userid.endIndex, offsetBy: -6))
                versionText.text = "Version: \(buildversion)(\(lastsix.uppercased()))"
            } else {
                versionText.text = "Version: \(buildversion)"
            }
            
        } else {
            versionText.text = ""
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func rateUs(_ sender: UITapGestureRecognizer) {
        let appStoreAppID = GlobalConstants.SocialMediaIds.appstoreId
        let url = URL(string: "itms://itunes.apple.com/app/id" + appStoreAppID)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(URL(string: GlobalConstants.SocialMediaIds.ITUNES_LINK)!,options: [:], completionHandler: nil)
        }
    }
    
    
    @IBAction func rateUsAmazon(_ sender: UITapGestureRecognizer) {
        //TODO
        UIApplication.shared.open(URL(string: GlobalConstants.SocialMediaIds.AMAZON_RATE_PRODUCT)!, options: [:], completionHandler: nil)
    }
    
    
    @IBAction func likeUs(_ sender: UITapGestureRecognizer) {
        let fbId = "bubbleuno"
        var url = URL(string:"fb://profile/\(fbId)")!
        if UIApplication.shared.canOpenURL(url)  {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            url = URL(string:GlobalConstants.SocialMediaIds.FACEBOOK_PAGE)!
            UIApplication.shared.open(url,options: [:], completionHandler: nil)
        }
    }
    
    
    @IBAction func privacy(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.open(URL(string: GlobalConstants.SocialMediaIds.PRIVACY_POLICY)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func tandc(_ sender: UITapGestureRecognizer) {
        UIApplication.shared.open(URL(string: GlobalConstants.SocialMediaIds.TERMS_OF_SERVICE)!, options: [:], completionHandler: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
