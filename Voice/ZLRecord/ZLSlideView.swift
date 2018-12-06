//
//  ZLSlideView.swift
//  Voice
//
//  Created by Jeffery on 2018/11/30.
//  Copyright © 2018年 Jeffery. All rights reserved.
//

import UIKit
let kLabelFont : CGFloat = 16
protocol ZLSlideViewProtocol: NSObjectProtocol{
    func cancelRecordVoice()
}
class ZLSlideView: UIView {
    
    weak var delegate : ZLSlideViewProtocol?
    
    lazy var showLabel : UILabel = {
        let label = UILabel.init(frame: self.bounds)
        label.font = UIFont.systemFont(ofSize: kLabelFont)
        label.textColor = UIColor.init(red: 20/255.0, green: 20/255.0, blue: 20/255.0, alpha: 1)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addSubview(showLabel)
        addAttribute()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAttribute() {
      
        let attri : NSMutableAttributedString = NSMutableAttributedString.init(string: NSLocalizedString("ZL_SWIPE_TO_CANCEL", comment: "Swipe to cancel"))
        let  attach : NSTextAttachment = NSTextAttachment.init()
        attach.image = UIImage.init(named: "SlideArrow")
        attach.bounds = CGRect.init(x: 5, y:(17-self.frame.size.height/2)/2, width: 8, height: 17)
        let string = NSAttributedString.init(attachment: attach)
        attri.append(string)
        showLabel.attributedText = attri;
    }
    
    func resetFrame() {
        showLabel.frame = CGRect.init(origin: self.bounds.origin, size: self.bounds.size)
    }
    
    func updateLocation(_ offSetX : CGFloat) {
        var labelFrame = showLabel.frame
        labelFrame.origin.x += offSetX
        showLabel.frame = labelFrame
    }
}
