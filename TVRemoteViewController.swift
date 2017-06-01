//
//  TVRemoteViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 1/30/17.
//  Copyright © 2017 Harsh Fadnavis. All rights reserved.
//

import UIKit

class TVRemoteViewController: UIViewController, BubbleWriteProcessDelegate, BubbleAPIDelegate {

    
    @IBOutlet weak var tvsourcecontrol: UIControl!
    @IBOutlet weak var tvpowerControl: UIControl!
    
    @IBOutlet weak var arrowRightControl: UIControl!
    @IBOutlet weak var arrowDownControl: UIControl!
    @IBOutlet weak var arrowUpControl: UIControl!
    @IBOutlet weak var okControl: UIControl!
    @IBOutlet weak var arrowLeftControl: UIControl!
    @IBOutlet weak var volumeUpControl: UIControl!
    @IBOutlet weak var volumeDownControl: UIControl!
    @IBOutlet weak var tvmutecontrol: UIControl!
    
    var rapidCode: String!
    var currentCode: String?
    var longPressTimer: Timer?
    var isSending = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "TV"

        setupGesturesForButtons()
        // Do any additional setup after loading the view.
    }
    
    func setupGesturesForButtons() {
        volumeUpControl.addTarget(self, action: #selector(TVRemoteViewController.volumeUpPressed(sender:)), for: .touchDown)
        volumeUpControl.addTarget(self, action: #selector(TVRemoteViewController.volumeUpReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        volumeDownControl.addTarget(self, action: #selector(TVRemoteViewController.volumeDownPressed(sender:)), for: .touchDown)
        volumeDownControl.addTarget(self, action: #selector(TVRemoteViewController.volumeDownReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowLeftControl.addTarget(self, action: #selector(TVRemoteViewController.arrowLeftPressed(sender:)), for: .touchDown)
        arrowLeftControl.addTarget(self, action: #selector(TVRemoteViewController.arrowLeftReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowRightControl.addTarget(self, action: #selector(TVRemoteViewController.arrowRightPressed(sender:)), for: .touchDown)
        arrowRightControl.addTarget(self, action: #selector(TVRemoteViewController.arrowRightReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowUpControl.addTarget(self, action: #selector(TVRemoteViewController.arrowUpPressed(sender:)), for: .touchDown)
        arrowUpControl.addTarget(self, action: #selector(TVRemoteViewController.arrowUpReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowDownControl.addTarget(self, action: #selector(TVRemoteViewController.arrowDownPressed(sender:)), for: .touchDown)
        arrowDownControl.addTarget(self, action: #selector(TVRemoteViewController.arrowDownReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        okControl.addTarget(self, action: #selector(TVRemoteViewController.okPressed(sender:)), for: .touchDown)
        okControl.addTarget(self, action: #selector(TVRemoteViewController.okReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        tvmutecontrol.addTarget(self, action: #selector(TVRemoteViewController.mutePressed(sender:)), for: .touchDown)
        tvmutecontrol.addTarget(self, action: #selector(TVRemoteViewController.muteReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        tvpowerControl.addTarget(self, action: #selector(TVRemoteViewController.powerTVPressed(sender:)), for: .touchDown)
        tvpowerControl.addTarget(self, action: #selector(TVRemoteViewController.powerTVReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        tvsourcecontrol.addTarget(self, action: #selector(TVRemoteViewController.sourceTVPressed(sender:)), for: .touchDown)
        tvsourcecontrol.addTarget(self, action: #selector(TVRemoteViewController.sourceTVReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        //do nothing
    }
    
    func onNetworkError(methodName: String) {
        //do nothing
    }
    override func viewWillAppear(_ animated: Bool) {
        self.title = "TV Remote"
    }
    
    func sendSingleCommand() {
        if(!self.isSending) {
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [rapidCode], medium: "TV")
            BluetoothSerialMain.sharedInstance.startProcessBubble()
        }
    }
    
//    func sendSingleCommand(_ mediumdevice : String = "TV") {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [rapidCode], medium: mediumdevice)
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
    
    // MARK: Button Pressed, Touch Down
    func volumeUpPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.VOLUME_UP
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(TVRemoteViewController.sendSingleCommand), userInfo: nil, repeats: true)
        volumeUpControl.isHighlighted = true
        volumeUpControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func volumeDownPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.VOLUME_DOWN
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(TVRemoteViewController.sendSingleCommand), userInfo: nil, repeats: true)
        volumeDownControl.isHighlighted = true
        volumeDownControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    
    func arrowLeftPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.LEFT
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(TVRemoteViewController.sendSingleCommand), userInfo: nil, repeats: true)
        arrowLeftControl.isHighlighted = true
        arrowLeftControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func arrowRightPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.RIGHT
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(TVRemoteViewController.sendSingleCommand), userInfo: nil, repeats: true)
        arrowRightControl.isHighlighted = true
        arrowRightControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func arrowUpPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.UP
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(TVRemoteViewController.sendSingleCommand), userInfo: nil, repeats: true)
        arrowUpControl.isHighlighted = true
        arrowUpControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func arrowDownPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.DOWN
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(TVRemoteViewController.sendSingleCommand), userInfo: nil, repeats: true)
        arrowDownControl.isHighlighted = true
        arrowDownControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func okPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.SELECT
        currentCode = rapidCode
        sendSingleCommand()
        okControl.isHighlighted = true
        okControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func powerTVPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.POWER
        currentCode = rapidCode
        sendSingleCommand()
        tvpowerControl.isHighlighted = true
        tvpowerControl.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func sourceTVPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.SOURCE
        currentCode = rapidCode
        sendSingleCommand()
        tvsourcecontrol.isHighlighted = true
        tvsourcecontrol.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func mutePressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.MUTE
        currentCode = rapidCode
        sendSingleCommand()
        tvmutecontrol.isHighlighted = true
        tvmutecontrol.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    //MARK: Button Released, Touch Up
    func volumeUpReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        
        volumeUpControl.isHighlighted = false
        volumeUpControl.backgroundColor = UIColor.clear
    }
    
    func volumeDownReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        volumeDownControl.isHighlighted = false
        volumeDownControl.backgroundColor = UIColor.clear
    }
    
    func arrowDownReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowDownControl.isHighlighted = false
        arrowDownControl.backgroundColor = UIColor.clear
    }
    
    func arrowUpReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowUpControl.isHighlighted = false
        arrowUpControl.backgroundColor = UIColor.clear
    }
    
    func arrowLeftReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowLeftControl.isHighlighted = false
        arrowLeftControl.backgroundColor = UIColor.clear
    }
    
    func arrowRightReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowRightControl.isHighlighted = false
        arrowRightControl.backgroundColor = UIColor.clear
    }
    
    func okReleased(sender: AnyObject) {
        okControl.isHighlighted = false
        okControl.backgroundColor = UIColor.clear
    }
    
    func powerTVReleased(sender: AnyObject) {
        tvpowerControl.isHighlighted = false
        tvpowerControl.backgroundColor = UIColor.clear
    }
    
    func sourceTVReleased(sender: AnyObject) {
        tvsourcecontrol.isHighlighted = false
        tvsourcecontrol.backgroundColor = UIColor.clear
    }
    
    func muteReleased(sender: AnyObject) {
        tvmutecontrol.isHighlighted = false
        tvmutecontrol.backgroundColor = UIColor.clear
    }
    
    func BubbleWriteStarted() {
        self.isSending = true
    }
    
    func BubbleWriteEnded() {
        self.isSending = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        logEventOnServer()
    }
    
    func BubbleWriteEndedWithError() {
        self.isSending = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main") as UIViewController
        //self.present(viewController, animated: true, completion: nil)
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func BubbleWriteBLEOff() {
        self.isSending = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let alert = UIAlertController(title: "Turn On Bluetooth", message: "Turn on Bluetooth to control your DTH from the app and try again!", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

    
    func logEventOnServer() {
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_EVENT_LOG
        params["email_id"] = UserData.sharedInstance.userEmail
        params["event"] = currentCode
        if let curcode = currentCode {
            params["label"] = curcode
        } else {
            params["label"] = ""
        }
        params["channelid"] = ""
        params["programid"] = ""
        params["source"] = "iOSTVRemotePage"
        params["macid"] = UserData.sharedInstance.bubbleMAC
        bubbleAPI.post(params)
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
