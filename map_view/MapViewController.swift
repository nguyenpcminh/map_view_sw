//
//  MapViewController.swift
//  map_view
//
//  Created by Nguyen Pham Cong Minh on 28/12/2021.
//

import Foundation
import UIKit
import Layoutless
import MapKit
import RxSwift

class MapViewController: UIViewController {
    
    private let vm = MapViewModelV2()
    private let bag = DisposeBag()
    
    let tfDirection : UITextField = {
        let tf = UITextField()
        tf.placeholder = "Input address"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    let getDirection : UIButton = {
        let btn = UIButton()
        btn.setTitleColor(.systemBlue, for: .normal)
        btn.setTitle("Get direction", for: .normal)
        
        return btn
    }()
    
    let startNav : UIButton = {
        let btn = UIButton()
        btn.setTitle("Start Navigation", for: .normal)
        btn.setTitleColor(.systemBlue, for: .normal)
        return btn
    }()
    
    let mapView : MKMapView = {
        let mv = MKMapView()
        mv.showsUserLocation = true
        return mv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configLayout()
        navigationItem.title = "Map view"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bindingCoordinate()
        bindingBtnGet()
        bindingDesination()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vm.stopUpdateLocation()
    }
    
    private func centerView(coordinate center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 500, longitudinalMeters: 500)
        
        mapView.setRegion(region, animated: true)
    }
    
    private func mapRoute(){
        guard let currentLocation = vm.currentLocation.value , let destinationCoordinate = vm.destinationCoordinate.value else {return}
        
        
        let scourcePlacemark = MKPlacemark(coordinate: currentLocation)
        let destionPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let source = MKMapItem(placemark: scourcePlacemark)
        let destination = MKMapItem(placemark: destionPlacemark)
        
        let request = MKDirections.Request()
        request.destination = destination
        request.source = source
        request.transportType = .automobile
    
        let direction = MKDirections(request: request)
        direction.calculate {[weak self] response, err in
            if let err = err {
                print("co loi : \(err.localizedDescription)")
            }
            guard let response = response,let route = response.routes.last else {return}
            self?.mapView.addOverlay(route.polyline)
            self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), animated: true)
        }
        
        
//        self.mapView.addOverlay()
    }
    
    private func bindingDesination() {
        vm.destinationCoordinate.asObservable().subscribe {[weak self] value in
            if value == nil {
                guard let location = self?.vm.currentLocation.value else {return}
                self?.centerView(coordinate: location)
            }
            self?.mapRoute()
        } onError: { err in
            print(err)
        }.disposed(by: bag)

    }
    
    private func bindingCoordinate() {
        vm.currentLocation.asObservable().subscribe {[weak self] coordinate in
            guard let coordinate = coordinate else {return}
            self?.centerView(coordinate: coordinate)
        } onError: { err in
            print(err)
        }.disposed(by: bag)

    }
    
    private func bindingBtnGet() {
        getDirection.rx.tap
            .throttle(RxTimeInterval.milliseconds(700), scheduler: MainScheduler.instance)
            .subscribe {[weak self] _ in
            self?.view.endEditing(true)
            guard let text = self?.tfDirection.text else { return}
            self?.vm.searchAddressString(text: text)
            if text == "" {
                self?.mapView.removeOverlays((self?.mapView.overlays)!)
                guard let currentLocation = self?.vm.currentLocation.value else {return}
                self?.centerView(coordinate: currentLocation)
            }
        } onError: { err in
            print(err)
        }.disposed(by: bag)
    }
    
    private func configLayout() {
        mapView.delegate = self
        
        let search = stack(.horizontal)(
            tfDirection,
            getDirection.sizing(toWidth: 88)
        )
        
        stack(.vertical)(
            search,
            startNav.sizing(toHeight: 50),
            mapView.sizing(toHeight: Length(floatLiteral: Float(view.bounds.size.height) - 300))
        )   .scrolling(.vertical)
            .fillingParent(relativeToSafeArea: false)
            .layout(in: view)
    }
}

extension MapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = .systemBlue
        return render
    }
}
