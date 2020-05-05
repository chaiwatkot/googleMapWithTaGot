//
//  EnterAddressViewContriller.swift
//  TestGoogleNapCarthage
//
//  Created by CHAIWAT CHANTHASEN on 27/4/2563 BE.
//  Copyright © 2563 CHAIWAT CHANTHASEN. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps

class EnterAddressViewController: UIViewController {
  
  @IBOutlet weak var selectAddress: UILabel!
  @IBOutlet weak var currentAddress: UILabel!
  @IBOutlet weak var curentView: UIView!
  @IBOutlet weak var loadingView: UIView!
  
  private lazy var locationManager: CLLocationManager =  {
    return CLLocationManager()
  }()
  
  var placesClient: GMSPlacesClient!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    checkPermissionLocation()
    loadingView.isHidden = true
    title = "Selected location"
//    setLanguage()
  }
  
  func setLanguage() {
//    let lang = UserDefaults.standard.object(forKey: "AppleLanguages") as? [String]
////    let lang = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String]
////    let lang = UserDefaults.standard.string(forKey: "AppleLanguages")
//    print(lang)
//    if lang?.isEmpty ?? false {
//      UserDefaults.standard.set("th", forKey: "AppleLanguages")
//      UserDefaults.standard.synchronize()
//    } else {
//      UserDefaults.standard.set("en", forKey: "AppleLanguages")
//      UserDefaults.standard.synchronize()
//    }
  }
  
  private func checkPermissionLocation() {
    if CLLocationManager.locationServicesEnabled() {
      checkLocationAuthorize()
    }
  }
  
  private func checkLocationAuthorize() {
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      locationManager.requestWhenInUseAuthorization()
    default: break
    }
  }
  
  private func getCurrentLocation() {
    loadingView.isHidden = false
    placesClient = GMSPlacesClient.shared()

    placesClient.currentPlace(callback: { [weak self] (placeLikelihoodList, error) -> Void in
      self?.loadingView.isHidden = true
      if let error = error {
        print("Current Place error: \(error.localizedDescription)")
        return
      }
      
      if let placeLikelihoodList = placeLikelihoodList {
        let place = placeLikelihoodList.likelihoods.first?.place
        if let place = place {
          self?.currentAddress.text = "\(place.name!) \(place.formattedAddress!.components(separatedBy: ", ").joined(separator: "\n"))"
        }
      }
    })
  }
  
  @IBAction private func getLocationJa() {
    getCurrentLocation()
  }
  
  @IBAction private func navigateToMap() {
    navigate()
  }
  
  func navigate() {
    guard let mapViewController = UIStoryboard(name: "MapView", bundle: Bundle(for: type(of: self))).instantiateViewController(withIdentifier: "MapViewController") as? MapViewController else { return }
    mapViewController.delegate = self
    navigationController?.pushViewController(mapViewController, animated: true)
  }
}

extension EnterAddressViewController: SelectedLocationDelegate {
  func selectedLocationJa(coordinate: CLLocationCoordinate2D, addressTitle: String) {
    currentAddress.text = addressTitle
  }
}
