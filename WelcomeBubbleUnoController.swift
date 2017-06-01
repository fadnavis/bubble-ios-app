//
//  WelcomeBubbleUnoController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/4/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class WelcomeBubbleUnoController: UIViewController {
    
    override func viewDidLoad() {
        
    }
    @IBAction func configBubbleUno(_ sender: UITapGestureRecognizer) {
        goToConfigureBubble()
    }
    
    func goToConfigureBubble() {
        let viewContoller: UIViewController = UIStoryboard(name: "SetupBubbleUno", bundle: nil).instantiateViewController(withIdentifier: "setupBubble")
        
        self.present(viewContoller, animated: true, completion: nil)
    }
    @IBAction func skipTapped(_ sender: UITapGestureRecognizer) {
        goToHomePage()
    }
    
    
    @IBAction func getUnoTapped(_ sender: UITapGestureRecognizer) {
        goToGetBubbleUno()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.view.layoutIfNeeded()
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.topItem?.title = "Welcome to Bubble"
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.BubbleOffWhite2(),
            NSFontAttributeName: UIFont(name: "Quicksand-Bold", size: 19)!
        ]
        self.navigationController?.navigationBar.barTintColor = UIColor.init(rgb: 0x111125)
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func goToHomePage() {
        let viewController: UIViewController = UIStoryboard(name: "Main",bundle: nil).instantiateViewController(withIdentifier: "containerViewController")
        
        self.present(viewController, animated: true, completion: nil)
    }
    
    func goToGetBubbleUno() {
        let viewController: UIViewController = UIStoryboard(name: "WelcomeBubbleUno",bundle: nil).instantiateViewController(withIdentifier: "getbubbleuno")
        
        self.navigationController?.pushViewController(viewController, animated: true)
        //self.present(viewController, animated: true, completion: nil)
    }
}
