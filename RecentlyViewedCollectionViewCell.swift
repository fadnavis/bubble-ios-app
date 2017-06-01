//
//  RecentlyViewedCollectionViewCell.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/9/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class RecentlyViewedCollectionViewCell: UICollectionViewCell, BubbleWriteProcessDelegate {
    
    @IBOutlet weak var channelLogo: UIImageView!
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    @IBOutlet weak var transView: UIView!
    
    var channelNumber: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playOnTV(recognizer:)))
        channelLogo.addGestureRecognizer(tapGesture)
        channelLogo.isUserInteractionEnabled = true
    }
    
    func playOnTV(recognizer: UITapGestureRecognizer) {
        var characters = self.channelNumber.characters.map { String($0) }
        characters.append(GlobalConstants.RemoteCodes.SELECT)
        BluetoothSerialMain.sharedInstance.setWriteProcessDelegate(delegate: self)
        BluetoothSerialMain.sharedInstance.setRemoteCodes(codeArray: characters, medium: "STB")
        BluetoothSerialMain.sharedInstance.startProcessBubble()
    }
    
    func BubbleWriteStarted() {
        loadingView.startAnimating()
        transView.isHidden = false
    }
    
    func BubbleWriteEnded() {
        loadingView.stopAnimating()
        transView.isHidden = true
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
    }
    
    func BubbleWriteEndedWithError() {
        loadingView.stopAnimating()
        transView.isHidden = true
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        if let cv = self.superview as? UICollectionView {
            if let vc = cv.dataSource as? UIViewController {
                let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "configBubble_main") as UIViewController
                //vc.present(viewController, animated: true, completion: nil)
                vc.navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }
    
    func BubbleWriteBLEOff() {
        loadingView.stopAnimating()
        transView.isHidden = true
        BluetoothSerialMain.sharedInstance.removeWriteProcessDelegate()
        if let cv = self.superview as? UICollectionView {
            if let vc = cv.dataSource as? UIViewController {
                let alert = UIAlertController(title: "Turn On Bluetooth", message: "Turn on Bluetooth to control your DTH from the app and try again!", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alert.addAction(okAction)
                vc.present(alert, animated: true, completion: nil)
            }
        }

    }
}
