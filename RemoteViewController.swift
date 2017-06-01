//
//  RemoteViewController.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/7/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData
import AudioToolbox

class RemoteViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, BubbleWriteProcessDelegate, BubbleAPIDelegate {

    @IBOutlet weak var recentlyViewedCollection: UICollectionView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var numPad: UIView!
    @IBOutlet weak var dummy: UIView!
    
    @IBOutlet weak var enteredNumbers: UILabel!
    @IBOutlet weak var remoteCodesCollection: UICollectionView!
    @IBOutlet weak var volumeUp: UIControl!
    @IBOutlet weak var volumeDown: UIControl!
    @IBOutlet weak var arrowRight: UIControl!
    @IBOutlet weak var arrowUp: UIControl!
    @IBOutlet weak var arrowDown: UIControl!
    @IBOutlet weak var arrowLeft: UIControl!
    @IBOutlet weak var channelUp: UIControl!
    @IBOutlet weak var channelDown: UIControl!
    @IBOutlet weak var powerSTB: UIControl!
    @IBOutlet weak var powerTV: UIControl!
    @IBOutlet weak var mute: UIControl!
    @IBOutlet weak var ok: UIControl!
    @IBOutlet weak var back: UIControl!
    @IBOutlet weak var guide: UIControl!
    @IBOutlet weak var numpad: UIControl!
    
    @IBOutlet weak var blue: UIControl!
    @IBOutlet weak var yellow: UIControl!
    @IBOutlet weak var green: UIControl!
    @IBOutlet weak var red: UIControl!
    @IBOutlet weak var pause: UIControl!
    @IBOutlet weak var playcontrol: UIControl!
    @IBOutlet weak var forward: UIControl!
    @IBOutlet weak var rewind: UIControl!
    @IBOutlet weak var stop: UIControl!
    @IBOutlet weak var record: UIControl!
    @IBOutlet weak var language: UIControl!
    @IBOutlet weak var exit: UIControl!
    
    
    @IBOutlet weak var exitLabelStack: UIStackView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var coloredButtonsControlStack: UIStackView!
    @IBOutlet weak var coloredButtonsStack: UIStackView!
    
    @IBOutlet weak var pauseLabel: UILabel!
    @IBOutlet weak var playLabel: UILabel!
    @IBOutlet weak var forwardLabel: UILabel!
    @IBOutlet weak var rewindLabel: UILabel!
    @IBOutlet weak var pauseImage: UIImageView!
    @IBOutlet weak var playremoteImage: UIImageView!
    @IBOutlet weak var forwardImage: UIImageView!
    @IBOutlet weak var stopLabel: UILabel!
    @IBOutlet weak var rewindImage: UIImageView!
    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var stopImage: UIImageView!
    @IBOutlet weak var recordImage: UIImageView!
    @IBOutlet weak var languageImage: UIImageView!
    
    @IBOutlet weak var numPadConstraint: NSLayoutConstraint!
    
    var remoteCodes = [NSManagedObject]()
    var isSending = false
    var isNumPadOn = false
    var channelcodes : [Any]?
    var tvCode : Bool?
    var longPressTimer: Timer?
    var rapidCode: String!
    var bubbleDevice: String?
    var currentCode: String?
    
    let codesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "STBCodes")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.recentlyViewedCollection.delegate = self
        self.recentlyViewedCollection.dataSource = self
        self.remoteCodesCollection.delegate = self
        self.remoteCodesCollection.dataSource = self
        self.title = "STB"
        let bubbleAPI: CallBubbleApi  = CallBubbleApi()
        bubbleAPI.delegate = self
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_GET_ALL_CHANNELS_INFO
        params["emailid"] = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_EMAIL_KEY) as! String?
        params["stbname"] = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_STB_KEY) as! String?
        params["language"] = "ALL"
//        params["language"] = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RECENT_LANGUAGE) as? String ?? "English"
        bubbleAPI.post(params)

        if let tv = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_TV_REMOTES_DETAILED) as? Bool {
            tvCode = tv
        }
        
        bubbleDevice = UserDefaults.standard.object(forKey: GlobalConstants.UserDefaults.BUBBLE_IDENTIFIER) as? String
        // Do any additional setup after loading the view.
        setupGesturesForButtons()
    }
    
//    override func viewDidLayoutSubviews() {
//        let contentRect = CGRect.zero
//        for view in self.scrollView.subviews {
//            print("VIEW HEIGHT \(view.frame.height)")
//            for innerview in view.subviews {
//                print("INNERVIEW HEIGHT \(innerview.frame.height)")
//                contentRect.union(innerview.frame)
//            }
//        }
//        //print("HEIGHT IS \(contentRect.height)")
//        //self.scrollView.contentSize.height = contentRect.height
//        self.scrollView.contentSize.height = 900
//    }
    
    
    func setupRemoteViews() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext { context in
            guard let context = context else {
                return
            }
            for code in GlobalConstants.RemoteCodes.DYNAMIC_CODES {
                let predicate = NSPredicate(format: "(medium = %@) AND (remoteNumber = %@)", argumentArray: ["STB",code])
                self.codesFetchRequest.predicate = predicate
                do {
                    let codeResult = try context.fetch(self.codesFetchRequest) as! [NSManagedObject]
                    if codeResult.count == 0 {
                        DispatchQueue.main.async {
                            switch code {
                            case "STOP" :
                                self.stopImage.isHidden = true
                                self.stopLabel.isHidden = true
                                self.stop.isHidden = true
                            case "PAUSE" :
                                self.pauseImage.isHidden = true
                                self.pauseLabel.isHidden = true
                                self.pause.isHidden = true
                            case "RECORD" :
                                self.recordImage.isHidden = true
                                self.recordLabel.isHidden = true
                                self.record.isHidden = true
                            case "REWIND" :
                                self.rewindImage.isHidden = true
                                self.rewindLabel.isHidden = true
                                self.rewind.isHidden = true
                                self.adjustColorButtonConstraints()
                            case "FORWARD" :
                                self.forwardImage.isHidden = true
                                self.forwardLabel.isHidden = true
                                self.forward.isHidden = true
                            case "PLAY" :
                                self.playremoteImage.isHidden = true
                                self.playLabel.isHidden = true
                                self.playcontrol.isHidden = true
                            case "LANG" :
                                self.languageImage.isHidden = true
                                self.languageLabel.isHidden = true
                                self.language.isHidden = true
                            default : break
                            }
                        }
                    }
                } catch {
                    
                }
            }
        }
    }
    func setupGesturesForButtons() {
        volumeUp.addTarget(self, action: #selector(RemoteViewController.volumeUpPressed(sender:)), for: .touchDown)
        volumeUp.addTarget(self, action: #selector(RemoteViewController.volumeUpReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        volumeDown.addTarget(self, action: #selector(RemoteViewController.volumeDownPressed(sender:)), for: .touchDown)
        volumeDown.addTarget(self, action: #selector(RemoteViewController.volumeDownReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        channelDown.addTarget(self, action: #selector(RemoteViewController.channelDownPressed(sender:)), for: .touchDown)
        channelDown.addTarget(self, action: #selector(RemoteViewController.channelDownReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        channelUp.addTarget(self, action: #selector(RemoteViewController.channelUpPressed(sender:)), for: .touchDown)
        channelUp.addTarget(self, action: #selector(RemoteViewController.channelUpReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowLeft.addTarget(self, action: #selector(RemoteViewController.arrowLeftPressed(sender:)), for: .touchDown)
        arrowLeft.addTarget(self, action: #selector(RemoteViewController.arrowLeftReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowRight.addTarget(self, action: #selector(RemoteViewController.arrowRightPressed(sender:)), for: .touchDown)
        arrowRight.addTarget(self, action: #selector(RemoteViewController.arrowRightReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowUp.addTarget(self, action: #selector(RemoteViewController.arrowUpPressed(sender:)), for: .touchDown)
        arrowUp.addTarget(self, action: #selector(RemoteViewController.arrowUpReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        arrowDown.addTarget(self, action: #selector(RemoteViewController.arrowDownPressed(sender:)), for: .touchDown)
        arrowDown.addTarget(self, action: #selector(RemoteViewController.arrowDownReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchDragInside, .touchDragOutside])
        ok.addTarget(self, action: #selector(RemoteViewController.okPressed(sender:)), for: .touchDown)
        ok.addTarget(self, action: #selector(RemoteViewController.okReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        powerSTB.addTarget(self, action: #selector(RemoteViewController.powerSTBPressed(sender:)), for: .touchDown)
        powerSTB.addTarget(self, action: #selector(RemoteViewController.powerSTBReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        powerTV.addTarget(self, action: #selector(RemoteViewController.powerTVPressed(sender:)), for: .touchDown)
        powerTV.addTarget(self, action: #selector(RemoteViewController.powerTVReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        mute.addTarget(self, action: #selector(RemoteViewController.mutePressed(sender:)), for: .touchDown)
        mute.addTarget(self, action: #selector(RemoteViewController.muteReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        playcontrol.addTarget(self, action: #selector(RemoteViewController.playPressed(sender:)), for: .touchDown)
        playcontrol.addTarget(self, action: #selector(RemoteViewController.playReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        pause.addTarget(self, action: #selector(RemoteViewController.pausePressed(sender:)), for: .touchDown)
        pause.addTarget(self, action: #selector(RemoteViewController.pauseReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        rewind.addTarget(self, action: #selector(RemoteViewController.rewindPressed(sender:)), for: .touchDown)
        rewind.addTarget(self, action: #selector(RemoteViewController.rewindReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        forward.addTarget(self, action: #selector(RemoteViewController.forwardPressed(sender:)), for: .touchDown)
        forward.addTarget(self, action: #selector(RemoteViewController.forwardReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        exit.addTarget(self, action: #selector(RemoteViewController.exitPressed(sender:)), for: .touchDown)
        exit.addTarget(self, action: #selector(RemoteViewController.exitReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        record.addTarget(self, action: #selector(RemoteViewController.recordPressed(sender:)), for: .touchDown)
        record.addTarget(self, action: #selector(RemoteViewController.recordReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        language.addTarget(self, action: #selector(RemoteViewController.languagePressed(sender:)), for: .touchDown)
        language.addTarget(self, action: #selector(RemoteViewController.languageReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        stop.addTarget(self, action: #selector(RemoteViewController.stopPressed(sender:)), for: .touchDown)
        stop.addTarget(self, action: #selector(RemoteViewController.stopReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        red.addTarget(self, action: #selector(RemoteViewController.redPressed(sender:)), for: .touchDown)
        red.addTarget(self, action: #selector(RemoteViewController.redReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        green.addTarget(self, action: #selector(RemoteViewController.greenPressed(sender:)), for: .touchDown)
        green.addTarget(self, action: #selector(RemoteViewController.greenReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        yellow.addTarget(self, action: #selector(RemoteViewController.yellowPressed(sender:)), for: .touchDown)
        yellow.addTarget(self, action: #selector(RemoteViewController.yellowReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        blue.addTarget(self, action: #selector(RemoteViewController.bluePressed(sender:)), for: .touchDown)
        blue.addTarget(self, action: #selector(RemoteViewController.blueReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        back.addTarget(self, action: #selector(RemoteViewController.backPressed(sender:)), for: .touchDown)
        back.addTarget(self, action: #selector(RemoteViewController.backReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        guide.addTarget(self, action: #selector(RemoteViewController.guidePressed(sender:)), for: .touchDown)
        guide.addTarget(self, action: #selector(RemoteViewController.guideReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
        numpad.addTarget(self, action: #selector(RemoteViewController.numpadPressed(sender:)), for: .touchDown)
        numpad.addTarget(self, action: #selector(RemoteViewController.numpadReleased(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragExit])
    }
    
    
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        volumeUp.isHighlighted = true
        volumeUp.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        volumeDown.isHighlighted = true
        volumeDown.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func channelUpPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.CHANNEL_UP
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        channelUp.isHighlighted = true
        channelUp.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func channelDownPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.CHANNEL_DOWN
        currentCode = rapidCode
        sendSingleCommand()
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        channelDown.isHighlighted = true
        channelDown.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        arrowLeft.isHighlighted = true
        arrowLeft.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        arrowRight.isHighlighted = true
        arrowRight.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        arrowUp.isHighlighted = true
        arrowUp.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
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
        longPressTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(RemoteViewController.sendSingleCommandForRapidSTB), userInfo: nil, repeats: true)
        arrowDown.isHighlighted = true
        arrowDown.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func okPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.SELECT
        currentCode = rapidCode
        sendSingleCommand()
        ok.isHighlighted = true
        ok.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func powerTVPressed(sender: AnyObject) {
        if bubbleDevice == nil {
            goToGetBubbleUnoPage()
        }
        else {
            if tvCode == nil {
                goToSetupTVPage()
            } else {
                powerTV.isHighlighted = true
                rapidCode = GlobalConstants.RemoteCodes.POWER
                currentCode = rapidCode
                powerTV.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
                sendSingleCommand("TV")
//                if(!BluetoothSerialMain.sharedInstance.getIsSending()) {
//                    BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//                    BluetoothSerialMain.sharedInstance.setTVCodeString(dataString: tvCode!)
//                    BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: <#T##[String]#>, medium: <#T##String#>)
//                    BluetoothSerialMain.sharedInstance.startProcessBubble()
//                }
            }
        }
    }
    
    func powerSTBPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.POWER
        currentCode = rapidCode
        sendSingleCommand()
        powerSTB.isHighlighted = true
        powerSTB.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func mutePressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.MUTE
        currentCode = rapidCode
        sendSingleCommand()
        mute.isHighlighted = true
        mute.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func playPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.PLAY
        currentCode = rapidCode
        sendSingleCommand()
        playcontrol.isHighlighted = true
        playcontrol.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func pausePressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.PAUSE
        currentCode = rapidCode
        sendSingleCommand()
        pause.isHighlighted = true
        pause.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func rewindPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.REWIND
        currentCode = rapidCode
        sendSingleCommand()
        rewind.isHighlighted = true
        rewind.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func forwardPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.FORWARD
        currentCode = rapidCode
        sendSingleCommand()
        forward.isHighlighted = true
        forward.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func recordPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.RECORD
        currentCode = rapidCode
        sendSingleCommand()
        record.isHighlighted = true
        record.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func exitPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.EXIT
        currentCode = rapidCode
        sendSingleCommand()
        exit.isHighlighted = true
        exit.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func stopPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.STOP
        currentCode = rapidCode
        sendSingleCommand()
        stop.isHighlighted = true
        stop.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func languagePressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.LANGUAGE
        currentCode = rapidCode
        sendSingleCommand()
        language.isHighlighted = true
        language.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func redPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.RED
        currentCode = rapidCode
        sendSingleCommand()
        red.isHighlighted = true
        red.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func greenPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.GREEN
        currentCode = rapidCode
        sendSingleCommand()
        green.isHighlighted = true
        green.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func yellowPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.YELLOW
        currentCode = rapidCode
        sendSingleCommand()
        yellow.isHighlighted = true
        yellow.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func bluePressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.BLUE
        currentCode = rapidCode
        sendSingleCommand()
        blue.isHighlighted = true
        blue.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func backPressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.BACK
        currentCode = rapidCode
        back.isHighlighted = true
        back.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
        sendSingleCommand()
        
    }
    
    func guidePressed(sender: AnyObject) {
        rapidCode = GlobalConstants.RemoteCodes.GUIDE
        currentCode = rapidCode
        sendSingleCommand()
        guide.isHighlighted = true
        guide.backgroundColor = UIColor.BubbleDarkIndigo().withAlphaComponent(0.5)
    }
    
    func numpadPressed(sender: AnyObject) {
        if(!self.isSending) {
            self.tappedNumberArray = []
            self.numPadConstraint.constant = 0
            //            let origin = self.view.frame.height - self.numPad.frame.height
            let alpha = 0.7
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                //self.numPad.frame.origin.y = origin
                self?.view.layoutIfNeeded()
                self?.dummy.alpha = CGFloat(alpha)
                })
        }
    }
    
    
    
    //MARK: Button Released, Touch Up
    func volumeUpReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        
        volumeUp.isHighlighted = false
        volumeUp.backgroundColor = UIColor.clear
    }
    
    func volumeDownReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        volumeDown.isHighlighted = false
        volumeDown.backgroundColor = UIColor.clear
    }
    
    func channelUpReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        channelUp.isHighlighted = false
        channelUp.backgroundColor = UIColor.clear
    }
    
    func channelDownReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        channelDown.isHighlighted = false
        channelDown.backgroundColor = UIColor.clear
    }
    
    func arrowDownReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowDown.isHighlighted = false
        arrowDown.backgroundColor = UIColor.clear
    }
    
    func arrowUpReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowUp.isHighlighted = false
        arrowUp.backgroundColor = UIColor.clear
    }
    
    func arrowLeftReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowLeft.isHighlighted = false
        arrowLeft.backgroundColor = UIColor.clear
    }
    
    func arrowRightReleased(sender: AnyObject) {
        if let longtimer = longPressTimer {
            if(longtimer.isValid) {
                longtimer.invalidate()
            }
        }
        arrowRight.isHighlighted = false
        arrowRight.backgroundColor = UIColor.clear
    }
    
    func okReleased(sender: AnyObject) {
        ok.isHighlighted = false
        ok.backgroundColor = UIColor.clear
    }
    
    func powerTVReleased(sender: AnyObject) {
        powerTV.isHighlighted = false
        powerTV.backgroundColor = UIColor.clear
    }
    
    func powerSTBReleased(sender: AnyObject) {
        powerSTB.isHighlighted = false
        powerSTB.backgroundColor = UIColor.clear
    }
    
    func muteReleased(sender: AnyObject) {
        mute.isHighlighted = false
        mute.backgroundColor = UIColor.clear
    }
    
    func playReleased(sender: AnyObject) {
        playcontrol.isHighlighted = false
        playcontrol.backgroundColor = UIColor.clear
    }
    
    func rewindReleased(sender: AnyObject) {
        rewind.isHighlighted = false
        rewind.backgroundColor = UIColor.clear
    }
    
    func forwardReleased(sender: AnyObject) {
        forward.isHighlighted = false
        forward.backgroundColor = UIColor.clear
    }
    
    func pauseReleased(sender: AnyObject) {
        pause.isHighlighted = false
        pause.backgroundColor = UIColor.clear
    }
    
    func exitReleased(sender: AnyObject) {
        exit.isHighlighted = false
        exit.backgroundColor = UIColor.clear
    }
    
    func stopReleased(sender: AnyObject) {
        stop.isHighlighted = false
        stop.backgroundColor = UIColor.clear
    }
    
    func recordReleased(sender: AnyObject) {
        record.isHighlighted = false
        record.backgroundColor = UIColor.clear
    }
    
    func languageReleased(sender: AnyObject) {
        language.isHighlighted = false
        language.backgroundColor = UIColor.clear
    }
    
    func redReleased(sender: AnyObject) {
        red.isHighlighted = false
        red.backgroundColor = UIColor.clear
    }
    
    func yellowReleased(sender: AnyObject) {
        yellow.isHighlighted = false
        yellow.backgroundColor = UIColor.clear
    }
    
    func greenReleased(sender: AnyObject) {
        green.isHighlighted = false
        green.backgroundColor = UIColor.clear
    }
    
    func blueReleased(sender: AnyObject) {
        blue.isHighlighted = false
        blue.backgroundColor = UIColor.clear
    }
    
    func backReleased(sender: AnyObject) {
        back.isHighlighted = false
        back.backgroundColor = UIColor.clear
    }
    
    func guideReleased(sender: AnyObject) {
        guide.isHighlighted = false
        guide.backgroundColor = UIColor.clear
    }
    
    func numpadReleased(sender: AnyObject) {
        numpad.isHighlighted = false
        numpad.backgroundColor = UIColor.clear
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.numPad.frame.origin.y = self.view.frame.height
        self.title = "STB"
        setupRemoteViews()
        if let tv = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.USER_TV_REMOTES_DETAILED) as? Bool {
            tvCode = tv
        }
    }
    
    func sendSingleCommand(_ mediumdevice : String = "STB") {
        if(!self.isSending) {
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [rapidCode], medium: mediumdevice)
            BluetoothSerialMain.sharedInstance.startProcessBubble()
        }
    }
    
    func sendSingleCommandForRapidSTB() {
        if(!self.isSending) {
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [rapidCode], medium: "STB")
            BluetoothSerialMain.sharedInstance.startProcessBubble()
        }
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        if let status = responseJSON["status"] as? Int {
            if (methodName == GlobalConstants.HttpMethodName.BUBBLE_GET_ALL_CHANNELS_INFO) {
                if status == 0 {
                    if let channels = responseJSON["channelarray"] as? [Any] {
                        self.channelcodes = channels
                        self.remoteCodesCollection.isHidden = false
                        self.remoteCodesCollection.reloadData()
                        deleteAllChannelData()
                        saveChannelData()
                        
                        //if tvCode == nil {
//                        var param : [String: String] = [:]
//                        param["method"] = GlobalConstants.HttpMethodName.BUBBLE_GET_TV_MODEL
//                        param["emailid"] = UserData.sharedInstance.userEmail
//                        let bubbleapi = CallBubbleApi()
//                        bubbleapi.delegate = self
//                        bubbleapi.post(param)
                        //}
                    }
                } else {
                    fetchChannelData()
                }
            } else if (methodName == GlobalConstants.HttpMethodName.BUBBLE_GET_TV_MODEL) {
                if status == 0 {
                    if let tvcode = responseJSON["usercodes"] as? [Any] {
                        if let tvpowercode = tvcode[0] as? [String] {
//                            var datastring = tvpowercode[2]
//                            datastring += ":"
//                            datastring += tvpowercode[3]
//                            datastring += ":"
//                            datastring += tvpowercode[4]
//                            datastring += ":"
//                            tvCode = datastring
//                            UserDefaults.standard.set(datastring, forKey: GlobalConstants.UserDefaults.USER_TV_CODE)
                        }
                    }
                }
            }
        }
    }
    
    func onNetworkError(methodName: String) {
//        let alert = UIAlertController(title: "Connectivity Issue", message: "Channel numbers ", preferredStyle: .actionSheet)
//        
//        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
//        alert.addAction(okAction)
//        self.present(alert, animated: true, completion: nil)
        if (methodName != GlobalConstants.HttpMethodName.BUBBLE_EVENT_LOG) {
            self.fetchChannelData()
        }
    }
    
    func deleteAllChannelData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            
            guard let context = context else {
                return
            }
            let requestChannelData = NSFetchRequest<NSFetchRequestResult>(entityName: "ChannelData")
            let batchDeleteChannels = NSBatchDeleteRequest(fetchRequest: requestChannelData)
            
            do {
                try context.execute(batchDeleteChannels)
            } catch {
                fatalError()
            }
        }
    }
    
    func adjustColorButtonConstraints() {
        self.contentView.addConstraint(NSLayoutConstraint(item: exitLabelStack, attribute: .bottom, relatedBy: .equal, toItem: self.coloredButtonsStack, attribute: .top, multiplier: 1, constant: -8))
//        self.coloredButtonsControlStack.addConstraint(NSLayoutConstraint(item: exitLabelStack, attribute: .bottom, relatedBy: .equal, toItem: self.coloredButtonsControlStack, attribute: .top, multiplier: 1, constant: 8))
//        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .bottom, relatedBy: .equal, toItem: self.helperView, attribute: .bottom, multiplier: 1, constant: -20))
//        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70))
//        self.helperView.addConstraint(NSLayoutConstraint(item: uicircleview, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 70))
    }
    
    func fetchChannelData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext { context in
            guard let context = context else {
                return
            }
            let channelFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChannelData")
            do {
                 let channelCodesCoreData = try context.fetch(channelFetchRequest) as! [NSManagedObject]
                for chancodes in channelCodesCoreData {
                    if let id = chancodes.value(forKey: "channelId") as? String, let channumber = chancodes.value(forKey: "channelNumber") as? String, let channame = chancodes.value(forKey: "channelName") as? String, let cat = chancodes.value(forKey: "channelCategory") as? String {
                        let channeldatarray = [id,channame,channumber,cat]
                        self.channelcodes?.append(channeldatarray)
                    }
                }
                self.remoteCodesCollection.reloadData()
            } catch {
            }
        }
    }
    
    func saveChannelData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.dataStoreController.inContext {
            context in
            guard let context = context else {
                return
            }
            for channel in self.channelcodes! {
                if let channel = channel as? [String] {
                    let hdentity = NSEntityDescription.insertNewObject(forEntityName: "ChannelData", into: context)
                    hdentity.setValue(channel[0], forKey: "channelId")
                    hdentity.setValue(channel[1], forKey: "channelName")
                    hdentity.setValue(channel[2], forKey: "channelNumber")
                    hdentity.setValue(channel[3], forKey: "channelCategory")
                }
            }
            do {
                try context.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.recentlyViewedCollection {
            return recentChannels.count
        } else {
            return self.channelcodes == nil ? 0 : self.channelcodes!.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.recentlyViewedCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "recentlyviewed", for: indexPath) as? RecentlyViewedCollectionViewCell
            
            let chnlid = recentChannels[recentChannels.count - indexPath.row - 1]
            cell?.channelNumber = recentChannelNumbers[recentChannelNumbers.count - indexPath.row - 1]
            let urlstring = GlobalConstants.BubbleAPI.BUBBLE_URL_PREFIX + "/images/channels_logo/" + chnlid + ".png"
            let url = URL(string: urlstring)
            
//            DispatchQueue.global(qos: .userInteractive).async {
//                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
//                DispatchQueue.main.async(execute: {
//                    cell?.channelLogo?.image = UIImage(data: data!)
//                });
//            }
            
            cell?.channelLogo?.kf.setImage(with: url, placeholder: UIImage(named: "chanlogoplaceholder"), options: [.transition(.fade(0.3))])
            
            return cell!
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "channelcodes", for: indexPath) as? ChannelNumbersCollectionViewCell
            if let channeldata = self.channelcodes?[indexPath.row] as? [String] {
                cell?.channelName.text = channeldata[1]
                cell?.channelNumber.text = channeldata[2]
            }
            return cell!
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.remoteCodesCollection {
            let selectedCell : ChannelNumbersCollectionViewCell = self.remoteCodesCollection.cellForItem(at: indexPath) as! ChannelNumbersCollectionViewCell
            //selectedCell.channelName.textColor = UIColor.BubbleDarkIndigo()
            if(!self.isSending) {
                var characters = selectedCell.channelNumber.text!.characters.map { String($0) }
                characters.append(GlobalConstants.RemoteCodes.SELECT)
//                var completearray = self.tappedNumberArray
//                completearray.append(GlobalConstants.RemoteCodes.SELECT)
                BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
                BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: characters, medium: "STB")
                BluetoothSerialMain.sharedInstance.startProcessBubble()
                self.tappedNumberArray.removeAll()
                self.enteredNumbers.text = ""
            }
        }
    }
    
    
//    @IBAction func powerSTB(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.POWER], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func powerTV(_ sender: UITapGestureRecognizer) {
//        if tvCode == nil {
//            goToSetupTVPage()
//        } else {
//            if(!BluetoothSerialMain.sharedInstance.getIsSending()) {
//                BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//                BluetoothSerialMain.sharedInstance.setTVCodeString(dataString: tvCode!)
//                BluetoothSerialMain.sharedInstance.startProcessBubble()
//            }
//        }
//    }
    
    func goToSetupTVPage() {
        self.navigationController?.navigationBar.topItem?.title = ""
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chooseTVViewController") as UIViewController
        //self.present(viewController, animated: true, completion: nil)
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func goToGetBubbleUnoPage() {
        self.navigationController?.navigationBar.topItem?.title = ""
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "getbubbleuno") as UIViewController
        //self.present(viewController, animated: true, completion: nil)
        self.navigationController!.pushViewController(viewController, animated: true)
    }

//    @IBAction func mute(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.MUTE], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func channelUp(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.CHANNEL_UP], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//            
//        }
//    }
//    
//    @IBAction func channelDown(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.CHANNEL_DOWN], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func up(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.UP], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func ok(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.SELECT], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func down(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.DOWN], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func left(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.LEFT], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func right(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.RIGHT], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func volumeUp(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.VOLUME_UP], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func volumeDown(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.VOLUME_DOWN], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    @IBAction func exit(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.BACK], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
//    
//    
    @IBAction func dummyBackgroundTap(_ sender: UITapGestureRecognizer) {
        if(!self.isSending) {
            //let origin = self.isNumPadOn ? self.view.frame.height : self.view.frame.height - self.numPad.frame.height
            //let origin = self.view.frame.height
            self.numPadConstraint.constant = -self.numPad.frame.height
            let alpha =  0
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                //self.numPad.frame.origin.y = origin
                self?.view.layoutIfNeeded()
                self?.dummy.alpha = CGFloat(alpha)
                })
        }
    }
    
    var tappedNumberArray : [String] = []
    
//    @IBAction func numbers(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            self.tappedNumberArray = []
//            self.numPadConstraint.constant = 0
////            let origin = self.view.frame.height - self.numPad.frame.height
//            let alpha = 0.7
//            UIView.animate(withDuration: 0.3, animations: { [weak self] in
//                //self.numPad.frame.origin.y = origin
//                self?.view.layoutIfNeeded()
//                self?.dummy.alpha = CGFloat(alpha)
//                })
//        }
//    }
    
//    @IBAction func guide(_ sender: UITapGestureRecognizer) {
//        if(!self.isSending) {
//            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
//            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: [GlobalConstants.RemoteCodes.GUIDE], medium: "STB")
//            BluetoothSerialMain.sharedInstance.startProcessBubble()
//        }
//    }
    
    func BubbleWriteStarted() {
        self.isSending = true
    }
    
    func BubbleWriteEnded() {
        self.isSending = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        logEventOnServer()
//        if (longPressTimer.isValid) {
//            longPressTimer.invalidate()
//        }
    }
    
    func logEventOnServer() {
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_EVENT_LOG
        params["email_id"] = UserData.sharedInstance.userEmail
        params["event"] = "RemoteControl"
        if let curcode = currentCode {
            params["label"] = curcode
        } else {
            params["label"] = ""
        }
        params["channelid"] = ""
        params["programid"] = ""
        params["source"] = "iOSRemotePage"
        params["macid"] = UserData.sharedInstance.bubbleMAC
        bubbleAPI.post(params)
    }
    
    func BubbleWriteEndedWithError() {
//        if (longPressTimer.isValid) {
//            longPressTimer.invalidate()
//        }
        self.isSending = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main") as UIViewController
        //self.present(viewController, animated: true, completion: nil)
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func BubbleWriteBLEOff() {
//        if (longPressTimer.isValid) {
//            longPressTimer.invalidate()
//        }
        self.isSending = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let alert = UIAlertController(title: "Turn On Bluetooth", message: "Turn on Bluetooth to control your DTH from the app and try again!", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func indexForStringNumber(numbers: [String]?) -> Int {
        var i = 0
        guard let num = numbers else {
            return 0
        }
        if num.count == 0 {
            self.enteredNumbers.text = ""
            return 0
        }
        var numberString = ""
        for numchar in num {
            numberString += numchar
            self.enteredNumbers.text = numberString
        }
        guard let chnls = self.channelcodes else {
            return 0
        }
        for channel in chnls {
            if let x = channel as? [String] {
                if x[2].contains(numberString) {
                    return i
                }
                i += 1
            }
            
        }
        return 0
    }
    
    func scrollToPosition (row: Int) {
        let indexPath = IndexPath(item: row, section: 0)
        guard let _ = self.channelcodes else {
            return
        }
        self.remoteCodesCollection.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
        
    }
    
    @IBAction func tap1(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("1")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap2(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("2")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap3(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("3")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap4(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("4")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap5(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("5")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap6(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("6")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap7(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("7")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap8(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("8")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tapBack(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count > 0) {
            self.tappedNumberArray.removeLast()
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap9(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("9")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tap0(_ sender: UITapGestureRecognizer) {
        if(self.tappedNumberArray.count < 5) {
            self.tappedNumberArray.append("0")
            self.scrollToPosition(row: self.indexForStringNumber(numbers: self.tappedNumberArray))
        }
    }
    
    @IBAction func tapGo(_ sender: UITapGestureRecognizer) {
        //send code to bubble device
        if(!self.isSending) {
            var completearray = self.tappedNumberArray
            completearray.append(GlobalConstants.RemoteCodes.SELECT)
            currentCode = ""
//            for num in completearray {
//                currentCode += num
//            }
            
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: completearray, medium: "STB")
            BluetoothSerialMain.sharedInstance.startProcessBubble()
            self.tappedNumberArray.removeAll()
            self.enteredNumbers.text = ""
        }
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
