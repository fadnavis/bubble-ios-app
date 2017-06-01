//
//  VersionUpdateViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 11/23/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class VersionUpdateViewController: UIViewController {

    public var isForced: Bool?
    
    @IBOutlet weak var skipButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let forced = isForced {
            if forced == true {
                skipButton.isHidden = true
            } else {
                skipButton.isHidden = false
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func skipTapped(_ sender: UIButton) {
        if let _ = UserDefaults.standard.object(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) {
            //do all the initialization before going to home page
            goToHomePage()
        } else {
            goToChooseSTBPage()
        }
    }
    
    
    @IBAction func updateTapped(_ sender: UIButton) {
        UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/in/app/bubble-tv-guide-smart-remote/id1174329057?mt=8")!)
    }
    
    func goToHomePage() {
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as UIViewController
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToChooseSTBPage() {
        let viewContoller: UIViewController = UIStoryboard(name: "ChooseSTB", bundle: nil).instantiateViewController(withIdentifier: "stbNavigationScene")
        
        self.present(viewContoller, animated: true, completion: nil)
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
