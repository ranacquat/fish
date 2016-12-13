//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos
import CoreActionSheetPicker
import Interpolate

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


@objc public protocol FusumaDelegate: class {
    
    func fusumaImageSelected(_ image: UIImage)
    @objc optional func fusumaDismissedWithImage(_ image: UIImage)
    func fusumaVideoCompleted(withFileURL fileURL: URL)
    func fusumaCameraRollUnauthorized()
    
    @objc optional func fusumaClosed()
}

public var fusumaBaseTintColor                          =   UIColor.hex("#FFFFFF", alpha: 1.0)
public var fusumaTintColor                              =   UIColor.hex("#009688", alpha: 1.0)
public var fusumaBackgroundColor                        =   UIColor.hex("#212121", alpha: 1.0)

public var fusumaAlbumImage :       UIImage?            =   nil
public var fusumaCameraImage :      UIImage?            =   nil
public var fusumaCheckImage :       UIImage?            =   nil
public var fusumaCloseImage :       UIImage?            =   nil
public var fusumaFlashOnImage :     UIImage?            =   nil
public var fusumaFlashOffImage :    UIImage?            =   nil
public var fusumaFlipImage :        UIImage?            =   nil
public var fusumaShotImage :        UIImage?            =   nil


public var fusumaCropImage:         Bool                =   true

public var fusumaCameraRollTitle                        =   "Fish - CAMERA ROLL"
public var fusumaCameraTitle                            =   "PHOTO"
public var fusumaTitleFont                              =   UIFont(name: "AvenirNext-DemiBold", size: 15)

public var fusumaTintIcons :        Bool                =   true

public enum FusumaModeOrder {
    case cameraFirst
    case libraryFirst
}

public final class FusumaViewController: UIViewController {
    
    enum Mode {
        case camera
        case library
    }

    public var hasVideo                                 =   false

    var mode:                       Mode                =   .camera
    public var modeOrder:           FusumaModeOrder     =   .libraryFirst
    var willFilter                                      =   true
    
    var docType:                    String              =   ""
    var serviceController:          ServiceController   =   ServiceController()
    var image:                      UIImage             =   UIImage()
    var document:                   Document            =   Document()
    var typeList                                        =   ["RIB", "CNI", "Bulletin de salaire"]
    
    var typeIsUp:Bool                                   =   false
    
    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer:         UIView!

    @IBOutlet weak var titleLabel:                  UILabel!
    @IBOutlet weak var menuView:                    UIView!
    @IBOutlet weak var closeButton:                 UIButton!
    @IBOutlet weak var libraryButton:               UIButton!
    @IBOutlet weak var cameraButton:                UIButton!
    @IBOutlet weak var doneButton:                  UIButton!

    @IBOutlet var libraryFirstConstraints:          [NSLayoutConstraint]!
    @IBOutlet var cameraFirstConstraints:           [NSLayoutConstraint]!
    
    @IBOutlet var docTypeButton: UIButton!
    
    @IBAction func docType(_ sender: Any) {
        let assp = ActionSheetStringPicker.show(withTitle: "Type de document", rows:
                typeList
                , initialSelection: 0, doneBlock: {
                    picker, values, indexes in
                    self.changeDocTypeButton(with:indexes as! String?)
                    return
            }, cancel: { ActionSheetStringPicker in return }, origin: sender)
        
        assp?.pickerBackgroundColor             =   UIColor.init(white: 1.0, alpha: 1.0)
        assp?.toolbarBackgroundColor            =   UIColor.init(white: 0.5, alpha: 1.0)
    }

    lazy var albumView                          =   FSAlbumView.instance()
    lazy var cameraView                         =   FSCameraView.instance()

    var colorChange:Interpolate? = nil
 
    fileprivate var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewControllerAdaptive", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        fusumaCropImage = false
        setNotifications()
        setSubViewsWhenViewDidLoad()
        
        UIView.animate(withDuration: 3, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.titleLabel.textColor = UIColor.black
            self.titleLabel.textColor = UIColor.green
            //self.titleLabel.textColor = UIColor.gray
            //self.titleLabel.textColor = UIColor.red
        }, completion: {_ in
            self.titleLabel.textColor = UIColor.green
            self.titleLabel.textColor = UIColor.black
            
        })
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setSubViewsWhenViewDidAppear()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAll()
    }

    public override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        print(orientation)
        
        switch (orientation) {
        case .portrait:
            cameraView.connection?.videoOrientation =   .portrait
            
        case .landscapeRight:
            cameraView.connection?.videoOrientation =   .landscapeLeft
            
        case .landscapeLeft:
            cameraView.connection?.videoOrientation =   .landscapeRight
            
        default:
            cameraView.connection?.videoOrientation =   .portrait
            
        }
        
        let width       =   cameraView.previewViewContainer.bounds.width
        let height      =   cameraView.previewViewContainer.bounds.height
        
        let frame2      =   CGRect(x: 0, y: 0, width: width, height: height)
        cameraShotContainer.frame = frame2
        cameraView.videoLayer?.removeFromSuperlayer()
        cameraView.videoLayer?.frame           =   cameraView.previewViewContainer.bounds
        cameraView.previewViewContainer.layer.addSublayer(cameraView.videoLayer!)
 
    }
    
    func changeOrientation() {
        
        let width       =   UIScreen.main.bounds.width
        let height      =   UIScreen.main.bounds.height
        

        
        let frame2      =   CGRect(x: 0, y: 0, width: height, height: width)
        cameraShotContainer.frame = frame2
        
        cameraView.videoLayer?.removeFromSuperlayer()
        
        cameraView.previewViewContainer.bounds = CGRect(x: 0, y: 0, width: width, height: height - 50)
        cameraView.previewViewContainer.setNeedsLayout()
        
        
        print("WELL : \(cameraView.previewViewContainer.bounds)")
        
        cameraView.videoLayer?.frame           =   cameraView.previewViewContainer.bounds
        cameraView.previewViewContainer.layer.addSublayer(cameraView.videoLayer!)
 
        setCameraViewLayout()
        
        let orientation: UIDeviceOrientation = UIDevice.current.orientation
        print(orientation)

        
        switch (orientation) {
        case .portrait:
            cameraView.connection?.videoOrientation =   .portrait

        case .landscapeRight:
            cameraView.connection?.videoOrientation =   .landscapeLeft

        case .landscapeLeft:
            cameraView.connection?.videoOrientation =   .landscapeRight

        default:
            cameraView.connection?.videoOrientation =   .portrait

        }
    }
 
    override public var prefersStatusBarHidden : Bool {
        return true
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            self.delegate?.fusumaClosed?()
        })
    }
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        changeMode(Mode.library)
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        changeMode(Mode.camera)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        let view:FSImageCropView? = albumView.imageCropView

        if fusumaCropImage {
            getCropImage(from:view)
        } else {
            print("no image crop ")
            delegate?.fusumaImageSelected((view?.image)!)
            
            self.dismiss(animated: true, completion: {
                self.delegate?.fusumaDismissedWithImage?((view?.image)!)
            })
        }
    }
    
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate {
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        delegate?.fusumaImageSelected(image)
    }
    
    public func albumViewCameraRollAuthorized() {
        // in the case that we're just coming back from granting photo gallery permissions
        // ensure the done button is visible if it should be
        self.updateDoneButtonVisibility()
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        delegate?.fusumaCameraRollUnauthorized()
    }
    
    func videoFinished(withFileURL fileURL: URL) {
        delegate?.fusumaVideoCompleted(withFileURL: fileURL)
        self.dismiss(animated: true, completion: nil)
    }
    
}

private extension FusumaViewController {

    func setNotifications(){
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "PHOTO_TAKEN"), object: nil, queue: OperationQueue.main, using: {notification in
            self.createDocument(with: notification.object as! UIImage)
        })
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "LOGIN_FAILED"), object: nil, queue: OperationQueue.main, using: {notification in
            self.showAlert(with: notification.object as! [String:String])
        })
    }
    
    func setViewDelegate(){
        cameraView.delegate         =   self
        albumView.delegate          =   self
    }
    
    func setMenuView(){
        menuView.backgroundColor    =   fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.black, width: 1.0)
    }
    
    func setButtons(){
        let bundle                  =   Bundle(for: self.classForCoder)
        
        let albumImage              =
            fusumaAlbumImage != nil ?
                fusumaAlbumImage :
                UIImage(named: "ic_insert_photo", in: bundle, compatibleWith: nil)
        let cameraImage             =
            fusumaCameraImage != nil ?
                fusumaCameraImage :
                UIImage(named: "ic_photo_camera", in: bundle, compatibleWith: nil)
        
        let checkImage              =
            fusumaCheckImage != nil ?
                fusumaCheckImage :
                UIImage(named: "ic_check", in: bundle, compatibleWith: nil)
        
        let closeImage              =
            fusumaCloseImage != nil ?
                fusumaCloseImage :
                UIImage(named: "ic_close", in: bundle, compatibleWith: nil)
        
        if fusumaTintIcons {
            
            self.buildLibraryButton(with:albumImage, color:fusumaTintColor, adjustsImageWhenHighlighted:false)
            
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            cameraButton.tintColor                      =   fusumaTintColor
            cameraButton.adjustsImageWhenHighlighted    =   false
            
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            closeButton.tintColor                       =   fusumaBaseTintColor
            
            doneButton.setImage(checkImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            doneButton.tintColor                        =   fusumaBaseTintColor
            
        } else {
            self.buildLibraryButton(with:albumImage, color:nil, adjustsImageWhenHighlighted:nil)
            
            cameraButton.setImage(cameraImage, for: UIControlState())
            cameraButton.setImage(cameraImage, for: .highlighted)
            cameraButton.setImage(cameraImage, for: .selected)
            cameraButton.tintColor = nil
            
            closeButton.setImage(closeImage, for: UIControlState())
            doneButton.setImage(checkImage, for: UIControlState())
        }
        
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true
    }
    
    
    func setSubViews(){
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
    }
    
    func setViewLayout(){
        if !hasVideo {
            
            self.view.addConstraint(NSLayoutConstraint(
                item:       self.view,
                attribute:  .trailing,
                relatedBy:  .equal,
                toItem:     cameraButton,
                attribute:  .trailing,
                multiplier: 1.0,
                constant:   0
                )
            )
            self.view.layoutIfNeeded()
        }
    }
    
    func setTitleLabel(){
        titleLabel.textColor    =   fusumaBaseTintColor
        titleLabel.font         =   fusumaTitleFont
        // CAT : INTERPOLATE
        
        
        
        /*
        UIView.animate(withDuration: 4, delay: 0, options: [.repeat], animations: {
            print("animation.......")
            UIView.setAnimationRepeatCount(Float.infinity)
            self.colorChange = Interpolate(from: UIColor.white,
                                      to: UIColor.red,
                                      apply: { (color) in
                                        self.titleLabel.textColor = color
            })
            self.colorChange?.animate(duration: 1)
        }, completion: {_ in
            self.colorChange = Interpolate(from: UIColor.red,
                                           to: UIColor.white,
                                           apply: { (color) in
                                            self.titleLabel.textColor = color
            })
            self.colorChange?.animate(duration: 1)
        })
 */
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "STOP_ANIMATION"), object: nil, queue: OperationQueue.main, using: {notification in
                //self.colorChange?.stopAnimation()
        })
    }
    
    func setCameraView(){
        if fusumaCropImage {
            cameraView.fullAspectRatioConstraint.isActive = false
            cameraView.croppedAspectRatioConstraint.isActive = true
        } else {
            cameraView.fullAspectRatioConstraint.isActive = true
            cameraView.croppedAspectRatioConstraint.isActive = false
        }
    }
    
    func changeDocTypeButton(with indexes:String?){
        self.docTypeButton.setTitle(indexes, for: UIControlState.normal)
        self.docTypeButton.setNeedsLayout() // do reload changes
        self.docTypeButton.setAttributedTitle(NSAttributedString.init(string: indexes!), for: UIControlState.normal)
        self.docTypeButton.titleLabel?.textColor = UIColor(white: 1.0, alpha: 1.0)
        
        
        self.typeIsUp   =   true
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "STOP_ANIMATION"), object: nil)
    }
    
    func buildLibraryButton(with albumImage:UIImage?, color:UIColor?, adjustsImageWhenHighlighted:Bool?){
        libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .selected)
        libraryButton.tintColor                     =   color
        libraryButton.adjustsImageWhenHighlighted   =   adjustsImageWhenHighlighted!
    }
    
    func setSubViewsWhenViewDidLoad(){
        self.view.backgroundColor   =   fusumaBackgroundColor
        
        self.docTypeButton.isHidden =   true
        
        setViewDelegate()
        
        setMenuView()
        
        // Get the custom button images if they're set
        setButtons()
        
        changeMode(Mode.library)
        
        setSubViews()
        
        setTitleLabel()
        
        setViewLayout()
        
        // CAT : setCameraView()
    }
    
    func setSubViewsWhenViewDidAppear(){
        
        setAlbumViewLayout()
        setCameraViewLayout()
        
        albumView.initialize()
        cameraView.initialize()
    }
    
    func setAlbumViewLayout(){
        albumView.frame  = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
    }
    
    func setCameraViewLayout(){
        cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
    }
    
    
    func stopAll() {
        
        self.cameraView.stopCamera()
    }
    
    func changeMode(_ mode: Mode) {

        if self.mode == mode {
            return
        }
        
        //operate this switch before changing mode to stop cameras
        switch self.mode {
        case .library:
            break
        case .camera:
            self.cameraView.stopCamera()
        default:
            break
        }
        
        self.mode = mode
        
        dishighlightButtons()
        updateDoneButtonVisibility()
        
        switch mode {
        case .library:
            titleLabel.text = NSLocalizedString(fusumaCameraRollTitle, comment: fusumaCameraRollTitle)
            
            highlightButton(libraryButton)
            
            //CAT
            self.photoLibraryViewerContainer.isHidden = false
            self.cameraShotContainer.isHidden = true
            //
            
            self.docTypeButton.isHidden = true
            self.view.bringSubview(toFront: photoLibraryViewerContainer)
        case .camera:
            //titleLabel.text = NSLocalizedString(fusumaCameraTitle, comment: fusumaCameraTitle)
            titleLabel.isHidden = true
            
            highlightButton(cameraButton)
            
            //CAT
            self.photoLibraryViewerContainer.isHidden = true
            self.cameraShotContainer.isHidden = false

            //
            self.view.bringSubview(toFront: cameraShotContainer)
            self.docTypeButton.titleLabel?.font = fusumaTitleFont
            self.docTypeButton.isHidden = false
            cameraView.startCamera()
        default:
            break
        }
        doneButton.isHidden = !hasGalleryPermission
        self.view.bringSubview(toFront: menuView)
    }
    
    
    func updateDoneButtonVisibility() {
        // don't show the done button without gallery permission
        if !hasGalleryPermission {
            self.doneButton.isHidden = true
            return
        }

        switch self.mode {
        case .library:
            self.doneButton.isHidden = false
        default:
            self.doneButton.isHidden = true
        }
    }
    
    func dishighlightButtons() {
        cameraButton.tintColor  = fusumaBaseTintColor
        libraryButton.tintColor = fusumaBaseTintColor
        
        if cameraButton.layer.sublayers?.count > 1 {
            
            for layer in cameraButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1 {
            
            for layer in libraryButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        
    }
    
    func highlightButton(_ button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.addBottomBorder(fusumaTintColor, width: 3)
    }
    
    func createDocument(with image:UIImage){
        let docController:DocumentController    =   DocumentController()
        document                                =   docController.create()
        document.info["IMAGE"]                  =   UIImagePNGRepresentation(image)
        
        let alert = UIAlertController.init(title: "Sauvegarde de l'image", message: "Voulez-vous sauvegarder l'image dans l'Album photo 'Fish' ?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: {_ in
            self.save(image:image)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Non, merci !", style: UIAlertActionStyle.cancel, handler: {_ in
            
        }))
                
        self.present(alert, animated: true, completion: nil)
        
        serviceController.storeTmp(document: document)
    }
    /*
    func createDocument(with data:NSMutableData){
        let docController:DocumentController    =   DocumentController()
        document                                =   docController.create()
        document.info["IMAGE"]                  =   data//UIImagePNGRepresentation(image)
        
        let alert = UIAlertController.init(title: "Sauvegarde de l'image", message: "Voulez-vous sauvegarder l'image dans l'Album photo 'Fish' ?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: {_ in
            self.save(data:data)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Non, merci !", style: UIAlertActionStyle.cancel, handler: {_ in
            
        }))
        
        self.present(alert, animated: true, completion: nil)
        
        serviceController.storeTmp(document: document)
    }
    */
    func showAlert(with info:[String:String]){
        let alert = UIAlertController.init(title: info["TITLE"], message: info["MESSAGE"], preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertActionStyle.default, handler: {_ in
        }))
                
        self.present(alert, animated: true, completion: nil)
    }
    
    func save(image:UIImage) {
        CustomPhotoAlbum().save(
            image: image,
            type: (self.docTypeButton.titleLabel?.text)!,
            success:{},
            failure:{})

    }
    /*
    func save(data:NSMutableData) {
        CustomPhotoAlbum().save(data: data, type: (self.docTypeButton.titleLabel?.text)!)
        
    }
 */
    
    func getCropImage(from view:FSImageCropView?){
        let normalizedX         =   (view?.contentOffset.x)! / (view?.contentSize.width)!
        let normalizedY         =   (view?.contentOffset.y)! / (view?.contentSize.height)!
        
        let normalizedWidth     =   (view?.frame.width)! / (view?.contentSize.width)!
        let normalizedHeight    =   (view?.frame.height)! / (view?.contentSize.height)!
        
        let cropRect            =   CGRect(x: normalizedX,
                                           y: normalizedY,
                                           width: normalizedWidth,
                                           height: normalizedHeight)
        
        DispatchQueue.global(qos: .default).async(execute: {
            
            let options                     =   PHImageRequestOptions()
            options.deliveryMode            =   .highQualityFormat
            options.isNetworkAccessAllowed  =   true
            options.normalizedCropRect      =   cropRect
            options.resizeMode              =   .exact
            
            let targetWidth                 =   floor(CGFloat(self.albumView.phAsset.pixelWidth) * cropRect.width)
            let targetHeight                =   floor(CGFloat(self.albumView.phAsset.pixelHeight) * cropRect.height)
            let dimension                   =   max(min(targetHeight, targetWidth),
                                                    1024 * UIScreen.main.scale)
            
            let targetSize                  =   CGSize(width: dimension, height: dimension)
            
            PHImageManager.default().requestImage(for: self.albumView.phAsset, targetSize: targetSize,
                                                  contentMode: .aspectFill, options: options) {
                                                    result, info in
                                                    
                                                    DispatchQueue.main.async(execute: {
                                                        self.delegate?.fusumaImageSelected(result!)
                                                        
                                                        self.dismiss(animated: true, completion: {
                                                            self.delegate?.fusumaDismissedWithImage?(result!)
                                                        })
                                                    })
            }
        })

    }
}
