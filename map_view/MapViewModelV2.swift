//
//  MapViewModelV2.swift
//  map_view
//
//  Created by Nguyen Pham Cong Minh on 28/12/2021.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

class MapViewModelV2 : NSObject {
    var currentLocation = BehaviorRelay<CLLocationCoordinate2D?>.init(value: nil)
    var destinationCoordinate = BehaviorRelay<CLLocationCoordinate2D?>.init(value: nil)
    let locationManger : CLLocationManager = {
        let manager = CLLocationManager()
        let authorization : CLAuthorizationStatus
        
      
        if #available(iOS 14.0, *) {
            authorization = manager.authorizationStatus
        } else {
            authorization = CLLocationManager.authorizationStatus()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            switch authorization {
            case .notDetermined,.restricted,.denied:
                manager.requestAlwaysAuthorization()
            case .authorizedAlways,.authorized,.authorizedWhenInUse:
                break
            default:
                break
            }
        } else {
            print("Location not enable")
        }
        
        return manager
    }()
    
    override init() {
        super.init()
        locationManger.delegate = self
        locationManger.startUpdatingLocation()
    }
    
     func stopUpdateLocation() {
        locationManger.stopUpdatingLocation()
    }
    
    func searchAddressString(text : String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(text) {[weak self] clPlacemarks, err in
            guard let clPlacemarks = clPlacemarks, let clPlacemark = clPlacemarks.last,let location = clPlacemark.location else {return}
            self?.destinationCoordinate.accept(location.coordinate)
        }
    }
}

extension MapViewModelV2 : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        currentLocation.accept(location.coordinate)
    }
}
