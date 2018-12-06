//
//  Common.swift
//  Voice
//
//  Created by zhoukai on 2018/12/4.
//  Copyright © 2018 Tyoung. All rights reserved.
//

import Foundation
import UIKit

let kScreenWidth = UIScreen.main.bounds.size.width
let kScreenHeight = UIScreen.main.bounds.size.height

let iPhoneX = UIScreen.main.bounds.size.height >= 812 ? true : false
let kNavHeight: CGFloat = iPhoneX ? 88.0 : 64.0
let kStatusHeight: CGFloat = iPhoneX ? 44 : 20

func RGBColor(r :CGFloat ,g:CGFloat,b:CGFloat) ->UIColor{
    return UIColor.init(red: r/255.0, green: g/255.0, blue: b/255.0, alpha: 1);
}
func COLORFROMHEX(_ h:Int) ->UIColor {
    return RGBColor(r: CGFloat(((h)>>16) & 0xFF), g: CGFloat(((h)>>8) & 0xFF), b: CGFloat((h) & 0xFF))
}

func iphonePlatform() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    
    let platform = withUnsafePointer(to: &systemInfo.machine.0) { ptr in
        return String(cString: ptr)
    }
    return platform
}

func deviceOldThan(device: Int) -> Bool {
    let platform = iphonePlatform()
    let preString = platform.components(separatedBy: ",").first
    let resultString = preString?.components(separatedBy: "e").last
    guard let reslut = resultString else { return true }
    guard let type = Int(reslut) else { return true }
    if type > device {
        return false
    }
    return true
}

func iphoneType() ->String {

    let platform = iphonePlatform()
    if platform == "iPhone1,1" { return "iPhone 2G"}
    if platform == "iPhone1,2" { return "iPhone 3G"}
    if platform == "iPhone2,1" { return "iPhone 3GS"}
    if platform == "iPhone3,1" { return "iPhone 4"}
    if platform == "iPhone3,2" { return "iPhone 4"}
    if platform == "iPhone3,3" { return "iPhone 4"}
    if platform == "iPhone4,1" { return "iPhone 4S"}
    if platform == "iPhone5,1" { return "iPhone 5"}
    if platform == "iPhone5,2" { return "iPhone 5"}
    if platform == "iPhone5,3" { return "iPhone 5C"}
    if platform == "iPhone5,4" { return "iPhone 5C"}
    if platform == "iPhone6,1" { return "iPhone 5S"}
    if platform == "iPhone6,2" { return "iPhone 5S"}
    if platform == "iPhone7,1" { return "iPhone 6 Plus"}
    if platform == "iPhone7,2" { return "iPhone 6"}
    if platform == "iPhone8,1" { return "iPhone 6S"}
    if platform == "iPhone8,2" { return "iPhone 6S Plus"}
    if platform == "iPhone8,4" { return "iPhone SE"}
    if platform == "iPhone9,1" { return "iPhone 7"}
    if platform == "iPhone9,2" { return "iPhone 7 Plus"}
    if platform == "iPhone10,1" { return "iPhone 8"}
    if platform == "iPhone10,2" { return "iPhone 8 Plus"}
    if platform == "iPhone10,3" { return "iPhone X"}
    if platform == "iPhone10,4" { return "iPhone 8"}
    if platform == "iPhone10,5" { return "iPhone 8 Plus"}
    if platform == "iPhone10,6" { return "iPhone X"}


    if platform == "i386"   { return "iPhone Simulator"}
    if platform == "x86_64" { return "iPhone Simulator"}

    return platform
}


