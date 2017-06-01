//
//  ProgramDataTableViewCell.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 9/11/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit
import CoreData

class ProgramDataTableViewCell: UITableViewCell, BubbleWriteProcessDelegate, BubbleAPIDelegate {
    
    @IBOutlet weak var programName: UILabel!
    @IBOutlet weak var channelLogo: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var endsInMins: UILabel!
    
    @IBOutlet weak var endsinView: UIView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var programNext: UILabel!
    @IBOutlet weak var programLater: UILabel!
    @IBOutlet weak var hdLabel: UILabel!
    @IBOutlet weak var sdLabel: UILabel!
    @IBOutlet weak var more: UILabel!
    @IBOutlet weak var play: UIImageView!
    @IBOutlet weak var genreLabel: UILabel!
    
    @IBOutlet weak var imdbHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imdbLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    let bubbleDateFormat = DateFormatter()
    var dformat = DateFormatter()
    
    var startDate: Date!
    var duration: Int!
    var minsOver: Int!
    var programStartTime: String!
    var programDuration: Int!
    var postTimer: Timer?
    var channelNumber: String!
    var channelId: String!
    var programId: String!
    var channelName: String!
    
    var hdProgram : Programs?
    var sdProgram : Programs?
    
    var nextHDprogram : Programs?
    var nextSDProgram : Programs?
    
    var laterSDProgram : Programs?
    var laterHDProgram : Programs?
    
    var counter: Int = 0 {
        didSet {
            let fractionalProgress = Float(counter)/Float(duration)
            if(fractionalProgress < 1.0) {
                progressView.setProgress(fractionalProgress, animated: false)
                let x = duration - counter
                endsInMins.text = "Ends in " + "\(x)" + " mins"
            } else {
                progressView.setProgress(Float(1.0), animated: false)
                endsInMins.text = "Show Ended"
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layoutIfNeeded()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()        
        let playTapGesture = UITapGestureRecognizer(target: self, action: #selector(playOnTV(recognizer:)))
        play.addGestureRecognizer(playTapGesture)
        play.isUserInteractionEnabled = true
        
        let hdTapGesture = UITapGestureRecognizer(target: self, action: #selector(HDTapped(recognizer:)))
        hdLabel.addGestureRecognizer(hdTapGesture)
        hdLabel.isUserInteractionEnabled = true
        
        let sdTapGesture = UITapGestureRecognizer(target: self, action: #selector(SDTapped(recognizer:)))
        sdLabel.addGestureRecognizer(sdTapGesture)
        sdLabel.isUserInteractionEnabled = true
        
//        let logoTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
//        let endsinTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
//        let backgroundTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
//        let progNameTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
//        let progNextTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
//        let progLaterTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
        let moreTapGesture = UITapGestureRecognizer(target: self, action: #selector(rowSelected(recognizer:)))
//        endsinView.addGestureRecognizer(endsinTapGesture)
//        background.addGestureRecognizer(backgroundTapGesture)
//        programName.addGestureRecognizer(progNameTapGesture)
//        programNext.addGestureRecognizer(progNextTapGesture)
//        programLater.addGestureRecognizer(progLaterTapGesture)
//        channelLogo.addGestureRecognizer(logoTapGesture)
        more.addGestureRecognizer(moreTapGesture)
        
//        endsinView.isUserInteractionEnabled = true
//        background.isUserInteractionEnabled = true
//        programName.isUserInteractionEnabled = true
//        programNext.isUserInteractionEnabled = true
//        programLater.isUserInteractionEnabled = true
//        channelLogo.isUserInteractionEnabled = true
        more.isUserInteractionEnabled = true
        
        dformat.dateFormat = GlobalConstants.BubbleDateFormat.DATE_FORMAT_AM
        dformat.amSymbol = "AM"
        dformat.pmSymbol = "PM"
    }
    
    func rowSelected(recognizer: UITapGestureRecognizer) {
        if let tv = self.superview?.superview as? UITableView {
            if let vc = tv.dataSource as? UIViewController {
                let nextOnThisChannelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "nextPrograms") as! NextProgramsViewController
                nextOnThisChannelVC.channelId = self.channelId
                nextOnThisChannelVC.channelNameString = self.channelName
                nextOnThisChannelVC.channelNumber = self.channelNumber
                vc.navigationController?.navigationBar.topItem?.title = ""
                vc.navigationController?.pushViewController(nextOnThisChannelVC, animated: true)
            }
        }
    }
    

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //fatalError("init(coder:) has not been implemented")
    }
    
    func playOnTV(recognizer: UITapGestureRecognizer) {
        if(!BluetoothSerialMain.sharedInstance.getIsSending()) {
            var characters = channelNumber.characters.map { String($0) }
            characters.append(GlobalConstants.RemoteCodes.SELECT)
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: characters, medium: "STB")
            BluetoothSerialMain.sharedInstance.startProcessBubble()
        }
    }
    
    func BubbleWriteStarted() {
        // do all the UI changes such as loading indicator
        loadingView.startAnimating()
        play.isHidden = true
    }
    
    func BubbleWriteEnded() {
        loadingView.stopAnimating()
        play.isHidden = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        if(!recentChannels.contains(self.channelId)) {
            recentChannels.append(self.channelId)
            if(recentChannels.count > 25) {
                recentChannels.removeFirst()
            }
            recentChannelNumbers.append(self.channelNumber)
            if(recentChannelNumbers.count > 25) {
                recentChannelNumbers.removeFirst()
            }
        }
        
        let hasrated = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.RATED) as? Bool
        if (hasrated == nil || hasrated == false) {
            if let lastRateUsDate = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.LAST_RATE_US_DATE) as? Date {
                if(Date().daysFrom(lastRateUsDate) >= 2) {
                    showRateUsAlert()
                    UserDefaults.standard.set(Date(), forKey: GlobalConstants.UserDefaults.LAST_RATE_US_DATE)
                }
                
            } else {
                if let playcounter = UserDefaults.standard.value(forKey: GlobalConstants.UserDefaults.PLAY_COUNTER) as? Int {
                    UserDefaults.standard.set(playcounter+1, forKey: GlobalConstants.UserDefaults.PLAY_COUNTER)
                    if playcounter == 4 {
                        showRateUsAlert()
                        UserDefaults.standard.set(Date(), forKey: GlobalConstants.UserDefaults.LAST_RATE_US_DATE)
                    }
                } else {
                    UserDefaults.standard.set(1, forKey: GlobalConstants.UserDefaults.PLAY_COUNTER)
                    UserDefaults.standard.set(false, forKey: GlobalConstants.UserDefaults.RATED)
                }
            }
        }
        logEventOnServer()
    }
    
    func logEventOnServer() {
        let bubbleAPI = CallBubbleApi()
        bubbleAPI.delegate = self
        var params: [String: String] = [:]
        params["method"] = GlobalConstants.HttpMethodName.BUBBLE_EVENT_LOG
        params["email_id"] = UserData.sharedInstance.userEmail
        params["event"] = "WatchOnTV"
        params["label"] = "ChannelChange"
        params["channelid"] = self.channelId
        params["programid"] = self.programId
        params["source"] = "iOSHomePage"
        params["macid"] = UserData.sharedInstance.bubbleMAC
        bubbleAPI.post(params)
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        //do nothing
    }
    
    func onNetworkError(methodName: String) {
        //do nothing
    }
    
    func showRateUsAlert() {
        let alert = UIAlertController(title: "Help spread the word", message: "If you have been enjoying the Bubble experience, consider rating us on Amazon", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Rate Now", style: .default) {
            (_)-> Void in
            UserDefaults.standard.set(true, forKey: GlobalConstants.UserDefaults.RATED)
            UIApplication.shared.open(URL(string: GlobalConstants.SocialMediaIds.AMAZON_RATE_PRODUCT)!, options: [:], completionHandler: nil)
        }
        alert.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "May be Later", style: .default, handler: nil)
        alert.addAction(cancelAction)
        if let tv = self.superview?.superview as? UITableView {
            if let vc = tv.dataSource as? UIViewController {
                vc.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func BubbleWriteEndedWithError() {
        loadingView.stopAnimating()
        play.isHidden = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        if let tv = self.superview?.superview as? UITableView {
            if let vc = tv.dataSource as? UIViewController {
                vc.navigationController?.navigationBar.topItem?.title = ""
                let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main") as UIViewController
                
                //vc.present(viewController, animated: true, completion: nil)
                vc.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }        
    
    func showIMDBText() {
        imdbHeightConstraint.constant = 16
    }
    
    func hideIMDBText() {
        imdbHeightConstraint.constant = 0
    }
    
    func BubbleWriteBLEOff() {
        loadingView.stopAnimating()
        play.isHidden = false
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        if let tv = self.superview?.superview as? UITableView {
            if let vc = tv.dataSource as? UIViewController {
                let alert = UIAlertController(title: "Turn On Bluetooth", message: "Turn on Bluetooth to control your DTH from the app and try again!", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                vc.present(alert, animated: true, completion: nil)
            }
        }
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//    }
    
    func startCounter() {
//        for _ in minsOver...duration {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
//                sleep(60)
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.counter += 1
//                })
//            })
//        }
        
        postTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(ProgramDataTableViewCell.updateCounter), userInfo: nil, repeats: true)
    }
    
    func updateCounter() {
        if(counter < duration) {
            self.counter += 1
        } else {
            postTimer?.invalidate()
        }
    }
    
    func setProgramData(_ programStartTime: String, programDuration: Int, channelNumber: String, channelId: String, chanName: String) {
        self.programStartTime = programStartTime
        self.programDuration = programDuration
        bubbleDateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
        self.startDate = bubbleDateFormat.date(from: self.programStartTime)
        self.duration = self.programDuration
        self.channelNumber = channelNumber
        self.channelId = channelId
        self.channelName = chanName
        self.minsOver = Date().minutesFrom(self.startDate)
        if(minsOver < duration) {
            counter = minsOver
            startCounter()
        } else {
            counter = duration
        }
    }
    
    func setHDData(hdProgram: NSManagedObject) {
        self.hdProgram = hdProgram as! Programs
    }
    
    func setSDData(sdProgram: NSManagedObject) {
        self.sdProgram = sdProgram as! Programs
    }
    
    func setNextHDProgram(nHDProgram : NSManagedObject) {
        self.nextHDprogram = nHDProgram as! Programs
    }
    
    func setNextSDProgram(nSDProgram: NSManagedObject) {
        self.nextSDProgram = nSDProgram as! Programs
    }
    
    func setLaterHDProgram(lHDProgram: NSManagedObject) {
        self.laterHDProgram = lHDProgram as! Programs
    }
    
    func setLaterSDProgram(lSDProgram: NSManagedObject) {
        self.laterSDProgram = lSDProgram as! Programs
    }
    
    func HDTapped(recognizer: UITapGestureRecognizer) {
        self.setHDSelected()
        //self.channelName.text = self.hdProgram?.channelName!
        
        if let _ = self.nextHDprogram {
            if let nextdate = bubbleDateFormat.date(from: (self.nextHDprogram?.startTime!)!) {
                let nextdatestring = dformat.string(from: nextdate)
                self.programNext.text = nextdatestring + " | " + (self.nextHDprogram?.programName!)!
            }
        } else {
            self.programNext.text = ""
        }
        
        if let _ = self.laterHDProgram {
            if let laterdate = bubbleDateFormat.date(from: (self.laterHDProgram?.startTime)!) {
                let laterdatestring = dformat.string(from: laterdate)
                self.programLater.text = laterdatestring + " | " + (self.laterHDProgram?.programName!)!
            }
        } else {
            self.programLater.text = ""
        }
        
        self.channelId = self.hdProgram?.channelId
        self.channelName = self.hdProgram?.channelName!
        self.channelNumber = self.hdProgram?.channelNum
        
        if let chnlid = self.hdProgram?.channelId {
            let urlstring = GlobalConstants.BubbleAPI.BUBBLE_URL_PREFIX + "/images/channels_logo/" + chnlid + ".png"
            let url = URL(string: urlstring)
            
            DispatchQueue.global(qos: .userInteractive).async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
                DispatchQueue.main.async(execute: {
                    self.channelLogo.image = UIImage(data: data!)
                });
            }
        }
    }
    
    func SDTapped(recognizer: UITapGestureRecognizer) {
        self.setSDSelected()
        //self.channelName.text = self.sdProgram?.channelName!
        
        if let _ = self.nextSDProgram {
            if let nextdate = bubbleDateFormat.date(from: (self.nextSDProgram?.startTime!)!) {
                let nextdatestring = dformat.string(from: nextdate)
                self.programNext.text = nextdatestring + " | " + (self.nextSDProgram?.programName!)!
            }
        } else {
            self.programNext.text = ""
        }
        
        if let _ = self.laterSDProgram {
            if let laterdate = bubbleDateFormat.date(from: (self.laterSDProgram?.startTime)!) {
                let laterdatestring = dformat.string(from: laterdate)
                self.programLater.text = laterdatestring + " | " + (self.laterSDProgram?.programName!)!
            }
        } else {
            self.programLater.text = ""
        }
        
        self.channelId = self.sdProgram?.channelId
        self.channelName = self.sdProgram?.channelName!
        self.channelNumber = self.sdProgram?.channelNum
        
        if let chnlid = self.sdProgram?.channelId {
            let urlstring = GlobalConstants.BubbleAPI.BUBBLE_URL_PREFIX + "/images/channels_logo/" + chnlid + ".png"
            let url = URL(string: urlstring)
            
            DispatchQueue.global(qos: .userInteractive).async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
                DispatchQueue.main.async(execute: {
                    self.channelLogo.image = UIImage(data: data!)
                });
            }
        }
    }
    
    
    func setHDSelected() {
        hdLabel.layer.borderColor = UIColor.BubbleBlue().cgColor
        hdLabel.backgroundColor = UIColor.BubbleBlue()
        
        sdLabel.layer.borderColor = UIColor.BubbleOffWhite().cgColor
        sdLabel.backgroundColor = UIColor.clear
    }
    
    func setSDSelected() {
        sdLabel.layer.borderColor = UIColor.BubbleBlue().cgColor
        sdLabel.backgroundColor = UIColor.BubbleBlue()
        
        hdLabel.layer.borderColor = UIColor.BubbleOffWhite().cgColor
        hdLabel.backgroundColor = UIColor.clear
        //hdLabel.backgroundColor = UIColor.clearColor()
    }
    
    
}
