//
//  ContactUsViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/25/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class ContactUsViewController: UIViewController, BubbleAPIDelegate, UITextViewDelegate, UITextFieldDelegate {

    
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var response: UILabel!
    @IBOutlet weak var emailTextView: UITextField!
    
    @IBOutlet weak var mobileNumber: UITextField!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Talk to Us"
        message.delegate = self
        emailTextView.delegate = self
        mobileNumber.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func sendMessage(_ sender: UIButton) {
        if(message.hasText && emailTextView.hasText) {
            if (isValidEmail(testStr: emailTextView.text!) == true) {
                message.isEditable = false
                var params : [String: String] = [:]
                params["method"] = GlobalConstants.HttpMethodName.SEND_FEEDBACK
                params["email_id"] = emailTextView.text!
                params["subject"] = "Feedback from iOS Customer \(UserData.sharedInstance.userEmail!)"
                params["userid"] = UserData.sharedInstance.userEmail
                params["isacknowledge"] = "3"
                if mobileNumber.hasText {
                    params["mobilenumber"] = mobileNumber.text
                }
                params["body"] = message.text
                let bubbleAPI = CallBubbleApi()
                bubbleAPI.delegate = self
                bubbleAPI.post(params)
                loadingView.startAnimating()
            } else {
                showAlert(title: "Invalid Email", body: "Kindly enter a valid Email Id to proceed")
            }
        } else {
            showAlert(title: "Enter a message", body: "Enter a valid email Id and your message. For fastest response, kindly enter your mobile number")
        }
    }
    
    func showAlert(title: String, body: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.message.endEditing(true)
        self.emailTextView.endEditing(true)
        self.mobileNumber.endEditing(true)
    }
    
    
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        loadingView.stopAnimating()
        if let status = responseJSON["status"] as? Int {
            if status == 0 {
                response.text = "Your message has been received by us. We will get back to you shortly"
                response.isHidden = false
                message.isEditable = true
                emailTextView.isEnabled = true
                mobileNumber.isEnabled = true
            } else {
                response.text = "Some error in sending data. Try again later"
                response.isHidden = false
                message.isEditable = true
                emailTextView.isEnabled = true
                mobileNumber.isEnabled = true
            }
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.tag == 1 {
            if(string == "\n") {
                if(isValidEmail(testStr: textField.text!)) {
                    emailTextView.resignFirstResponder()
                } else {
                    showAlert(title: "Invalid Email", body: "Enter a valid Email Id")
                }
            }
        } else {
            if(string == "\n") {
                mobileNumber.resignFirstResponder()
            }
        }
        return true
    }
    
    func onNetworkError(methodName: String) {
        loadingView.stopAnimating()
        let alert = UIAlertController(title: "Connectivity Issue", message: "Are you connected to the internet? Try again", preferredStyle: .actionSheet)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil) 
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
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
