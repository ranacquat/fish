//
//  Localizator.swift
//  KYCMobile
//
//  Created by Jan ATAC on 30/11/2016.
//  Copyright © 2016 Vialink. All rights reserved.
//

import Foundation
import CoreLocation

class Localizator {

    func getAddress(location:CLLocation?,completion: @escaping (_ answer: String?) -> Void){
        
        if let pictureLocation = location {
            CLGeocoder().reverseGeocodeLocation(pictureLocation, completionHandler: {(placemarks, error) -> Void in
                if (error != nil) {
                    print("Reverse geocoder failed with an error" + (error?.localizedDescription)!)
                    completion("")
                } else if (placemarks?.count)! > 0 {
                    let pm = (placemarks?[0])! as CLPlacemark
                    completion(self.displayLocationInfo(placemark: pm))
                } else {
                    print("Problems with the data received from geocoder.")
                    completion("")
                }
            })
        }
        
    }
    
    func displayLocationInfo(placemark: CLPlacemark?) -> String
    {
        if let containsPlacemark = placemark
        {
            let locality = (containsPlacemark.locality != nil) ? containsPlacemark.locality : ""
            return locality!
        } else {
            return ""
        }
    }
}
