//
//  ViewController.swift
//  MyTravelMap
//
//  Created by Oleksandr Roditeiliev on 19.08.2024.
//
//

import UIKit
import MapKit
import CoreLocation
import ReplayKit

class GlobeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, RPPreviewViewControllerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var buttonsStackView: UIStackView!
    
    let locationManager = CLLocationManager()
    var selectedOrSavedCountries: [CountryData] = []
    var currentCountryIndex: Int = 0
    var timer: Timer?
    let recorder = RPScreenRecorder.shared()
    var defaultCoordinate = CLLocationCoordinate2D(latitude: 48.3794, longitude: 31.1656) // Center of Ukraine
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        mapView.mapType = .hybridFlyover
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        setInitialMapCamera()
        loadCountries()
        NotificationCenter.default.addObserver(self, selector: #selector(countrySelected(_:)), name: Notification.Name("CountrySelected"), object: nil)
        if let geoJSON = loadGeoJSON() {
            addSelectedCountriesPolygons(geoJSON: geoJSON) // Add selected countries to the map
        }
    }
    
    @objc func countrySelected(_ notification: Notification) {
        if let userInfo = notification.userInfo, let countryData = userInfo["countryData"] as? CountryData {
            if !selectedOrSavedCountries.contains(where: { $0.code == countryData.code }) {
                selectedOrSavedCountries.append(countryData)
                //  saveCountries()
                mapView.removeOverlays(mapView.overlays)
                if let geoJSON = loadGeoJSON() {
                    addSelectedCountriesPolygons(geoJSON: geoJSON)
                }
            }
        }
    }
    
    func loadCountries() {
        if let savedCountriesData = UserDefaults.standard.data(forKey: "SavedCountries") {
            let decoder = JSONDecoder()
            if let loadedCountries = try? decoder.decode([CountryData].self, from: savedCountriesData) {
                selectedOrSavedCountries = loadedCountries
            }
        }
    }
    
    func loadGeoJSON() -> GeoJSON? {
        if let url = Bundle.main.url(forResource: "countries", withExtension: "geo.json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let geoJSON = try decoder.decode(GeoJSON.self, from: data)
                return geoJSON
            } catch {
                print("Error loading JSON: \(error)")
            }
        }
        return nil
    }
    
    private func addSelectedCountriesPolygons(geoJSON: GeoJSON) {
        let selectedCountry = selectedOrSavedCountries.map { $0.name }
        for feature in geoJSON.features {
            if let countryName = feature.properties?.name, selectedCountry.contains(countryName) {
                guard let geometry = feature.geometry else { continue }
                switch geometry.type {
                case "Polygon":
                    if case let .polygon(coordinates) = geometry.coordinates {
                        for ring in coordinates {
                            addPolygon(from: ring)
                        }
                    }
                case "MultiPolygon":
                    if case let .multiPolygon(coordinates) = geometry.coordinates {
                        for polygon in coordinates {
                            for ring in polygon {
                                addPolygon(from: ring)
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func addPolygon(from coordinatesArray: [[Double]]) {
        var coordinates = [CLLocationCoordinate2D]()
        for coordinatePair in coordinatesArray {
            if coordinatePair.count == 2 {
                let longitude = coordinatePair[0]
                let latitude = coordinatePair[1]
                coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        if !coordinates.isEmpty {
            let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polygon)
        }
    }
    // Delegate method for rendering overlays
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygonOverlay = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygonOverlay)
            renderer.fillColor = UIColor(hex: "#eac500", alpha: 0.8)
            renderer.strokeColor = UIColor(hex: "#eac500")
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCountries()
        mapView.removeOverlays(mapView.overlays)
        if let geoJSON = loadGeoJSON() {
            addSelectedCountriesPolygons(geoJSON: geoJSON)
        }
    }
    
    // If the user has granted location permission
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // Delegate method triggered when location is updated
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let userCoordinate = location.coordinate
        defaultCoordinate = userCoordinate
        setInitialMapCamera()
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
    
    private func setInitialMapCamera() {
        let camera = MKMapCamera(lookingAtCenter: defaultCoordinate, fromDistance: 50_000_000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("CountrySelected"), object: nil)
    }
    
    func resetAllCountryHighlights() {
        mapView.removeOverlays(mapView.overlays)
    }
    
    func highlightCountry(at index: Int) {
        guard index < selectedOrSavedCountries.count else {
            stopRecording()
            return
        }
        let country = selectedOrSavedCountries[index]
        if let geoJSON = loadGeoJSON() {
            // Filter GeoJSON to keep only the selected country
            let filteredGeoJSON = GeoJSON(
                type: geoJSON.type,
                features: geoJSON.features.filter { $0.properties?.name == country.name }
            )
            // Add the polygon to the map
            addSelectedCountriesPolygons(geoJSON: filteredGeoJSON)
            // Move the camera to the polygon area
            moveToPolygon(for: filteredGeoJSON)
        }
    }
    
    func moveToPolygon(for geoJSON: GeoJSON) {
        var boundingMapRect: MKMapRect = .null
        for feature in geoJSON.features {
            guard let geometry = feature.geometry else { continue }
            switch geometry.type {
            case "Polygon":
                if case let .polygon(coordinates) = geometry.coordinates {
                    for ring in coordinates {
                        let polygon = createPolygon(from: ring)
                        boundingMapRect = boundingMapRect.union(polygon.boundingMapRect)
                    }
                }
            case "MultiPolygon":
                if case let .multiPolygon(coordinates) = geometry.coordinates {
                    for polygon in coordinates {
                        for ring in polygon {
                            let polygon = createPolygon(from: ring)
                            boundingMapRect = boundingMapRect.union(polygon.boundingMapRect)
                        }
                    }
                }
            default:
                continue
            }
        }
        
        // Move the camera to the polygon area
        if !boundingMapRect.isNull {
            mapView.setVisibleMapRect(boundingMapRect, edgePadding: UIEdgeInsets(top: 120, left: 120, bottom: 120, right: 120), animated: true)
        }
    }
    
    private func createPolygon(from coordinatesArray: [[Double]]) -> MKPolygon {
        var coordinates = [CLLocationCoordinate2D]()
        for coordinatePair in coordinatesArray {
            if coordinatePair.count == 2 {
                let longitude = coordinatePair[0]
                let latitude = coordinatePair[1]
                coordinates.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        return MKPolygon(coordinates: coordinates, count: coordinates.count)
    }
    
    
    func stopRecording() {
        if currentCountryIndex >= selectedOrSavedCountries.count {
            timer?.invalidate()
            timer = nil
            setInitialMapCamera()
            buttonsStackView.isHidden = false
            recorder.stopRecording { [weak self] (previewController, error) in
                self?.timer?.invalidate()
                self?.currentCountryIndex = 0
                if let error = error {
                    print("Error stopping recording: \(error.localizedDescription)")
                    return
                }
                if let previewController = previewController {
                    previewController.previewControllerDelegate = self
                    self?.present(previewController, animated: true, completion: nil)
                }
            }
            return
        }
    }
    
    func startRecording() {
        setInitialMapCamera()
        recorder.startRecording { error in
            self.startCountriesAnimation()
            if let error = error {
                print("Error starting recording: \(error.localizedDescription)")
            } else {
                print("Recording started")
            }
        }
    }
    
    private func startCountriesAnimation() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            highlightCountry(at: currentCountryIndex)
            currentCountryIndex += 1
        }
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func playAnimationButton(_ sender: Any) {
        buttonsStackView.isHidden = true
        resetAllCountryHighlights()
        startRecording()
    }
    
    @IBAction func addCountryButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let countriesListVC = storyboard.instantiateViewController(withIdentifier: "CountriesListViewController") as? CountriesListViewController {
            self.navigationController?.pushViewController(countriesListVC, animated: true)
        }
    }
}





