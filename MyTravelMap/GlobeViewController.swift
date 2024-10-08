//
//  ViewController.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 19.08.2024.
//
//

import UIKit
import MapKit
import CoreLocation

class GlobeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var selectedOrSavedCountries: [CountryData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        mapView.mapType = .hybridFlyover
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        setInitialMapCamera()
        loadCountries()
        if let geoJSON = loadGeoJSON() {
            addSelectedCountriesPolygons(geoJSON: geoJSON) // Добавляем выбранные страны на карту
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
        let selectedCountry = selectedOrSavedCountries.map { $0.name }
        
        for feature in geoJSON.features {
            if let countryName = feature.properties?.name, selectedCountry.contains(countryName) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCountries()
        mapView.removeOverlays(mapView.overlays)
        if let geoJSON = loadGeoJSON() {
            addSelectedCountriesPolygons(geoJSON: geoJSON)
        }
    }
    
    @IBAction func addCountryButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let countriesListVC = storyboard.instantiateViewController(withIdentifier: "CountriesListViewController") as? CountriesListViewController {
            self.navigationController?.pushViewController(countriesListVC, animated: true)
        }
    }
}





