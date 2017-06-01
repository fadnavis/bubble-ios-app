//
//  BubbleTabBarController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/18/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class BubbleTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        let settingsItem = (self.tabBar.items?[0])! as UITabBarItem
        settingsItem.selectedImage = UIImage(named: "home_selected")
    }

}
