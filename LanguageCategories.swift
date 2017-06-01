//
//  LanguageCategories.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/18/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import Foundation

class LanguageCategories {
    func returnCategories(language: String) -> [String]? {
        switch language {
        case "English":
            return ["Entertainment", "Movies", "News","Sports","Documentary","Food and Lifestyle", "Music","Kids","Religious"]
        case "Hindi":
            return ["Entertainment", "Movies", "News","Sports","Documentary","Food and Lifestyle", "Music","Kids","Religious"]
        case "Tamil":
            return ["Entertainment", "Movies", "News", "Music","Kids","Religious"]
        case "Telugu":
            return ["Entertainment", "Movies", "News","Music","Kids","Religious"]
        case "Malayalam":
            return ["Entertainment", "Movies", "News","Music","Kids","Religious"]
        case "Bengali":
            return ["Entertainment", "Movies", "News","Music"]
        case "Kannada":
            return ["Entertainment", "Movies", "News","Music","Kids","Religious"]
        case "Marathi":
            return ["Entertainment", "Movies", "News","Music"]
        case "Punjabi":
            return ["Entertainment", "News","Music"]
        case "Oriya":
            return ["Entertainment", "News","Music","Religious"]
        case "Bhojpuri":
            return ["Entertainment", "Movies", "Music"]
        case "Gujarati":
            return ["Entertainment", "News"]
        case "Assamese":
            return ["Entertainment", "News"]
        case "Urdu":
            return ["Entertainment","Religious"]
        default: return nil
        }
    }
}
