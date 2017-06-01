//
//  ChooseTVViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/17/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class ChooseTVViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BubbleAPIDelegate {

    @IBOutlet weak var tvTableView: UITableView!
    @IBOutlet weak var proceedButton: UILabel!
    
    
    var tvArray = [String]()
    var tvName : String?
    //var initialSelectedPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Choose your TV"
        tvTableView.delegate = self
        tvTableView.dataSource = self
        
        // fetch program data for this user
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_TV_BRANDS
        params["emailid"] = UserData.sharedInstance.userEmail
        let callBubbleAPI = CallBubbleApi()
        callBubbleAPI.delegate = self
        callBubbleAPI.post(params)
        if let tv = (UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_TV_BRAND) as? String) {
            self.tvName = tv
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = "Choose your TV"
        proceedButton.isEnabled = false
//        if tvName == nil {
//            proceedButton.isEnabled = false
//        } else {
//            proceedButton.isEnabled = true
//        }
    }

    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                if (methodName == GlobalConstants.HttpMethodName.BUBBLE_TV_BRANDS) {
                    guard let tvList = responseJSON["operator"] as? [String : String] else {
                        return
                    }
                    
                    for (_,value) in (Array(tvList).sorted{$0.1<$1.1}) {
                        tvArray.append(value)
                    }
                    self.tvTableView.reloadData()
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
    
    @IBAction func tapProceed(_ sender: UITapGestureRecognizer) {
        if (proceedButton.isEnabled) {
            UserDefaults.standard.set(tvName, forKey: GlobalConstants.UserDefaults.USER_TV_BRAND)
            self.navigationController?.navigationBar.topItem?.title = ""
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configureTV")
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tvArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tvTableView.dequeueReusableCell(withIdentifier: "chooseTV", for: indexPath) as! ChooseTVTableViewCell
        cell.tvBrandName.text = tvArray[indexPath.row]
        return cell
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if let tv = tvName {
//            if tv == tvArray[indexPath.row] {
//                cell.setSelected(true, animated: true)
//                initialSelectedPath = indexPath
//                proceedButton.isEnabled = true
//            }
//        }
//    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        proceedButton.isEnabled = true
//        if let path = initialSelectedPath {
//            tableView.deselectRow(at: path, animated: true)
//            initialSelectedPath = nil
//        }
        tvName = tvArray[indexPath.row]
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
