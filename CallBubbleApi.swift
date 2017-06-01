//
//  CallBubbleApi.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/7/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

@objc protocol BubbleAPIDelegate {
    @objc optional func onResponseReceived(_ responseJSON: [String: AnyObject], methodName: String)
    @objc optional func onNetworkError(methodName: String)
}
class CallBubbleApi {
    var delegate: BubbleAPIDelegate?
    
    func post(_ params : Dictionary<String, String>) {
        DispatchQueue.global(qos: .userInteractive).async {
            let bubbleDateFormat = DateFormatter()
            bubbleDateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let url: String = GlobalConstants.BubbleAPI.BUBBLE_POST_API
            var urlRequest = URLRequest(url: URL(string: url)! )
            urlRequest.httpMethod = GlobalConstants.HttpMethod.METHOD_POST
            let session = URLSession.shared
            
            var paramString = ""
            
            for (key, value) in params {
                if(!paramString.isEmpty) {
                    paramString += "&"
                }
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                paramString += "\(escapedKey!)=\(escapedValue!)"
            }
            
            
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = paramString.data(using: String.Encoding.utf8)
            
            let task = session.dataTask(with: urlRequest, completionHandler: { 
                (data, response, error) -> () in
                
                guard let responseData = data else {
                    self.delegate?.onNetworkError?(methodName: params["method"]!)
                    return
                }
                
                //let resstring = String(data: responseData, encoding: String.Encoding.utf8)
                //print(resstring)
//                guard let _ = error else {
//                    print("error calling the server")
//                    return
//                }
                
                
                do {
                    guard let receivedJSON = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.delegate?.onResponseReceived!(receivedJSON, methodName: params["method"]!)
                    }
                    
                    
                } catch {
                }
            }) 
            task.resume()
        }
    }
    
}
