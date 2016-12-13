//
//  FSCameraView.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import AVFoundation
import CoreActionSheetPicker
import ImageIO
import LocalAuthentication

enum UIUserInterfaceIdiom : Int
{
    case Unspecified
    case Phone
    case Pad
}

struct ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    static let IS_IPAD_PRO          = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1366.0
}


@objc protocol FSCameraViewDelegate: class {
    func cameraShotFinished(_ image: UIImage)
}

final class FSCameraView: UIView, UIGestureRecognizerDelegate {
    //@available(iOS 2.0, *)

    @IBOutlet weak var secureScanLabel: UILabel!
    @IBOutlet weak var previewViewContainer:            UIView!
    @IBOutlet weak var shotButton:                      UIButton!
    @IBOutlet weak var flashButton:                 	UIButton!
    @IBOutlet weak var flipButton:                      UIButton!
    @IBOutlet weak var croppedAspectRatioConstraint:    NSLayoutConstraint!
    @IBOutlet weak var fullAspectRatioConstraint:       NSLayoutConstraint!
    
    weak var delegate: FSCameraViewDelegate? = nil
    
    var session:                                        AVCaptureSession?
    var device:                                         AVCaptureDevice?
    var videoInput:                                     AVCaptureDeviceInput?
    var imageOutput:                                    AVCaptureStillImageOutput?
    var focusView:                                      UIView?

    var flashOffImage:                                  UIImage?
    var flashOnImage:                                   UIImage?
    
    //CAT
    var connection:                                     AVCaptureConnection?
    var videoLayer:                                     AVCaptureVideoPreviewLayer?
    //
    
    @IBOutlet var flashButtonLabel: UILabel!
        
    static func instance() -> FSCameraView {
        return UINib(nibName: "FSCameraViewAdaptive", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSCameraView
    }
    
    func initialize() {
        
        if session != nil {
            return
        }
        self.backgroundColor    	=   fusumaBackgroundColor
        
        let bundle                  =   Bundle(for: self.classForCoder)
        let authenticationContext   =   LAContext()
        var error:NSError?

        if !authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            fusumaShotImage = UIImage(named: "shutter_button", in: bundle, compatibleWith: nil)
        }
        
        flashOnImage            =   fusumaFlashOnImage != nil ?
            fusumaFlashOnImage :
            UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage           =   fusumaFlashOffImage != nil ?
            fusumaFlashOffImage :
            UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage           =   fusumaFlipImage != nil ?
            fusumaFlipImage :
            UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)

        // CAT : TouchID specifics
        secureScanLabel.text = fusumaShotImage != nil ? "" : secureScanLabel.text
        let shotImage = fusumaShotImage != nil ? fusumaShotImage : UIImage(named: "Touch-icon-lg", in: bundle, compatibleWith: nil)
        
        if(fusumaTintIcons) {
            flashButton.tintColor = fusumaBaseTintColor
            flipButton.tintColor  = fusumaBaseTintColor
            shotButton.tintColor  = fusumaBaseTintColor
            
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            shotButton.setImage(shotImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        } else {
            flashButton.setImage(flashOffImage, for: UIControlState())
            flipButton.setImage(flipImage, for: UIControlState())
            shotButton.setImage(shotImage, for: UIControlState())
        }

        
        self.isHidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice , device.position == AVCaptureDevicePosition.back {
                
                self.device = device
                
                if !device.hasFlash {
                    
                    flashButton.isHidden = true
                }
            }
        }
        
        do {

            if let session = session {

                videoInput = try AVCaptureDeviceInput(device: device)

                session.addInput(videoInput)
                
                imageOutput = AVCaptureStillImageOutput()
                
                session.addOutput(imageOutput)
                
                videoLayer                  =   AVCaptureVideoPreviewLayer(session: session)
                videoLayer?.frame           =   self.previewViewContainer.bounds
                videoLayer?.videoGravity    =   AVLayerVideoGravityResizeAspectFill
                //CAT
                self.connection = videoLayer?.connection
                //
                self.previewViewContainer.layer.addSublayer(videoLayer!)
                
                session.sessionPreset       =   AVCaptureSessionPresetPhoto

                session.startRunning()
                
            }
            
            // Focus View
            self.focusView                  =   UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer               =   UITapGestureRecognizer(target: self, action:#selector(FSCameraView.focus(_:)))
            tapRecognizer.delegate          =   self
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            
        }
        // THIS TEST IS NEEDED TO BE COMPATIBLE FOR IPAD
        if (DeviceType.IS_IPAD || DeviceType.IS_IPAD_PRO) {
            print("IS_IPAD : NO FLASH CONFIGURATION")
        }else{
            flashButtonLabel.isHidden = true
            flashConfiguration()
        }
        
        self.startCamera()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FSCameraView.willEnterForegroundNotification(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        
    }
    
    func willEnterForegroundNotification(_ notification: Notification) {
        
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.authorized {
            
            session?.startRunning()
            
        } else if status == AVAuthorizationStatus.denied || status == AVAuthorizationStatus.restricted {
            
            session?.stopRunning()
        }
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func startCamera() {
        
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if status == AVAuthorizationStatus.authorized {

            session?.startRunning()
            
        } else if status == AVAuthorizationStatus.denied || status == AVAuthorizationStatus.restricted {

            session?.stopRunning()
        }
    }
    
    func stopCamera() {
        session?.stopRunning()
    }
    
    @IBAction func shotButtonPressed(_ sender: UIButton) {
        let authenticationContext = LAContext()
        var error:NSError?
        
        // 2. Check if the device has a fingerprint sensor
        // If not, show the user an alert view and bail out!
        if !authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            //showAlertViewIfNoBiometricSensorHasBeenDetected()
            self.scan()
        }else {
            authenticationContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Only awesome people are allowed", reply: {(success, error) in
                if success {
                    print("OK FINGERPRINT")
                    self.scan()
                }else{
                    print("KO FINGERPRINT")
                }
                // Check if there is an error
                if error != nil {
                    self.showMessage(error as! NSError)
                }
            })
        }
    }
    
    func showMessage(_ error:NSError){
        var message : NSString
        var showAlert : Bool
        
        switch(error.code) {
        case LAError.authenticationFailed.rawValue:
            message = "There was a problem verifying your identity."
            showAlert = true
            break;
        case LAError.userCancel.rawValue:
            message = "You pressed cancel."
            showAlert = true
            break;
        case LAError.userFallback.rawValue:
            message = "You pressed password."
            showAlert = true
            break;
        default:
            showAlert = true
            message = "Touch ID may not be configured"
            break;
        }
        if showAlert {
            self.showAlert(message: message as String)
        }
    }
    
    func scan(){
        guard let imageOutput = imageOutput else {
            return
        }
        
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 2.0, execute: { () -> Void in
            
            let videoConnection = imageOutput.connection(withMediaType: AVMediaTypeVideo)
            
            let orientation: UIDeviceOrientation = UIDevice.current.orientation
            switch (orientation) {
            case .portrait:
                videoConnection?.videoOrientation = .portrait
            case .portraitUpsideDown:
                videoConnection?.videoOrientation = .portraitUpsideDown
            case .landscapeRight:
                videoConnection?.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                videoConnection?.videoOrientation = .landscapeRight
            default:
                videoConnection?.videoOrientation = .portrait
            }
            
            imageOutput.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (buffer, error) -> Void in
                
                self.session?.stopRunning()
                
                if buffer != nil{
                    let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    
                    // CAT
                    /*
                     let rawMetadata = CMCopyDictionaryOfAttachments(nil, buffer!, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
                     let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
                     
                     let exifData = metadata.value(forKey: kCGImagePropertyExifDictionary as String) as? NSMutableDictionary
                     exifData?.setValue("TEST_TYPE", forKey: kCGImagePropertyExifMakerNote as String)
                     
                     metadata.setValue(exifData, forKey: kCGImagePropertyExifDictionary as String)
                     metadata.setValue(1, forKey: kCGImagePropertyOrientation as String)
                     */
                    //
                    if let image = UIImage(data: data!), let delegate = self.delegate {
                        /*
                         guard let jpgData = UIImageJPEGRepresentation(image, 1) else { return }
                         // Add metadata to jpgData
                         guard let source = CGImageSourceCreateWithData(jpgData as CFData, nil),
                         let uniformTypeIdentifier = CGImageSourceGetType(source) else { return }
                         let finalData = NSMutableData(data: jpgData)
                         guard let destination = CGImageDestinationCreateWithData(finalData, uniformTypeIdentifier, 1, nil) else { return }
                         CGImageDestinationAddImageFromSource(destination, source, 0, metadata)
                         guard CGImageDestinationFinalize(destination) else { return }
                         */
                        // Image size
                        var iw: CGFloat
                        var ih: CGFloat
                        
                        switch (orientation) {
                        case .landscapeLeft, .landscapeRight:
                            // Swap width and height if orientation is landscape
                            iw = image.size.height
                            ih = image.size.width
                        default:
                            iw = image.size.width
                            ih = image.size.height
                        }
                        
                        // Frame size
                        let sw = self.previewViewContainer.frame.width
                        
                        // The center coordinate along Y axis
                        let rcy = ih * 0.5
                        
                        let imageRef = image.cgImage?.cropping(to: CGRect(x: rcy-iw*0.5, y: 0 , width: iw, height: iw))
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            if fusumaCropImage {
                                let resizedImage = UIImage(cgImage: imageRef!, scale: sw/iw, orientation: image.imageOrientation)
                                delegate.cameraShotFinished(resizedImage)
                            } else {
                                delegate.cameraShotFinished(image)
                            }
                            
                            // SAVE IMAGE OR NOT
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PHOTO_TAKEN"), object: image)
                            
                            self.session        =   nil
                            self.device         =   nil
                            self.imageOutput    =   nil
                            
                        })
                    }
                }else{
                    self.session?.startRunning()
                    self.scan()
                }
            })
            
        })
    }
    
    func showAlertViewIfNoBiometricSensorHasBeenDetected(){
        
        var info:[String:String] = [String:String]()
        info["TITLE"] = "Error"
        info["MESSAGE"] = "This device does not have a TouchID sensor"
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LOGIN_FAILED"), object:info)
        //showAlertWithTitle(title: "Error", message: "This device does not have a TouchID sensor.")
        
    }
    
    func showAlert(message:String){
        var info:[String:String] = [String:String]()
        info["TITLE"] = "Error"
        info["MESSAGE"] = message
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LOGIN_FAILED"), object:info)
    }
    
    @IBAction func flipButtonPressed(_ sender: UIButton) {

        if !cameraIsAvailable() {

            return
        }
        
        session?.stopRunning()
        
        do {

            session?.beginConfiguration()

            if let session = session {
                
                for input in session.inputs {
                    
                    session.removeInput(input as! AVCaptureInput)
                }

                let position = (videoInput?.device.position == AVCaptureDevicePosition.front) ? AVCaptureDevicePosition.back : AVCaptureDevicePosition.front

                for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {

                    if let device = device as? AVCaptureDevice , device.position == position {
                 
                        videoInput = try AVCaptureDeviceInput(device: device)
                        session.addInput(videoInput)
                        
                    }
                }

            }
            
            session?.commitConfiguration()
            
        } catch {
            
        }
        
        session?.startRunning()
    }
    
    @IBAction func flashButtonPressed(_ sender: UIButton) {

        if !cameraIsAvailable() {

            return
        }

        do {

            if let device = device {
                
                guard device.hasFlash else { return }
            
                try device.lockForConfiguration()
                
                let mode = device.flashMode
                
                if mode == AVCaptureFlashMode.off {
                    
                    device.flashMode = AVCaptureFlashMode.on
                    flashButton.setImage(flashOnImage, for: UIControlState())
                    
                } else if mode == AVCaptureFlashMode.on {
                    
                    device.flashMode = AVCaptureFlashMode.off
                    flashButton.setImage(flashOffImage, for: UIControlState())
                }
                
                device.unlockForConfiguration()

            }

        } catch _ {

            flashButton.setImage(flashOffImage, for: UIControlState())
            return
        }
 
    }
}

extension FSCameraView {
    
    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        
        let point       =   recognizer.location(in: self)
        let viewsize    =   self.bounds.size
        let newPoint    =   CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
        let device      =   AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            
            try device?.lockForConfiguration()
            
        } catch _ {
            
            return
        }
        
        if device?.isFocusModeSupported(AVCaptureFocusMode.autoFocus) == true {

            device?.focusMode               =   AVCaptureFocusMode.autoFocus
            device?.focusPointOfInterest    =   newPoint
        }

        if device?.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) == true {
            
            device?.exposureMode            =   AVCaptureExposureMode.continuousAutoExposure
            device?.exposurePointOfInterest =   newPoint
        }
        
        device?.unlockForConfiguration()
        
        self.focusView?.alpha               =   0.0
        self.focusView?.center              =   point
        self.focusView?.backgroundColor     =   UIColor.clear
        self.focusView?.layer.borderColor   =   fusumaBaseTintColor.cgColor
        self.focusView?.layer.borderWidth   =   1.0
        self.focusView!.transform           =   CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.addSubview(self.focusView!)
        
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
            initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn, // UIViewAnimationOptions.BeginFromCurrentState
            animations: {
                self.focusView!.alpha       =   1.0
                self.focusView!.transform   =   CGAffineTransform(scaleX: 0.7, y: 0.7)
            }, completion: {(finished) in
                self.focusView!.transform   =   CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.focusView!.removeFromSuperview()
        })
    }
    
    func flashConfiguration() {
    
        do {
            
            if let device = device {
                
                guard device.hasFlash else { return }
                
                try device.lockForConfiguration()
                
                device.flashMode = AVCaptureFlashMode.off
                flashButton.setImage(flashOffImage, for: UIControlState())
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            return
        }
    }

    func cameraIsAvailable() -> Bool {

        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)

        if status == AVAuthorizationStatus.authorized {

            return true
        }

        return false
    }
    
}

extension UIImage {
    
    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImageOrientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImageOrientation.down, UIImageOrientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            break
        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            break
        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
            break
        case UIImageOrientation.up, UIImageOrientation.upMirrored:
            break
        }
        switch imageOrientation {
        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0, space: self.cgImage!.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
        default:
            ctx.draw(self.cgImage!, in: CGRect(origin: CGPoint.zero, size: size))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
}
