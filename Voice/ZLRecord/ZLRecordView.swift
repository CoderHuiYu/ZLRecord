//
//  RecordView.swift
//  Voice
//
//  Created by Jeffery on 2018/11/27.
//  Copyright © 2018 Jeffery. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation
import QuartzCore

let kFloatRecordImageUpTime  = 0.5
let kFloatRecordImageRotateTime = 0.17
let kFloatRecordImageDownTime = 0.5
let kFloatGarbageAnimationTime = 0.3
let kFloatGarbageBeginY : CGFloat = 45.0
let kFloatCancelRecordingOffsetX  : CGFloat = 100.0
let kFloatLockViewHeight : CGFloat  = 120.0
let kFloatLockViewWidth : CGFloat  = 40.0
let commonBlueColor : UIColor = UIColor.init(red: 50/255.0, green: 146/255.0, blue: 244/255.0, alpha: 1)
let kFloatSentButtonWidth : CGFloat = 30

@objc protocol ZLRecordViewProtocol: NSObjectProtocol{
    //return the recode voice data
    func zlRecordFinishRecordVoice(didFinishRecode voiceData: NSData)
    
    // record canceled
    @objc optional func zlRecordCanceledRecordVoice()
}

class ZLRecordView: UIView {
    fileprivate var playTimer: Timer?
    fileprivate var docmentFilePath: String?
    fileprivate var recorder: AVAudioRecorder?
    fileprivate var playTime: Int = 0

    
    var voiceData: NSData?
    weak var delegate: ZLRecordViewProtocol?
    var isFinished : Bool = false
    var lastDate : NSDate?
    
    var trackTouchPoint : CGPoint?
    var firstTouchPoint : CGPoint?
    var isCanceled : Bool = false      //is canceled
    var timeCount : Int = 0
    
    
    //MARK: == init the view
    lazy var placeholdLabel : UILabel = {
        let placeholdLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: self.frame.height))
        placeholdLabel.backgroundColor = self.backgroundColor
        return placeholdLabel
    }()
    
    lazy var cancelButton : UIButton = {
       let btn = UIButton.init(frame: CGRect.init(x:(frame.size.width - 100)/2, y: 0, width: 100, height: frame.size.height))
        btn.isHidden = true
        btn.setTitle(NSLocalizedString("ZL_CANCEL", comment: "cancel"), for: UIControl.State.normal)
        btn.setTitleColor(commonBlueColor, for: UIControl.State.normal)
        btn.addTarget(self, action: #selector(cancelRecordVoice), for: UIControl.Event.touchUpInside)
        return btn
    }()
    
    @objc func cancelRecordVoice() {
        sendButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 1.0) {
            self.cancelButton.alpha = 0
            self.cancelButton.isHidden = true
            self.sendButton.alpha = 0
        }
        recordCanceled()
    }
    
    lazy var sendButton : UIButton = {
        let gap = (frame.size.height - kFloatSentButtonWidth)/2
        let btn = UIButton.init(frame: CGRect(x: frame.size.width - kFloatSentButtonWidth - gap, y: gap, width: kFloatSentButtonWidth, height: kFloatSentButtonWidth))
        btn.backgroundColor = commonBlueColor
        btn.setImage(UIImage.init(named: "send"), for: UIControl.State.normal)
        btn.isHidden = true
        btn.addTarget(self, action: #selector(sendVoice), for: UIControl.Event.touchUpInside)
        btn.layer.cornerRadius = kFloatSentButtonWidth / 2
        btn.layer.masksToBounds = true
        return btn
    }()
    
    lazy var shimmerView :ShimmeringView = {
        let shimmerView = ShimmeringView.init(frame: CGRect.init(x: 100 + kScreenWidth, y: 0, width: self.frame.size.width-100 - 100, height: self.frame.size.height))
        let zlSliderView = ZLSlideView.init(frame: shimmerView.bounds)
        shimmerView.contentView = zlSliderView
        
        shimmerView.shimmerDirection = .left
        shimmerView.shimmerSpeed = 60
        shimmerView.shimmerAnimationOpacity = 0.3
        shimmerView.shimmerPauseDuration = 0.2
        shimmerView.isShimmering = true
        return shimmerView
    }()
    
    lazy var recordButton: UIButton = {
        let recordButton = UIButton.init(frame: CGRect(x: frame.size.width-self.frame.size.height, y: 0, width: self.frame.size.height, height: self.frame.size.height))        
        recordButton.backgroundColor = self.backgroundColor
        recordButton.setImage(UIImage.init(named: "ButtonMic7"), for:UIControl.State.normal)
        recordButton.addTarget(self, action: #selector(recordStartRecordVoice(sender:event:)), for: .touchDown)
        recordButton.addTarget(self, action: #selector(recordMayCancelRecordVoice(sender:event:)), for: .touchDragInside)
        recordButton.addTarget(self, action: #selector(recordMayCancelRecordVoice(sender:event:)), for: .touchDragOutside)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchCancel)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchUpOutside)
        return recordButton
    }()
    
    func resetRecordButtonTarget() {
        recordButton.addTarget(self, action: #selector(recordStartRecordVoice(sender:event:)), for: .touchDown)
        recordButton.addTarget(self, action: #selector(recordMayCancelRecordVoice(sender:event:)), for: .touchDragInside)
        recordButton.addTarget(self, action: #selector(recordMayCancelRecordVoice(sender:event:)), for: .touchDragOutside)
        
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchCancel)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchUpOutside)
    }
    
    lazy var leftTipImageView : UIImageView  = {
        let leftTipImageView = UIImageView.init(frame: CGRect.init(x:8, y: self.frame.size.height/2 - 28/2, width: 28 , height: 28))
        var leftTipImage =  UIImage.init(named: "button_mic_white")
        leftTipImage = leftTipImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        leftTipImageView.image = leftTipImage
        leftTipImageView.contentMode = .scaleAspectFit
        leftTipImageView.isHidden = true
        leftTipImageView.tintColor = UIColor.lightGray
        return leftTipImageView
    }()
    
     lazy var garbageView : ZLGarbageView = {
        let garbageView = ZLGarbageView.init(frame: CGRect.init(x: self.leftTipImageView.center.x - 15/2, y: kFloatGarbageBeginY, width: 30, height: self.frame.height))
        garbageView.isHidden = true
        return garbageView
    }()
    
    lazy var timeLabel:UILabel = {
        let timeLabel = UILabel.init(frame: CGRect.init(x: 45 , y: 0, width: 60, height: self.frame.height))
        timeLabel.textColor = UIColor.black
        timeLabel.backgroundColor = self.backgroundColor
        timeLabel.text = "0:00"
        timeLabel.font = UIFont.systemFont(ofSize: 18)
        timeLabel.isHidden = true
        return timeLabel
    }()
    
    lazy var lockView : ZLLockView = {
        let lockView = ZLLockView.init(frame: CGRect.init(x: self.frame.size.width-kFloatLockViewWidth, y: 0, width: kFloatLockViewWidth, height: kFloatLockViewHeight))
        lockView.backgroundColor = UIColor.white
        lockView.layer.borderWidth = 1
        lockView.layer.borderColor = UIColor.init(red: 200/255.0, green:  200/255.0, blue:  200/255.0, alpha: 1).cgColor
        lockView.layer.cornerRadius = kFloatLockViewWidth / 2
        lockView.layer.masksToBounds = true
        lockView.isHidden = true
        return lockView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = UIColor.init(displayP3Red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)
        insertSubview(lockView, belowSubview: recordButton)
        addSubview(shimmerView)
        addSubview(placeholdLabel)
        addSubview(leftTipImageView)
        addSubview(garbageView)
        addSubview(timeLabel)
        addSubview(recordButton)
        addSubview(sendButton)
        addSubview(cancelButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    //MARK: == show view and animation
    func showLockView()  {
        lockView.isHidden = false
        lockView.lockAnimationView.addAnimation()
        UIView.animate(withDuration: 0.5, animations: {
            let originFrame = self.lockView.frame
            let lockViewFrame = CGRect.init(x:originFrame.origin.x, y: -originFrame.height+30, width: originFrame.size.width, height: originFrame.size.height)
            self.lockView.frame = lockViewFrame;
        }) { (finish) in
            
        }
    }
    
    func showSliderView() {
        
        shimmerView.isHidden = false
        shimmerView.alpha = 1
        
        leftTipImageView.alpha = 1.0;
        leftTipImageView.isHidden = false
        
        let shimmerViewFrame = CGRect(x: 100, y: 0, width: shimmerView.frame.size.width, height: shimmerView.frame.size.height)
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveLinear, animations: {
            self.shimmerView.frame = shimmerViewFrame
        }, completion: nil)
    }
    
    //leftTipImageView layer animation
    func showleftTipImageViewGradient() {
        
        let basicAnimtion: CABasicAnimation = CABasicAnimation.init(keyPath: "opacity")
        basicAnimtion.repeatCount = MAXFLOAT
        basicAnimtion.duration = 1.0
        basicAnimtion.autoreverses = true
        basicAnimtion.fromValue = 1.0
        basicAnimtion.toValue = 0.1
        self.leftTipImageView.layer.add(basicAnimtion, forKey: "opacity")
    }
    
    //show garbageView
    func showGarbage() {
        garbageView.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            let transFormNew = CGAffineTransform.init(rotationAngle: CGFloat(-1 * Double.pi / 2))
            self.garbageView.headerView.transform  = transFormNew
            var orgFrame = self.garbageView.frame
            orgFrame.origin.y = (self.bounds.height - orgFrame.size.height) / 2
            self.garbageView.frame = orgFrame
            
        }) { (finish) in
        }
    }
    
    //recordButton‘s animation :  rotate And move
    func showLeftTipImageViewAnimation() {
        
        let orgFrame = self.leftTipImageView.frame
        
        UIView.animate(withDuration: kFloatRecordImageUpTime, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            
            var frame = self.leftTipImageView.frame
            frame.origin.y -= (1.5 * self.leftTipImageView.frame.height)
            self.leftTipImageView.frame = frame;
            
        }) { (finish) in
            self.showGarbage()
            UIView.animate(withDuration: kFloatRecordImageRotateTime, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                let transFormNew = CGAffineTransform.init(rotationAngle: CGFloat(-1 * Double.pi))
                self.leftTipImageView.transform  = transFormNew
                
            }) { (finish) in
                
                UIView.animate(withDuration: kFloatRecordImageDownTime, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    self.leftTipImageView.frame = orgFrame

                }) { (finish) in
                    self.leftTipImageView.transform = CGAffineTransform.identity
                    self.leftTipImageView.isHidden = true
                    self.dismissGarbage()
                }
            }
        }
    }
    
    //dismiss Garbageview
    func dismissGarbage() {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.garbageView.headerView.transform = CGAffineTransform.identity
            var orgFrame = self.garbageView.frame
            orgFrame.origin.y = kFloatGarbageBeginY
            self.garbageView.frame = orgFrame
        }){(finish) in
            self.garbageView.isHidden = true
            self.leftTipImageView.isHidden = true
            self.garbageView.frame = CGRect.init(x: self.leftTipImageView.center.x - 15/2, y: kFloatGarbageBeginY, width: 30, height: self.frame.height)
            self.resetCancelStatusView()         
        }
    }
    
    func resetLockView() {
        lockView.isHidden = true
        
        lockView.resetLockViewImageTint()
        lockView.layer.removeAllAnimations()
        let originFrame = CGRect.init(x: self.frame.size.width-kFloatLockViewWidth, y: 0, width: kFloatLockViewWidth, height: kFloatLockViewHeight)
        lockView.frame = originFrame;
    }
    
    func resetLeftTipImageView() {
        leftTipImageView.isHidden = true
        leftTipImageView.frame = CGRect.init(x:8, y: self.frame.size.height/2 - 28/2, width: 28, height: 28)
        leftTipImageView.layer.removeAllAnimations()
    }
    
    func resetShimmerView() {
        shimmerView.isHidden = true
        shimmerView.isShimmering = true
        let shimmerViewFrame = CGRect(x: 100 + kScreenWidth , y: 0, width: shimmerView.frame.size.width, height: shimmerView.frame.size.height)
        self.shimmerView.frame = shimmerViewFrame
        
        let zlSlideView = shimmerView.contentView as! ZLSlideView
        zlSlideView.resetFrame()
    }
    
    func resetTimeLabel() {
        timeLabel.isHidden = true
        timeLabel.text = "0:00"
    }
    
    func resetCancelButton() {
        cancelButton.isHidden = true
        cancelButton.alpha = 1
    }
    
    func resetFinishStatusView() {
        recordButton.isHidden = false
        sendButton.isHidden = true
        sendButton.isUserInteractionEnabled = true
        resetLeftTipImageView()
        resetShimmerView()
        resetTimeLabel()
        resetLockView()
        resetCancelButton()
    }
    
    func resetCancelStatusView() {
        recordButton.isHidden = false
        sendButton.isUserInteractionEnabled = true
        sendButton.isHidden = true
        sendButton.alpha = 1
//        resetLockView()
        resetTimeLabel()
        resetShimmerView()
        resetCancelButton()
    }
    
    //MARK: == cancel the record
    // cancle record
    func recordCanceled() {
       
        print("isCanceled")
        self.timeCount = 0
        
        //record stoped and delete the record
        if (playTimer != nil) {
            recorder?.stop()
            recorder?.deleteRecording()
            playTimer?.invalidate()
            playTimer = nil
        }
        resetRecordButtonTarget()
        resetLockView()
        //show animation
        showLeftTipImageViewAnimation()
        //notice delegate
        guard let delegate = delegate else {
            return
        }
        if let noticeCancelRecord = delegate.zlRecordCanceledRecordVoice {
            noticeCancelRecord()
        }
    }
    
    //ended record
    func recordEnded()  {
        
        recorder?.stop()
        playTimer?.invalidate()
        playTimer = nil

        
        resetRecordButtonTarget()
        
        resetFinishStatusView()
//        let zlSliderView : ZLSlideView = self.shimmerView.contentView as! ZLSlideView
//        zlSliderView.resetFrame()
    }
    
}


  //MARK: == handle : click the recordButton and it's status
extension ZLRecordView {
    
    // 0 start record
    @objc func recordStartRecordVoice(sender senderA: UIButton, event eventA: UIEvent) {
        //0.avoid tap twice
        let curDate = NSDate.init()
        
        if lastDate != nil {
            if (curDate.timeIntervalSince1970 - lastDate!.timeIntervalSince1970 < 0.5) {
                lastDate = curDate
                return
            }
        }
       lastDate = curDate
        //1.get the trackPoint
        let touch : UITouch = (eventA.touches(for: senderA)?.first)!
        trackTouchPoint = touch.location(in: self)
        firstTouchPoint = trackTouchPoint;
        isCanceled = false;
        //2.start execut the animation
        showSliderView()
        //3.start record
        startRecord()
    }
    
    //1. recordMayCancel
    @objc func recordMayCancelRecordVoice(sender senderA: UIButton, event eventA: UIEvent) {
        
        let touch = eventA.touches(for: senderA)?.first
        let curPoint = touch?.location(in: self)
        guard curPoint != nil else {
            return
        }
        let zlSliderView : ZLSlideView = self.shimmerView.contentView as! ZLSlideView
        if curPoint!.x < recordButton.frame.origin.x {
            zlSliderView.updateLocation(curPoint!.x - self.trackTouchPoint!.x)
            shimmerView.alpha = (kFloatCancelRecordingOffsetX - (firstTouchPoint!.x - trackTouchPoint!.x))/kFloatCancelRecordingOffsetX
        }
        if (firstTouchPoint!.x - trackTouchPoint!.x) >= kFloatCancelRecordingOffsetX{
            if  timeCount >= 1{
                isCanceled = true
                senderA.cancelTracking(with: eventA)
                senderA.removeTarget(nil, action: nil, for: UIControl.Event.allEvents)
                self.recordCanceled()
            }
        }
        
        guard timeCount >= 1 else {
            trackTouchPoint = curPoint
            return
        }
        
        guard lockView.isHidden == false else {
            trackTouchPoint = curPoint
            return
        }
        
        let changeY = trackTouchPoint!.y - curPoint!.y
        print("changeY\(changeY)")
        if changeY >= 0{
            var originFrame = self.lockView.frame
            originFrame.origin.y -= changeY
            originFrame.size.height -= changeY
            if originFrame.size.height > kFloatLockViewWidth + 5 {
                lockView.frame = originFrame;
                lockView.lockAnimationView.arrowImageView.alpha = 0.7 * (kFloatLockViewWidth / (kFloatLockViewWidth + 5))
            }else {
                //lock animation
                lockView.lockAnimationView.arrowImageView.alpha = 0
//                senderA.cancelTracking(with: eventA)
                senderA.removeTarget(nil, action: nil, for: UIControl.Event.allEvents)
                sendButton.isHidden = false
                recordButton.isHidden = true
                shimmerView.isShimmering = false
                shimmerView.isHidden = true
                cancelButton.isHidden = false
                originFrame.size = CGSize.init(width: kFloatLockViewWidth, height: kFloatLockViewWidth)
                lockView.frame = originFrame;
                lockView.addBoundsAnimation()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (kBoundsAnimationDuration * 3)) {
                    self.resetLockView()
                }
            }
        }else {
            var originFrame = self.lockView.frame
            originFrame.origin.y -= changeY
            originFrame.size.height -= changeY
            if originFrame.size.height <= kFloatLockViewHeight {
                self.lockView.frame = originFrame;
            }
        }
        
        trackTouchPoint = curPoint
    }
    
    
    //2.finish Record Voice
    @objc func recordFinishRecordVoice(){
        print("~~~~~~~recordFinish-----0")
        guard isCanceled  == false else {
            return
        }
        print("~~~~~~~recordFinish-----1")
        recorder?.stop()
        playTimer?.invalidate()
        playTimer = nil
        
        recordEnded()
        isFinished = true
    }
    @objc private func sendVoice(){
        sendButton.isUserInteractionEnabled = false
        recordFinishRecordVoice()
    }
   
    //MARK: == handle recodr voice
    
    @objc private func countVoiceTime(){
        playTime = playTime + 1
        recordIsRecordingVoice(playTime)
        if playTime >= 60 {
            recordFinishRecordVoice()
        }
        print("~~~~~~~\(playTime)")
    }
    // is recording
    func recordIsRecordingVoice(_ recordTime: Int) {
        timeCount = recordTime
        if (timeCount == 1){
            showLockView()
        }
        print("timeCount= \(timeCount)")
        if recordTime < 10 {
            self.timeLabel.text = "0:0" + "\(recordTime)"
        }else{
            self.timeLabel.text = "0:" + "\(recordTime)"
        }
    }
    
    func startRecord() {
        leftTipImageView.tintColor = UIColor.lightGray
        print("startRecord")
        isCanceled = false
        playTime = 0
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        } catch let err{
            print("set type fail:\(err.localizedDescription)")
            return
        }
        //set session
        do {
            try audioSession.setActive(true)
        } catch let err {
            print("inital fail:\(err.localizedDescription)")
            return
        }
        //Compressed audio
        let recordSetting: [String : Any] = [AVEncoderAudioQualityKey:NSNumber(integerLiteral: AVAudioQuality.max.rawValue),AVFormatIDKey:NSNumber(integerLiteral: Int(kAudioFormatMPEG4AAC)),AVNumberOfChannelsKey:1,AVLinearPCMBitDepthKey:8,AVSampleRateKey:NSNumber(integerLiteral: 44100)]
        let docments = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        let fileNameString = String(Int(Date.timeIntervalBetween1970AndReferenceDate))
        docmentFilePath = docments! + "/\(fileNameString).caf" //Set storage address
        do {
            let url = NSURL.fileURL(withPath: docmentFilePath!)
            recorder = try AVAudioRecorder(url: url, settings: recordSetting)
            recorder?.delegate = self
            recorder!.prepareToRecord()
            recorder?.isMeteringEnabled = true
        } catch let err {
            print("record fail:\(err.localizedDescription)")
        }
    
       
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            self.timeLabel.isHidden = false
            self.leftTipImageView.tintColor = UIColor.red
            //show the animation
            self.showleftTipImageViewGradient()
            self.recorder?.record()
            if self.playTimer == nil {
                self.playTimer = Timer.init(timeInterval: 1, target: self, selector: #selector(self.countVoiceTime), userInfo: nil, repeats: true)
            }
            RunLoop.main.add(self.playTimer!, forMode: RunLoop.Mode.common)
        }
    }
}

extension ZLRecordView: AVAudioRecorderDelegate{
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let url = NSURL.fileURL(withPath: docmentFilePath!)
        do{
            let audioData = try  NSData(contentsOfFile: url.path, options: [])
            if isFinished && (isCanceled == false) && (timeCount >= 1) {
                isFinished = false
                timeCount = 0
                self.delegate?.zlRecordFinishRecordVoice(didFinishRecode: audioData)
            }
        } catch let err{
            print("record fail:\(err.localizedDescription)")
        }
    }
}

