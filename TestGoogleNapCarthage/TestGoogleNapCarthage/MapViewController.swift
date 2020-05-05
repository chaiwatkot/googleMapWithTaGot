//
//  ViewController.swift
//  TestGoogleNapCarthage
//
//  Created by CHAIWAT CHANTHASEN on 26/4/2563 BE.
//  Copyright © 2563 CHAIWAT CHANTHASEN. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

protocol SelectedLocationDelegate: class {
  func selectedLocationJa(coordinate: CLLocationCoordinate2D, addressTitle: String)
}

class MapViewController: UIViewController {
  
  weak var delegate: SelectedLocationDelegate?
  
  private var placesClient: GMSPlacesClient!
  private var currentLocation: CLLocation?
  private var currentCoordinate: CLLocationCoordinate2D?
  private var currentAddressText: String?
  
  var zoomLevel: Float = 14.0
  
  var selectedPlace: GMSPlace?
  
  @IBOutlet private weak var mapView: GMSMapView!
  
  private lazy var locationManager: CLLocationManager =  {
    return CLLocationManager()
  }()
  
  var resultsViewController: GMSAutocompleteResultsViewController?
  var searchController: UISearchController?
  var resultView: UITextView?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationBar()
    placesClient = GMSPlacesClient.shared()
    checkPermissionLocation()
    setupmapview()
  }
  
  func setupNavigationBar() {
    let image = UIImage(systemName: "arrow.left")
    let backButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(defaultBackAction))
    backButton.tintColor = UIColor(cgColor: CGColor(srgbRed: 118/255, green: 49/255, blue: 193/255, alpha: 1.0))
    navigationItem.leftBarButtonItem = backButton
    navigationItem.title = ""
    let backItem = UIBarButtonItem()
    backItem.title = " "
    navigationItem.backBarButtonItem = backItem
  }
  
  @objc func defaultBackAction() {
    navigationController?.popViewController(animated: true)
  }
  
  private func setupmapview() {
    setupLocationManager()
    mapView.isMyLocationEnabled = true
    mapView.settings.compassButton = true
    mapView.settings.myLocationButton = true
    mapView.delegate = self
    setupCurrentLocation()
  }
  
  private func setupLocationManager() {
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.requestAlwaysAuthorization()
    locationManager.distanceFilter = 50
    locationManager.startUpdatingLocation()
    locationManager.delegate = self
  }
  
  private func setupCurrentLocation() {
    setupSearchBar()
    getCurrentLocation()
  }
  
  private func getCurrentLocation() {
    placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
      if let error = error {
        print("Current Place error: \(error.localizedDescription)")
        return
      }
      
      if let placeLikelihoodList = placeLikelihoodList {
        let place = placeLikelihoodList.likelihoods.first?.place
        if let place = place {
          let name = place.name
          let detail = place.formattedAddress?.components(separatedBy: ", ")
            .joined(separator: "\n")
          let lat = place.coordinate.latitude
          let long = place.coordinate.longitude
          self.currentAddressText = "\(name!) \(detail!)"
          self.currentLocation = CLLocation(latitude: lat, longitude: long)
          self.currentCoordinate = place.coordinate
          self.createMarker(lat: lat, long: long, title: name!, snip: detail!)
          self.setCamera(lat: lat, long: long)
        }
      }
    })
  }
  
  @IBAction private func SelectedJa() {
    selectedLocationNaja()
  }
  
  private func selectedLocationNaja() {
    guard let currentCoordinate = self.currentCoordinate, let addressText = currentAddressText else {
      let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
      let alert = UIAlertController(title: "Need selected place for \"Robinhood\"", message: "please selected location.", preferredStyle: .alert)
      alert.addAction(okAction)
      
      present(alert, animated: true, completion: nil)
      return
    }
    
    let confirmButton = UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
      self?.delegate?.selectedLocationJa(coordinate: currentCoordinate, addressTitle: addressText)
      self?.navigationController?.popViewController(animated: true)
    }
    
    let cancelButton = UIAlertAction(title: "cancel", style: .destructive, handler: nil)
    
    let alert = UIAlertController(title: "Please confirm you selected location.", message: addressText, preferredStyle: .alert)
    alert.addAction(cancelButton)
    alert.addAction(confirmButton)
    
    present(alert, animated: true, completion: nil)
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
  
  private func setCamera(lat: CLLocationDegrees,long: CLLocationDegrees) {
    let camera = GMSCameraPosition.camera(withLatitude: lat, longitude: long, zoom: 14)
    mapView.camera = camera
  }
  
  private func createMarker(lat: CLLocationDegrees,long: CLLocationDegrees, title: String, snip: String) {
    mapView.clear()
    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
    let marker = GMSMarker()
    marker.position = coordinate
    marker.title = title
    marker.snippet = snip
    marker.map = mapView
    
    currentAddressText = "\(title) \(snip)"
    currentCoordinate = coordinate
  }
  
  private func setupSearchBar() {
    resultsViewController = GMSAutocompleteResultsViewController()
    resultsViewController?.delegate = self
        
    let filter = GMSAutocompleteFilter()
    filter.type = .noFilter
    filter.country = "TH"
    resultsViewController?.autocompleteFilter = filter
    
    searchController = UISearchController(searchResultsController: resultsViewController)
    searchController?.searchBar.searchBarStyle = .minimal
    searchController?.searchBar.tintColor = UIColor(cgColor: CGColor(srgbRed: 118/255, green: 49/255, blue: 193/255, alpha: 1.0))
    searchController?.searchResultsUpdater = resultsViewController
    
    // Put the search bar in the navigation bar.
    searchController?.searchBar.sizeToFit()
    navigationItem.titleView = searchController?.searchBar
    
    // When UISearchController presents the results view, present it in
    // this view controller, not one further up the chain.
    definesPresentationContext = true
    
    // Prevent the navigation bar from being hidden when searching.
    searchController?.hidesNavigationBarDuringPresentation = false
  }
  
  func getDetailWithPOI(placeID: String, name: String) {
    let field = GMSPlaceField.all
    placesClient.fetchPlace(fromPlaceID: placeID, placeFields: field, sessionToken: nil) { [weak self] (places, error) in
      if let errorJa = error {
        print(errorJa)
      }
      
      let lat = places?.coordinate.latitude
      let long = places?.coordinate.longitude
      let title = name
      let snip = places?.formattedAddress?.components(separatedBy: ", ")
        .joined(separator: "\n")
      self?.createMarker(lat: lat!, long: long!, title: title, snip: snip!)
    }
  }
  
  func getPlacesDetail(coordinate: CLLocationCoordinate2D) {
    let coder = GMSGeocoder()
    coder.reverseGeocodeCoordinate(coordinate) { [weak self] (response, error) in
      if let errorNaja = error {
        // handle this
        print(errorNaja)
      }
      
      if let places = response?.firstResult() {
        let lat = places.coordinate.latitude
        let long = places.coordinate.longitude
        let title: String = "\(places.thoroughfare ?? "")"
        let snip: String = "\(places.locality ?? places.subLocality ?? "") \(places.administrativeArea ?? "") \(places.postalCode ?? "")"
        self?.createMarker(lat: lat, long: long, title: title, snip: snip)
      }
    }
  }
}

extension MapViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //     let location: CLLocation = locations.last!
    //     print("Location: \(location)")
    //
    //     let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
    //                                           longitude: location.coordinate.longitude,
    //                                           zoom: zoomLevel)
    //
    //     if mapView.isHidden {
    //       mapView.isHidden = false
    //       mapView.camera = camera
    //     } else {
    //       mapView.animate(to: camera)
    //     }
    //    listLikelyPlaces()
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    locationManager.stopUpdatingLocation()
  }
}

extension MapViewController: GMSMapViewDelegate {
  func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
    getPlacesDetail(coordinate: coordinate)
  }
  
  func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
    getDetailWithPOI(placeID: placeID, name: name)
  }
}

extension MapViewController: GMSAutocompleteResultsViewControllerDelegate {
  func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didAutocompleteWith place: GMSPlace) {
    searchController?.isActive = false
    setCamera(lat: place.coordinate.latitude, long: place.coordinate.longitude)
    createMarker(lat: place.coordinate.latitude, long: place.coordinate.longitude, title: place.name!, snip: place.formattedAddress!)
  }
  
  func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                         didFailAutocompleteWithError error: Error) {
    // TODO: handle the error.
    print("Error: ", error.localizedDescription)
  }
  
  // Turn the network activity indicator on and off again.
  func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) { }
  
  func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) { }
}
