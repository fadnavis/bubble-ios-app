//
//  NextProgramsHeaderTableViewCell.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/21/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class NextProgramsHeaderTableViewCell: UITableViewCell, BubbleWriteProcessDelegate, BubbleAPIDelegate {
    
    @IBOutlet weak var background: UIImageView!
    
    //@IBOutlet weak var scroll: UIScrollView!
    
    @IBOutlet weak var loadingViewHeader: UIActivityIndicatorView!
    @IBOutlet weak var synopsis: UILabel!
    @IBOutlet weak var endsIn: UILabel!
    @IBOutlet weak var genre: UILabel!
    @IBOutlet weak var programName: UILabel!
    @IBOutlet weak var channelName: UILabel!
    @IBOutlet weak var channelLogo: UIImageView!
    @IBOutlet weak var imdbRating: UILabel!
    @IBOutlet weak var playButton: UIImageView!
    
    var channelNumber: String!
    var channelId: String!
    var programId: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let playGesture = UITapGestureRecognizer(target: self, action: #selector(play(recognizer:)))
        playButton.addGestureRecognizer(playGesture)
        playButton.isUserInteractionEnabled = true
    }
    
    
    func play(recognizer: UITapGestureRecognizer) {
        guard let channumber = channelNumber else {
            return
        }
        if(!BluetoothSerialMain.sharedInstance.getIsSending()) {
            var characters = channumber.characters.map { String($0) }
            characters.append(GlobalConstants.RemoteCodes.SELECT)
            BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
            BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: characters, medium: "STB")
            BluetoothSerialMain.sharedInstance.startProcessBubble()
        }
    }
    
    func BubbleWriteStarted() {
        loadingViewHeader.startAnimating()
        playButton.isHidden = true
    }
    
    func BubbleWriteEnded() {
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        loadingViewHeader.stopAnimating()
        playButton.isHidden = false
        if(!recentChannels.contains(self.channelId)) {
            recentChannels.append(self.channelId)
            if(recentChannels.count > 25) {
                recentChannels.removeFirst()
            }
            if let channum = self.channelNumber {
                recentChannelNumbers.append(channum)
                if(recentChannelNumbers.count > 25) {
                    recentChannelNumbers.removeFirst()
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
        params["source"] = "iOSSynopsisPage"
        params["macid"] = UserData.sharedInstance.bubbleMAC
        bubbleAPI.post(params)
    }
    
    func onResponseReceived(_ responseJSON: [String : AnyObject], methodName: String) {
        //do nothing
    }
    
    func onNetworkError(methodName: String) {
        //do nothing
    }
    
    func BubbleWriteEndedWithError() {
        playButton.isHidden = false
        loadingViewHeader.stopAnimating()
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main") as UIViewController
        //self.present(viewController, animated: true, completion: nil)
        if let tv = self.superview?.superview as? UITableView {
            if let vc = tv.dataSource as? UIViewController {
                vc.navigationController!.pushViewController(viewController, animated: true)
            }
        }
    }
    
    func BubbleWriteBLEOff() {
        playButton.isHidden = false
        loadingViewHeader.stopAnimating()
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        let alert = UIAlertController(title: "Turn On Bluetooth", message: "Turn on Bluetooth to control your DTH from the app and try again!", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        if let tv = self.superview?.superview as? UITableView {
            if let vc = tv.dataSource as? UIViewController {
                vc.present(alert, animated: true, completion: nil)
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
