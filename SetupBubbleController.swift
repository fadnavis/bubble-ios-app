//
//  SetupBubbleController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/29/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class SetupBubbleController: UIViewController {
    
    @IBAction func clickNext(_ sender: UITapGestureRecognizer) {
        startSetup()
    }
    
    func startSetup() {
        let viewController:UIViewController = UIStoryboard(name: "SetupBubbleUno", bundle: nil).instantiateViewController(withIdentifier: "configBubble") as UIViewController
        
        self.present(viewController, animated: true, completion: nil)
    }
}
