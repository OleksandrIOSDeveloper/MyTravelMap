//
//  ViewController.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 19.08.2024.
//
//
//import UIKit
//import MapKit
//import CoreLocation
//
//class GlobeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
//    
//    @IBOutlet var mapView: MKMapView!
//    
//    let locationManager = CLLocationManager()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        mapView.delegate = self
//        locationManager.delegate = self
//        mapView.mapType = .hybridFlyover
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//        
//        setInitialMapCamera()
//        
////        let searchRequest = MKLocalSearch.Request()
////            searchRequest.naturalLanguageQuery = "USA"
////            
////            let search = MKLocalSearch(request: searchRequest)
////            
////            search.start { response, error in
////                guard let response = response else {
////                    print("Error: \(error?.localizedDescription ?? "Unknown error").")
////                    return
////                }
////                
////                self.mapView.setRegion(response.boundingRegion, animated: true)
////            }
//        
//    }
//    
//    private func setInitialMapCamera() {
//        let centerCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
//        let camera = MKMapCamera(lookingAtCenter: centerCoordinate, fromDistance: 50_000_000, pitch: 0, heading: 0)
//        mapView.setCamera(camera, animated: true)
//    }
//
//    @IBAction func addCountryButton(_ sender: Any) {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        if let countriesListVC = storyboard.instantiateViewController(withIdentifier: "CountriesListViewController") as? CountriesListViewController {
//            self.navigationController?.pushViewController(countriesListVC, animated: true)
//        }
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        self.navigationController?.setNavigationBarHidden(false, animated: animated)
//        
//    }
//    
//}

import UIKit
import MapKit
import CoreLocation

class GlobeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        mapView.mapType = .hybridFlyover
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        setInitialMapCamera()
        
        
        
        if let geoJSON = loadGeoJSON() {
            addSelectedCountriesPolygons(geoJSON: geoJSON) // Добавляем выбранные страны на карту
        }
    }
    
    private func setInitialMapCamera() {
        let centerCoordinate = CLLocationCoordinate2D(latitude: 48.3794, longitude: 31.1656) // Центр Украины
        let camera = MKMapCamera(lookingAtCenter: centerCoordinate, fromDistance: 50_000_000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    
    // Функция для загрузки GeoJSON файла
    func loadGeoJSON() -> GeoJSON? {
        if let url = Bundle.main.url(forResource: "countries", withExtension: "geo.json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let geoJSON = try decoder.decode(GeoJSON.self, from: data)
                return geoJSON
            } catch {
                print("Ошибка при загрузке JSON: \(error)")
            }
        }
        return nil
    }
    
    private func addSelectedCountriesPolygons(geoJSON: GeoJSON) {
        let selectedCountries = ["UKR", "HRV", "FRA",] // ISO3 коды стран
        
        for feature in geoJSON.features {
            if selectedCountries.contains(feature.id ?? "") { // Проверяем наличие кода страны
                guard let geometry = feature.geometry else { continue }
                
                switch geometry.type {
                case "Polygon":
                    // Обработка обычного полигона
                    if case let .polygon(coordinates) = geometry.coordinates {
                        for ring in coordinates {
                            addPolygon(from: ring)
                        }
                    }
                case "MultiPolygon":
                    // Обработка мультиполигона
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
    
    
    
    // Делегатный метод для рендеринга overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygonOverlay = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygonOverlay)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    @IBAction func addCountryButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let countriesListVC = storyboard.instantiateViewController(withIdentifier: "CountriesListViewController") as? CountriesListViewController {
            self.navigationController?.pushViewController(countriesListVC, animated: true)
        }
    }
}





