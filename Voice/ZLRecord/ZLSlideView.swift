//
//  ZLSlideView.swift
//  Voice
//
//  Created by Jeffery on 2018/11/30.
//  Copyright © 2018年 Jeffery. All rights reserved.
//

import UIKit
protocol ZLSlideViewProtocol: NSObjectProtocol{
    func cancelRecordVoice()
}
class ZLSlideView: UIView {
    
    weak var delegate : ZLSlideViewProtocol?
    
    lazy var showLabel : UILabel = {
        let label = UILabel.init(frame: self.bounds)
        label.font = UIFont.systemFont(ofSize: 16)
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
      
        let attri : NSMutableAttributedString = NSMutableAttributedString.init(string: "滑动来取消")
        let  attach : NSTextAttachment = NSTextAttachment.init()
        attach.image = UIImage.init(named: "SlideArrow")
        attach.bounds = CGRect.init(x: 5, y:(17-self.frame.size.height/2)/2, width: 8, height: 17)
        let string = NSAttributedString.init(attachment: attach)
        attri.append(string)
        showLabel.attributedText = attri;
    }
    
    func resetFrame() {
        showLabel.frame = CGRect.init(origin: self.bounds.origin, size: self.bounds.size)
        addAttribute()
    }
    
    func updateLocation(_ offSetX : CGFloat) {
        var labelFrame = showLabel.frame
        labelFrame.origin.x += offSetX
        showLabel.frame = labelFrame
    }
    
    func changeStatus() {
        showLabel.text = "取消"
        showLabel.isUserInteractionEnabled = true
        showLabel.textColor = commonBlueColor

        let tap : UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action:#selector(canelRecord))
        showLabel.addGestureRecognizer(tap)
    }
    
    func resetShowLableText() {
        addAttribute()
        showLabel.font = UIFont.systemFont(ofSize: 16)
        showLabel.textColor = UIColor.init(red: 20/255.0, green: 20/255.0, blue: 20/255.0, alpha: 1)
        showLabel.textAlignment = NSTextAlignment.center
        showLabel.isUserInteractionEnabled = false
    }
    
    @objc func canelRecord() {
        guard let delegate = delegate else {return}
        delegate.cancelRecordVoice()
    }
}

extension UIImage{
    
    /// 更改图片颜色
    public func imageWithTintColor(color : UIColor) -> UIImage{
        UIGraphicsBeginImageContext(self.size)
        color.setFill()
        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIRectFill(bounds)
        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)
        
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
}
