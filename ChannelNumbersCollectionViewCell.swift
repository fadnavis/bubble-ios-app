//
//  ChannelNumbersCollectionViewCell.swift
//  Bubble
//
//  Created by Harsh Fadnavis on 10/13/16.
//  Copyright © 2016 Harsh Fadnavis. All rights reserved.
//

import UIKit

class ChannelNumbersCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var channelNumber: UILabel!
    @IBOutlet weak var channelName: UILabel!
    
    override var isSelected: Bool {
        didSet {
            self.channelNumber.textColor = isSelected ? UIColor.BubbleYellow() : UIColor.BubbleOffWhite2()
            self.channelName.textColor = isSelected ? UIColor.BubbleYellow() : UIColor.BubbleOffWhite2()
        }
    }
    
}
