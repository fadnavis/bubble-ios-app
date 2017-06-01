//
//  SharedUserData.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/21/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import Foundation

class UserData {
//    private static var __once: () = {
//            Static.instance = UserData()
//        }()
//    class var sharedInstance: UserData {
//        struct Static {
//            static var instance: UserData?
//            static var token: Int = 0
//        }
//        
//        _ = UserData.__once
//        
//        return Static.instance!
//    }
    static let sharedInstance = UserData()
    
    
    var userEmail : String!
    
    var userLanguage : String!
    
    var isHD : Bool!
    
    var bubbleMAC : String!
    
    
    
}

