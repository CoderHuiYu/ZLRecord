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
import AudioToolbox

let kFloatSliderShowTime : Double = 0.3
let kFloatSliderDissppearTime : Double = 0.2
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
var sysID:SystemSoundID = 0
let startPoint : CGPoint = CGPoint.init(x: kScreenWidth - 120, y: 20)
let notification = UINotificationFeedbackGenerator()

@objc protocol ZLRecordViewProtocol: NSObjectProtocol{
    //return the recode voice data
    func zlRecordFinishRecordVoice(didFinishRecode voiceData: NSData)
    
    // record canceled
    @objc optional func zlRecordCanceledRecordVoice()
}

class ZLRecordView: UIView {
    enum State { case closed, opening, open, closing }
    fileprivate var playTimer: Timer?
    fileprivate var docmentFilePath: String?
    fileprivate var recorder: AVAudioRecorder?
    fileprivate var playTime: Int = 0
    
    var voiceData: NSData?
    weak var delegate: ZLRecordViewProtocol?
    var curStartDate : Date?
    var curFinishDate : Date = Date.init()
    var lastFinishDate :Date?
    
  
    private var state: State = .closed
    private var lastState : State?
    private var trackTouchPoint : CGPoint?
    private var firstTouchPoint : CGPoint?
    private var timeCount : Int = 0
    private var shimmerWidth :CGFloat = 0.0
    private var _shimmerView : ShimmeringView?
    private var _beatImageView : UIImageView?
    private var _timeLabel : UILabel?
    
    private var isStarted :  Bool = false
    private var isCanceled : Bool = false      //is canceled
    private var isFinished : Bool = false
    
    //MARK: ============ init the view
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
    
    lazy var rightTipView: UIView = {
        let rightTipView = UIView()
        rightTipView.backgroundColor = commonBlueColor
        rightTipView.layer.cornerRadius = 12
        
        let tipLabel = UILabel()
        tipLabel.text = NSLocalizedString("ZL_RECORD_TAP_NOTICE", comment: "notice")
        tipLabel.textColor = UIColor.white
        tipLabel.font = UIFont.systemFont(ofSize: 14)
        tipLabel.sizeToFit()
        
        let cancelButtonBGView = UIView()
        cancelButtonBGView.backgroundColor = UIColor.white
        cancelButtonBGView.tintColor = commonBlueColor
        
        var cancelImageNormal = UIImage(named: "btn_cancel")
        cancelImageNormal = cancelImageNormal?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
     
        let closeButton = UIButton()
        closeButton.setImage(cancelImageNormal, for: .normal)
        closeButton.tintColor = commonBlueColor
        closeButton.addTarget(self, action: #selector(closeRightTipView), for: .touchUpInside)
        cancelButtonBGView.addSubview(closeButton)
        
        let spinnerView = UIImageView()
        spinnerView.tintColor = commonBlueColor
        var spinnerImage = UIImage(named: "abc_spinner_mtrl_am_alpha")
        spinnerImage = spinnerImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        spinnerView.image = spinnerImage
        spinnerView.sizeToFit()
        
        let tipViewWidth = 10 + tipLabel.frame.size.width + 10 + 20 + 10
        let tipViewHeight = CGFloat(40)
        rightTipView.frame = CGRect(x: kScreenWidth - tipViewWidth - 5, y: -tipViewHeight + 5, width: tipViewWidth, height: tipViewHeight)
        tipLabel.frame = CGRect(x: 10, y: tipViewHeight/2 - tipLabel.frame.size.height/2, width: tipLabel.frame.size.width, height: tipLabel.frame.size.height)
        cancelButtonBGView.frame = CGRect(x: tipLabel.frame.maxX + 10, y: tipViewHeight/2 - 18.0/2, width: 18, height: 18)
        closeButton.frame = CGRect(x: 2, y: 2, width: 14, height: 14)
        cancelButtonBGView.layer.cornerRadius = cancelButtonBGView.frame.size.width/2
        
        spinnerView.frame = CGRect(x: tipViewWidth - 33, y: 25, width: spinnerView.frame.size.width, height: spinnerView.frame.size.height)
        rightTipView.addSubview(tipLabel)
        rightTipView.addSubview(cancelButtonBGView)
        rightTipView.addSubview(spinnerView)
        
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(closeRightTipView))
        rightTipView.addGestureRecognizer(tap)
        rightTipView.isHidden = true
        return rightTipView
    }()
    
    var beatImageView : UIImageView  {
        if  _beatImageView == nil {
            _beatImageView = UIImageView.init(frame: CGRect.init(x:8, y: self.frame.size.height/2 - 28/2, width: 28 , height: 28))
            var leftTipImage =  UIImage.init(named: "button_mic_white")
            leftTipImage = leftTipImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            _beatImageView?.image = leftTipImage
            _beatImageView?.contentMode = .scaleAspectFit
            _beatImageView?.tintColor = UIColor.lightGray
            _beatImageView?.isHidden = true
        }
        return _beatImageView!
    }
    
    var shimmerView :ShimmeringView {
        if _shimmerView == nil {
            let textString = NSLocalizedString("ZL_SWIPE_TO_CANCEL", comment: "Swipe to cancel")
            shimmerWidth = self.getStringWidth(string: textString, font: UIFont.systemFont(ofSize: kLabelFont)) + 30
            _shimmerView = ShimmeringView.init(frame: CGRect.init(x: (kScreenWidth - shimmerWidth)/2, y: 0, width: shimmerWidth, height: self.frame.size.height))
            
            let zlSliderView = ZLSlideView.init(frame: _shimmerView!.bounds)
            _shimmerView?.contentView = zlSliderView
            _shimmerView?.shimmerDirection = .left
            _shimmerView?.shimmerSpeed = 60
            _shimmerView?.shimmerAnimationOpacity = 0.3
            _shimmerView?.shimmerPauseDuration = 0.2
            _shimmerView?.isShimmering = true
            _shimmerView?.isHidden = true
        }
        return _shimmerView!
    }
    
    lazy var garbageView : ZLGarbageView = {
        let garbageView = ZLGarbageView.init(frame: CGRect.init(x: self.beatImageView.center.x - 15/2, y: kFloatGarbageBeginY, width: 30, height: self.frame.height))
        garbageView.isHidden = true
        return garbageView
    }()
    
    var timeLabel:UILabel {
        if  _timeLabel == nil {
            _timeLabel = UILabel.init(frame: CGRect.init(x: 45 , y: 0, width: 45, height: self.frame.height))
            _timeLabel?.textColor = UIColor.black
            _timeLabel?.backgroundColor = self.backgroundColor
            _timeLabel?.text = "0:00"
            _timeLabel?.translatesAutoresizingMaskIntoConstraints = false
//            _timeLabel?.heightAnchor.constraint(equalToConstant: self.frame.height).isActive = true
            _timeLabel?.font = UIFont.systemFont(ofSize: 18)
            _timeLabel?.alpha = 0
        }
        return _timeLabel!
    }
    
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
    
    //MARK: ================== init frame =======
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = RGBColor(r: 245, g: 245, b: 245)
        addSubview(placeholdLabel)
        addSubview(garbageView)
        addSubview(timeLabel)
//        timeLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 45).isActive = true
        addSubview(sendButton)
        addSubview(cancelButton)
        addSubview(recordButton)
        insertSubview(lockView, belowSubview: recordButton)
        addSubview(rightTipView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resetRecordButtonTarget() {
        recordButton.addTarget(self, action: #selector(recordStartRecordVoice(sender:event:)), for: .touchDown)
        recordButton.addTarget(self, action: #selector(recordMayCancelRecordVoice(sender:event:)), for: .touchDragInside)
        recordButton.addTarget(self, action: #selector(recordMayCancelRecordVoice(sender:event:)), for: .touchDragOutside)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchCancel)
        recordButton.addTarget(self, action: #selector(recordFinishRecordVoice), for: .touchUpOutside)
    }
    
    @objc func cancelRecordVoice() {
        sendButton.isUserInteractionEnabled = false
        UIView.animate(withDuration: 1.0) {
            self.cancelButton.alpha = 0
            self.cancelButton.isHidden = true
            self.sendButton.alpha = 0
        }
        recordCanceled()
    }
    
    //MARK: ============ show view and animation
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
        beatImageView.alpha = 1.0;
        beatImageView.isHidden = false
        
        let shimmerViewFrame = CGRect.init(x: (kScreenWidth - shimmerWidth)/2 , y: 0, width: shimmerWidth, height: self.frame.size.height)
        UIView.animate(withDuration: kFloatSliderShowTime, delay: 0.0, options: UIView.AnimationOptions.curveLinear, animations: {
            self.shimmerView.frame = shimmerViewFrame
        }, completion: nil)
    }
    
    //beatImageView layer animation
    func showbeatImageViewGradient() {
        let basicAnimtion: CABasicAnimation = CABasicAnimation.init(keyPath: "opacity")
        basicAnimtion.repeatCount = MAXFLOAT
        basicAnimtion.duration = 1.0
        basicAnimtion.autoreverses = true
        basicAnimtion.fromValue = 1.0
        basicAnimtion.toValue = 0.1
        self.beatImageView.layer.add(basicAnimtion, forKey: "opacity")
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
    func showbeatImageViewAnimation() {
        let orgFrame = self.beatImageView.frame
        UIView.animate(withDuration: kFloatRecordImageUpTime, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            var frame = self.beatImageView.frame
            frame.origin.y -= (1.5 * self.beatImageView.frame.height)
            self.beatImageView.frame = frame;
        }) { (finish) in
            self.showGarbage()
            UIView.animate(withDuration: kFloatRecordImageRotateTime, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                let transFormNew = CGAffineTransform.init(rotationAngle: CGFloat(-1 * Double.pi))
                self.beatImageView.transform  = transFormNew
            }) { (finish) in
                UIView.animate(withDuration: kFloatRecordImageDownTime, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                    self.beatImageView.frame = orgFrame
                }) { (finish) in
                    self.beatImageView.transform = CGAffineTransform.identity
                    self.beatImageView.isHidden = true
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
            self.beatImageView.isHidden = true
            self.garbageView.frame = CGRect.init(x: self.beatImageView.center.x - 15/2, y: kFloatGarbageBeginY, width: 30, height: self.frame.height)
            self.resetCancelStatusView()         
        }
    }
    //MARK: ============== reset View ====
    func resetLockView() {
        lockView.isHidden = true
        lockView.resetLockViewImageTint()
        lockView.layer.removeAllAnimations()
        let originFrame = CGRect.init(x: self.frame.size.width-kFloatLockViewWidth, y: 0, width: kFloatLockViewWidth, height: kFloatLockViewHeight)
        lockView.frame = originFrame;
    }
    
    func resetbeatImageView() {
      beatImageView.removeFromSuperview()
      _beatImageView = nil
    }
    
    func resetShimmerView() {
        shimmerView.removeFromSuperview()
        _shimmerView = nil
    }
    
    func resetTimeLabel() {
        timeLabel.text = "0:00"
        timeLabel.alpha = 0
    }
    
    func resetCancelButton() {
        cancelButton.isHidden = true
        cancelButton.alpha = 1
    }
    
    func resetFinishStatusView() {
        recordButton.isHidden = false
        sendButton.isHidden = true
        sendButton.isUserInteractionEnabled = true
        resetbeatImageView()
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
        resetbeatImageView()
        resetTimeLabel()
        resetShimmerView()
        resetCancelButton()
        resetRecordButtonTarget()
    }
    
    //MARK: ============ Actions
    @objc func closeRightTipView() {
        if rightTipView.isHidden == false {
            UIView.animate(withDuration: 1) {
                self.rightTipView.alpha = 0
            }
        }
    }
    
    func showRightTipView() {
        
        if rightTipView.isHidden {
            self.rightTipView.isHidden = false
            self.rightTipView.alpha = 1
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                UIView.animate(withDuration: 1, animations: {
                    self.rightTipView.alpha = 0
                }, completion: { (finish) in
                    self.rightTipView.isHidden = true
                    self.rightTipView.alpha = 1
                })
                
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if point.y < 0 && point.y > -40 {
            return rightTipView
        } else {
            return super.hitTest(point, with: event)
        }
    }
    
    deinit{
        //release service
        AudioServicesDisposeSystemSoundID(sysID)
    }
    
    
    //MARK: ============ Tap RecordButton ---->  showView && hideView ============
    func showViewAndAnimation() {
        if state == .closing {
            shimmerView.removeFromSuperview()
            _shimmerView = nil
            _beatImageView?.removeFromSuperview()
            _beatImageView = nil
        }
        state = .opening
        insertSubview(shimmerView, belowSubview: recordButton)
        insertSubview(beatImageView, belowSubview: recordButton)
        self.shimmerView.isHidden = false
        self.beatImageView.isHidden = false
        let shimmerOrgFrame = shimmerView.frame
        var shimmerNowFrame = shimmerView.frame
        let beatImgViewOrgFrame = beatImageView.frame
        var beatImgViewNowFrame = beatImageView.frame
        shimmerNowFrame.origin.x = startPoint.x
        beatImgViewNowFrame.origin.x = startPoint.x - (shimmerOrgFrame.minX - beatImgViewOrgFrame.maxX )
        shimmerView.frame = shimmerNowFrame
        beatImageView.frame = beatImgViewNowFrame
        
        UIView.animate(withDuration: kFloatSliderShowTime, animations: {
            self.shimmerView.isHidden = false
            self.beatImageView.isHidden = false
            self.shimmerView.frame = shimmerOrgFrame
            self.beatImageView.frame = beatImgViewOrgFrame
        }) { (finished) in
            if finished {
                if self.state == .opening {
                    DispatchQueue.main.async {
                        self.startRecord()
                    }
                }
                self.state = .open
            }
        }
    }
    
    func hideviewAndAnimation() {
        state = .closing
        self.lastState = .closing
        self.timeLabel.layer.removeAllAnimations()
        self.timeLabel.isHidden = true
        if lastFinishDate == nil {
            lastFinishDate = curFinishDate
            let shimmerOrgFrame = shimmerView.frame
            var shimmerNowFrame = shimmerView.frame
            let beatImgViewOrgFrame = beatImageView.frame
            var beatImgViewNowFrame = beatImageView.frame
            shimmerNowFrame.origin.x = startPoint.x
            beatImgViewNowFrame.origin.x = startPoint.x - (shimmerOrgFrame.minX - beatImgViewOrgFrame.maxX )
            UIView.animate(withDuration: kFloatSliderDissppearTime, delay: 0.3, options: UIView.AnimationOptions.curveLinear, animations: {
                self.shimmerView.frame = shimmerNowFrame
                self.beatImageView.frame = beatImgViewNowFrame
            }) { (finished) in
                if finished {
                    if self.lastFinishDate != nil {
                        let timeGap = self.curFinishDate.timeIntervalSince(self.lastFinishDate!)
                        if timeGap == 0 {
                            self.lastFinishDate = nil
                        }
                    }
                    self.shimmerView.removeFromSuperview()
                    self._shimmerView = nil
                    self._beatImageView?.removeFromSuperview()
                    self._beatImageView = nil
                    self.state = .closed
                    self.lastState = self.state
                }
            }
        }else{
            self.shimmerView.removeFromSuperview()
            self._shimmerView = nil
            self._beatImageView?.removeFromSuperview()
            self._beatImageView = nil
            self.lastFinishDate = nil
            state = .closed
            self.lastState = self.state
        }
    }
}

extension ZLRecordView {
    //MARK: ============ handle : click the recordButton and it's status  ============
    //Start record
    @objc func recordStartRecordVoice(sender senderA: UIButton, event eventA: UIEvent) {
        curStartDate = Date.init()
        isStarted = false
        playTime = 0
        isCanceled = false
        //1.start execut the animation
        showViewAndAnimation()
        startPlayMusic(musicName: "send_message")
        if deviceOldThan(device: 9) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        } else {
            notification.notificationOccurred(.error)
        }
        //2.get the trackPoint
        let touch : UITouch = (eventA.touches(for: senderA)?.first)!
        trackTouchPoint = touch.location(in: self)
        firstTouchPoint = trackTouchPoint;
    }
    
    //RecordMayCancel
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
                recordButton.cancelTracking(with: eventA)
                recordButton.removeTarget(nil, action: nil, for: UIControl.Event.allEvents)
                recordCanceled()
                return
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
    
    //Finish Record Voice
    @objc func recordFinishRecordVoice(){
        curFinishDate = Date.init()
        if isCanceled == false {
            hideviewAndAnimation()
        }
    
        let timeGap = curFinishDate.timeIntervalSince(curStartDate!)
        if timeGap < 2 {
            UIView.animate(withDuration: 1) {
                self.showRightTipView()
            }
        }
        guard isStarted == true else {
            return
        }
        guard isCanceled  == false else {
            return
        }
        self.hide()
        isFinished = true
        recordEnded()
    }
    
    //MARK: ============ record status: 1.start 2.cancel 3.end
    func startRecord() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options:[.allowBluetooth,.allowBluetoothA2DP,.defaultToSpeaker])
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
        self.docmentFilePath = docments! + "/\(fileNameString).caf" //Set storage address
        do {
            let url = NSURL.fileURL(withPath: self.docmentFilePath!)
            self.recorder = try AVAudioRecorder(url: url, settings: recordSetting)
            self.recorder?.delegate = self
            self.recorder!.prepareToRecord()
            self.recorder?.isMeteringEnabled = true
        } catch let err {
            print("record fail:\(err.localizedDescription)")
        }
        self.timeLabel.isHidden = false
        let basicAnimtion: CABasicAnimation = CABasicAnimation.init(keyPath: "opacity")
        basicAnimtion.duration = 0.5
        basicAnimtion.fromValue = 0
        basicAnimtion.toValue = 1
        self.timeLabel.layer.add(basicAnimtion, forKey: "opacity")
        self.timeLabel.alpha = 1
        //1.change status to start
        self.isStarted = true
        self.isCanceled = false
        
        //2.show the animation
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.beatImageView.tintColor = UIColor.red
            self.showbeatImageViewGradient()
        }
        self.showbeatImageViewGradient()
        self.recorder?.record()
        if self.playTimer == nil {
            self.playTimer = Timer.init(timeInterval: 1, target: self, selector: #selector(self.countVoiceTime), userInfo: nil, repeats: true)
        }
        RunLoop.main.add(self.playTimer!, forMode: RunLoop.Mode.common)
    }
    
    // cancle record
    func recordCanceled() {
        isCanceled = false
        self.timeCount = 0
        state = .closed
        self.hide()
        //record stoped and delete the record
        if (playTimer != nil) {
            recorder?.stop()
            recorder?.deleteRecording()
            playTimer?.invalidate()
            playTimer = nil
        }
        resetLockView()
        //show animation
        showbeatImageViewAnimation()
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
        //        startPlayMusic(musicName: "send_message")
        if (playTimer != nil || recorder != nil) {
            recorder?.stop()
            playTimer?.invalidate()
            playTimer = nil
        }
        resetRecordButtonTarget()
        resetFinishStatusView()
        
    }
    
    //MARK: ============ handle recode voice && send voice
    @objc private func sendVoice(){
        sendButton.isUserInteractionEnabled = false
        recordFinishRecordVoice()
    }
    
    @objc private func countVoiceTime(){
        playTime = playTime + 1
        recordIsRecordingVoice(playTime)
        if playTime >= 60 {
            recordFinishRecordVoice()
        }
    }
    
    // is recording
    func recordIsRecordingVoice(_ recordTime: Int) {
        timeCount = recordTime
        if (timeCount == 1){
            showLockView()
        }
        if recordTime < 10 {
            self.timeLabel.text = "0:0" + "\(recordTime)"
        }else{
            self.timeLabel.text = "0:" + "\(recordTime)"
            
            if recordTime >= 50 {
                self.show("\(60 - recordTime)")
            }
        }
    }
}

extension ZLRecordView: AVAudioRecorderDelegate{
    func startPlayMusic(musicName muscicName : String) {
        guard let path = Bundle.main.path(forResource: muscicName, ofType: "m4a") else {
            return
        }
        let pathUrl = URL(fileURLWithPath: path)
        AudioServicesCreateSystemSoundID(pathUrl as CFURL, &sysID)
        AudioServicesPlaySystemSound(sysID)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let url = NSURL.fileURL(withPath: docmentFilePath!)
        do{
            let audioData = try  NSData(contentsOfFile: url.path, options: [])
            if isFinished && (isCanceled == false) && (timeCount >= 1) {
                AudioServicesPlaySystemSound(1003)
                if deviceOldThan(device: 9) {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                } else {
                    notification.notificationOccurred(.success)
                }
                isFinished = false
                timeCount = 0
                self.delegate?.zlRecordFinishRecordVoice(didFinishRecode: audioData)
            }
        } catch let err{
            print("record fail:\(err.localizedDescription)")
        }
    }
}
extension NSObject {
    func getStringWidth(string :String, font :UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font:font]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = string.boundingRect(with: CGSize.init(width:CGFloat(MAXFLOAT), height:CGFloat(MAXFLOAT)), options: option, attributes: attributes, context: nil)
        return rect.size.width
    }
}
