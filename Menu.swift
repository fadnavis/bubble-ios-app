//
//  Menu.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/9/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class Menu {
    let title: String
    let icon: UIImage?
    
    init(title: String, icon: UIImage? = nil) {
        self.title = title
        self.icon = icon
    }
    
    class func allMenu() -> Array<Menu> {
        return [Menu(title: "Get Bubble Uno",icon: UIImage(named: "cart")), Menu(title: "Setup Bubble Uno",icon: UIImage(named: "setting")), Menu(title: "Change DTH Operator",icon: UIImage(named: "operator")), Menu(title: "Change TV",icon: UIImage(named: "configTV")), Menu(title: "FAQ",icon: UIImage(named: "questionFAQ")), Menu(title: "Talk to Us",icon: UIImage(named: "talktous")), Menu(title: "About Us",icon: UIImage(named: "aboutus"))]
    }
    
    class func allLanguages() -> Array<Menu> {
        return [Menu(title: "English"), Menu(title: "Hindi"), Menu(title: "Tamil"), Menu(title: "Telugu"), Menu(title: "Malayalam"), Menu(title: "Bengali"), Menu(title: "Kannada"), Menu(title: "Marathi"), Menu(title: "Punjabi"), Menu(title: "Oriya"), Menu(title: "Bhojpuri"), Menu(title: "Gujrati"), Menu(title: "Assamese"), Menu(title: "Urdu")]
    }
}
