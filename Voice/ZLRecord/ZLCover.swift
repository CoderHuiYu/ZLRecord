//
//  ZLCover.swift
//  Voice
//
//  Created by 余辉 on 2018/12/6.
//  Copyright © 2018年 Tyoung. All rights reserved.
//

import UIKit
let kTipWidth : CGFloat = 120
var tipLabel : UILabel?

class ZLCover: UIView {
    
    class func showTip(_ title : String) {
        let window = UIApplication.shared.keyWindow
        if tipLabel == nil {
            tipLabel = UILabel.init(frame: CGRect.init(x: (kScreenWidth - kTipWidth)/2, y: (kScreenHeight - kTipWidth - kNavHeight)/2, width: kTipWidth, height: kTipWidth))
            tipLabel?.layer.cornerRadius = 5
            tipLabel?.layer.masksToBounds = true
            tipLabel?.textColor = UIColor.white
            tipLabel?.textAlignment = NSTextAlignment.center
            tipLabel?.font = UIFont.systemFont(ofSize: 50, weight: UIFont.Weight.bold)
            tipLabel?.backgroundColor = RGBColor(r: 100, g: 100, b: 100).withAlphaComponent(0.4)
            window?.addSubview(tipLabel!)
        }
        tipLabel?.text = title
    }
    
    class func showTip(_ title : String,font : CGFloat,textColor : UIColor) {
        let window = UIApplication.shared.keyWindow
        if tipLabel == nil {
            tipLabel = UILabel.init(frame: CGRect.init(x: (kScreenWidth - kTipWidth)/2, y: (kScreenHeight - kTipWidth - kNavHeight)/2, width: kTipWidth, height: kTipWidth))
            tipLabel?.layer.cornerRadius = 5
            tipLabel?.layer.masksToBounds = true
            tipLabel?.textColor = UIColor.white
            tipLabel?.textAlignment = NSTextAlignment.center
            tipLabel?.font = UIFont.systemFont(ofSize: 50, weight: UIFont.Weight.bold)
            tipLabel?.backgroundColor = RGBColor(r: 100, g: 100, b: 100).withAlphaComponent(0.4)
            window?.addSubview(tipLabel!)
        }
        tipLabel?.textColor = textColor
        tipLabel?.font = UIFont.systemFont(ofSize: font)
        tipLabel?.text = title
    }
    
  
    class func hideTip() {
        tipLabel?.removeFromSuperview()
        tipLabel = nil
    }
}
extension  UIView{
    func show(_ title : String){
        ZLCover.showTip(title)
    }
    func show(_ title : String,_ font : CGFloat,_ textColor : UIColor){
        ZLCover.showTip(title, font: font, textColor: textColor)
    }
    func hide(){
        ZLCover.hideTip()
    }
}
