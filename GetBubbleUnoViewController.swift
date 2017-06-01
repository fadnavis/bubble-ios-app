//
//  GetBubbleUnoViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/25/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class GetBubbleUnoViewController: UIViewController, BubbleAPIDelegate {

    
    
    @IBOutlet weak var price: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        var params :  [String: String] = [:]
//        let bubbleApi = CallBubbleApi()
//        bubbleApi.delegate = self
//        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_PRICE
//        params["emailid"] = UserData.sharedInstance.userEmail
//        bubbleApi.post(params)
        self.title = ""
        //self.navigationController?.navigationBar.isTranslucent = true
        

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.title = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = true
    }
        
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                if let pricenum = responseJSON["price"] as? Int {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    // formatter.locale = NSLocale.currentLocale() // This is the default
                    price.text = formatter.string(from: NSNumber(value: pricenum))
//                     = @"\u20B9"
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func watchDemo(_ sender: UIButton) {        
        let youtubeId = GlobalConstants.SocialMediaIds.YOUTUBE_ID
        var url = URL(string:"youtube://\(youtubeId)")!
        if UIApplication.shared.canOpenURL(url)  {
            UIApplication.shared.openURL(url)
        } else {
            url = URL(string:"http://www.youtube.com/watch?v=\(youtubeId)")!
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func buyNow(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string: GlobalConstants.SocialMediaIds.AMAZON_PRODUCT_PAGE)!)
    }
    
    @IBAction func faq(_ sender: UIButton) {
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.topItem?.title = ""
        let faqController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "faqController")
        //self.present(configController, animated: true)
        self.navigationController?.pushViewController(faqController, animated: true)
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
