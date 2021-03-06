//
//  CustomPhotoAlbum.swift
//  KYCMobile
//
//  Created by Jan ATAC on 10/11/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//
import Foundation
import Photos
#if os(iOS)
import PhotosUI
#endif


class CustomPhotoAlbum: NSObject,CLLocationManagerDelegate {
    static let albumName = "Fish"
    var album:PHAssetCollection?
    var images:PHFetchResult<PHAsset>   =   PHFetchResult<PHAsset>()
    
    var userCollections:                    PHFetchResult<PHCollection>!
    
    var imagesToReturn:[UIImage]        =   [UIImage]()
    var photo:UIImage                   =   UIImage()

    let appDelegate                     =   UIApplication.shared.delegate as! AppDelegate

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self as PHPhotoLibraryChangeObserver)
    }
    
    func getPhotos(from album:String)->[UIImage]?{
        getAlbum(title:CustomPhotoAlbum.albumName,
                 success:{
                    let fetchOptions    =   PHFetchOptions()
                    fetchOptions.sortDescriptors        =   [NSSortDescriptor(key: "creationDate", ascending: true)]
                    
                    self.images         =   PHAsset.fetchAssets(in: self.album!, options: fetchOptions
                    )
                    
                    let imageManager    =   PHCachingImageManager()
                    
                    self.images.enumerateObjects({(object: AnyObject!,
                        count: Int,
                        stop: UnsafeMutablePointer<ObjCBool>) in
                        
                        if object is PHAsset{
                            let asset = object as! PHAsset
                            print("Inside  If object is PHAsset, This is number 1")
                            
                            let imageSize = CGSize(width: asset.pixelWidth,
                                                   height: asset.pixelHeight)
                            
                            /* For faster performance, and maybe degraded image */
                            let options = PHImageRequestOptions()
                            options.deliveryMode = .fastFormat
                            options.isSynchronous = true
                            
                            imageManager.requestImage(for: asset,
                                                      targetSize: imageSize,
                                                      contentMode: .aspectFill,
                                                      options: options,
                                                      resultHandler: {
                                                        (image, info) -> Void in
                                                        self.photo = image!
                                                        /* The image is now available to us */
                                                        self.addImgToArray(uploadImage: self.photo)
                                                        print("enum for image, This is number 2")
                            })
                        }
                    })
        },
        failure:{})
        
        
        
        return self.imagesToReturn
    }

    private func getAlbum(title:String, success:@escaping ()->Void, failure:@escaping ()->Void)->Void{

        PHPhotoLibrary.shared().register(self as PHPhotoLibraryChangeObserver)
        
        let fetchOptions        =   PHFetchOptions()
        fetchOptions.predicate  =   NSPredicate(format: "title = '\(title)'")
        
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        print("RESULT : \(result.count)")
        print("RESULT OF PHAssetMediaTypeImage : \(result.countOfAssets(with: PHAssetMediaType.image))")
        
        guard let tmp = result.firstObject as PHAssetCollection? else {
            createAlbum(title:title, success:{
                print("SUCCESS AT CREATING A NEW ALBUM")
                self.getAlbum(title: title, success:{
                    success()
                }, failure:{
                    print("FAILURE AT GETTING THE ALBUM")
                    failure()
                })
            }, failure:{ _ in
                print("FAILURE AT CREATING A NEW ALBUM")
            })
            return
        }
        
        self.album = tmp
        success()
    }
    
    
    func addImgToArray(uploadImage:UIImage)
    {
        self.imagesToReturn.append(uploadImage)
    }

    
    func save(image:UIImage){
        
        let image = textToImage(drawText: "TEST_Fish", inImage: image, atPoint: CGPoint.zero)
        
        //let exifData = addExif(image)
        
        getAlbum(title:CustomPhotoAlbum.albumName,
                 success:{},
                 failure:{})
        
        PHPhotoLibrary.shared().performChanges({
            let assetRequest            =   PHAssetChangeRequest.creationRequestForAsset(from: image)
            assetRequest.location       =   self.appDelegate.location
            assetRequest.creationDate   =   Date()
            assetRequest.isHidden       =   true
            
            let photosAsset             =   PHAsset.fetchAssets(in: self.album!, options: nil)
            let assetPlaceholder        =   assetRequest.placeholderForCreatedAsset
            let albumChangeRequest      =   PHAssetCollectionChangeRequest(for: self.album!, assets: photosAsset)
            let fastEnumeration         =   NSArray(array: [assetPlaceholder!] as [PHObjectPlaceholder])
            albumChangeRequest?.addAssets(fastEnumeration)
            
        }, completionHandler: { success, error in
            if !success { print("error adding image: \(error)") }
        })
    }
    
    func save(image:UIImage, type:String, success:@escaping ()->Void, failure:@escaping ()->Void){
        
        NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.4, "title":"Check Geolocation capabilities"])
        
        if let imageLocation   =   self.appDelegate.location {
            NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.5, "title":"Get location..."])
            Localizator().getAddress(location: imageLocation, completion: {
                answer in
                NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.6, "title":"Got location : \(answer!)"])
                let date                        =   Date()
                let textToDraw                  =   "\(type) - \(date) - \(answer!)"
                
                let image                       =   self.textToImage(drawText: textToDraw, inImage: image, atPoint: CGPoint.zero)
                
                self.getAlbum(title:CustomPhotoAlbum.albumName, success:{}, failure:{})
                
                PHPhotoLibrary.shared().performChanges({
                    NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.6, "title":"Adding image to : \(CustomPhotoAlbum.albumName)..."])
                    let assetRequest            =   PHAssetChangeRequest.creationRequestForAsset(from: image)
                    assetRequest.location       =   imageLocation
                    assetRequest.creationDate   =   date
                    assetRequest.isHidden       =   true
                    
                    let albumChangeRequest      =   PHAssetCollectionChangeRequest(for: self.album!)
                    albumChangeRequest?.addAssets([assetRequest.placeholderForCreatedAsset!] as NSArray)
                    
                }, completionHandler: { successFul, error in
                    if !successFul {
                        print("error adding image: \(error)")
                        failure()
                    }
                    else
                    {
                        success()
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RELOAD_DEMAND"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.7, "title":"Adding image to : \(CustomPhotoAlbum.albumName)...DONE"])
                    }
                })
            })
        }else{
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "LOCALIZATION_FAILED"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.55, "title":"Geolocation not activated"])
            
            let date                        =   Date()
            let textToDraw                  =   "\(type) - \(date) - LOCATION UNKNOWN"
            
            let image                       =   self.textToImage(drawText: textToDraw, inImage: image, atPoint: CGPoint.zero)
            
            self.getAlbum(title:CustomPhotoAlbum.albumName, success:{
                PHPhotoLibrary.shared().performChanges({
                    
                    let assetRequest            =   PHAssetChangeRequest.creationRequestForAsset(from: image)
                    assetRequest.creationDate   =   date
                    assetRequest.isHidden       =   true
                    
                    let albumChangeRequest      =   PHAssetCollectionChangeRequest(for: self.album!)
                    albumChangeRequest?.addAssets([assetRequest.placeholderForCreatedAsset!] as NSArray)
                    
                }, completionHandler: { successFul, error in
                    if !successFul {
                        print("error adding image: \(error)")
                        failure()
                    }
                    else
                    {
                        success()
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RELOAD_DEMAND"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.7, "title":"Adding image to : \(CustomPhotoAlbum.albumName)...DONE"])
                    }
                })
            }, failure:{
                print("ERROR IN GETTING THE ALBUM")
                failure()
            })
            
            
        }
        
    }

    func createAlbum(title:String, success:@escaping ()->Void, failure:()->Void){
        NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.6, "title":"Album Creation"])
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = '\(CustomPhotoAlbum.albumName)'")
        
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        let rec = result.firstObject as PHAssetCollection!
        if rec == nil {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            }, completionHandler: { successFull, error in
                if !successFull { print("error creating album: \(error)") }
                else{
                    NotificationCenter.default.post(name: Notification.Name(rawValue:"SPINNER_SHOW"), object: ["progress":0.65, "title":"Album created"])
                    success()
                }
            })
        }
    }
    
    func textToImage(drawText: String, inImage: UIImage, atPoint: CGPoint) -> UIImage{
        
        // Setup the font specific variables
        let textColor   =   UIColor.white
        let textFont    =   UIFont(name: "Helvetica Bold", size: 12)!
        
        // Setup the image context using the passed image
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(inImage.size, false, scale)
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            ] as [String : Any]
        
        // Put the image into a rectangle as large as the original image
        inImage.draw(in: CGRect(x: 0, y: 0, width: inImage.size.width, height: inImage.size.height))
        
        // Create a point within the space that is as bit as the image
        let rect = CGRect(x: atPoint.x, y: atPoint.y, width: inImage.size.width, height: inImage.size.height)
        
        // Draw the text into an image
        drawText.draw(in: rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //Pass the image back up to the caller
        return newImage!
        
    }

    
}

extension CustomPhotoAlbum:PHPhotoLibraryChangeObserver{
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photoLibraryDidChange ALERT")
    }
}
