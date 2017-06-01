//
//  ConfigureBubbleUno.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/29/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConfigureBubbleUno : UIViewController, BluetoothSerialDelegate {
    //@IBOutlet weak var loadingView: NVActivityIndicatorView!
    @IBOutlet weak var statusText: UILabel!
    @IBOutlet weak var connected: UIImageView!
    @IBOutlet weak var retry: UIImageView!
    @IBOutlet weak var configButton: UILabel!
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    //private var activityView: NVActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        UserDefaults.standard.set(false, forKey: GlobalConstants.UserDefaults.USER_IS_FIRST_LAUNCH)
//        self.navigationController?.navigationBar.barTintColor = UIColor.init(rgb: 0x111125)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
//        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //loadingView.startAnimating()
        //showLoadingIndicator()
        super.viewWillAppear(animated)
        setupViews(1)
        initiateBLESerial()
    }
    
//    func showLoadingIndicator(){
//        if activityView == nil{
//            activityView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40.0, height: 40.0), type: NVActivityIndicatorType.ballPulseSync, color: UIColor.BubbleOffWhite(), padding: 0.0)
//            // add subview
//            view.addSubview(activityView)
//            // autoresizing mask
//            activityView.translatesAutoresizingMaskIntoConstraints = false
//            // constraints
//            view.addConstraint(NSLayoutConstraint(item: activityView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.leadingMargin, multiplier: 1, constant: 250))
//            view.addConstraint(NSLayoutConstraint(item: activityView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0))
//        }
//        
//        activityView.startAnimating()
//    }
    
    func initiateBLESerial() {
        serial = BluetoothSerial(delegate: self)
        serial.writeType = .withResponse
        //serial.startScan()
    }
    
    func setupStatusChanged(_ status: GlobalConstants.BubbleSetupStatus) {
        if(status == GlobalConstants.BubbleSetupStatus.all_OK) {
            statusText.text = "  Setup Complete"
            setupViews(2)
            configButton.text? = "Done"
        } else if(status == GlobalConstants.BubbleSetupStatus.in_PROGRESS) {
            statusText.text = "  Setting up your Bubble Uno"
            setupViews(1)
            configButton.text? = "Cancel"
        } else if(status == GlobalConstants.BubbleSetupStatus.error_FINDING_BUBBLE) {
            statusText.text = " Error finding Bubble. Retry!"
            setupViews(3)
            configButton.text? = "Cancel"
        }
    }
    
    func setupViews(_ viewNumber: Int) {
        if(viewNumber == 1) {
            self.loadingView.startAnimating()
        } else {
            self.loadingView.stopAnimating()
        }
        //activityView.isHidden = viewNumber != 1
        connected.isHidden = viewNumber != 2
        retry.isHidden = viewNumber != 3
    }
    
    
    @IBAction func configButtonClicked(_ sender: UITapGestureRecognizer) {
        if let txt = configButton.text {
            if(txt == "Cancel") {
                serial.stopScan()
                if self.navigationController != nil {
                    BluetoothSerialMain.sharedInstance.resetBluetooth()
                } else {
                    serial.resetBluetooth()
                }
                serial = nil
                goToHomePage()
            } else {
                serial.stopScan()
                serial = nil
                if self.navigationController != nil {
                    BluetoothSerialMain.sharedInstance.resetBluetooth()
                }
                goToHomePage()
            }
        }
    }
    
    func goToHomePage() {
        
        if self.navigationController == nil {
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "containerViewController") as UIViewController
            
            self.present(viewController, animated: true, completion: nil)
        } else {
            //self.navigationController!.popViewController(animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }
    @IBAction func retrySetup(_ sender: UITapGestureRecognizer) {
        serial.startScan()
    }
}
