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
        NotificationCenter.default.addObserver(self, selector: #selector(countrySelected(_:)), name: Notification.Name("CountrySelected"), object: nil)
        if let geoJSON = loadGeoJSON() {
            addSelectedCountriesPolygons(geoJSON: geoJSON) // Добавляем выбранные страны на карту
        }
    }
    
    @objc func countrySelected(_ notification: Notification) {
         if let userInfo = notification.userInfo, let countryData = userInfo["countryData"] as? CountryData {
             // Добавляем выбранную страну в список стран
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
    
    
    // Если пользователь разрешил использовать геопозицию
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    // Метод делегата, который срабатывает при получении локации
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let userCoordinate = location.coordinate
        
        // Настроим камеру на текущие координаты пользователя
        setMapCamera(to: userCoordinate)
        
        // Останавливаем обновление локации после получения данных
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Не удалось получить локацию: \(error.localizedDescription)")
    }
    
    // Устанавливаем начальное местоположение на центр Украины
    private func setInitialMapCamera() {
        let centerCoordinate = CLLocationCoordinate2D(latitude: 48.3794, longitude: 31.1656) // Центр Украины
        let camera = MKMapCamera(lookingAtCenter: centerCoordinate, fromDistance: 50_000_000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    
    // Настроить камеру на координаты пользователя
    private func setMapCamera(to coordinate: CLLocationCoordinate2D) {
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 50_000_000, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
  
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("CountrySelected"), object: nil)
    }
    
    
    
    @IBAction func playAnimationButton(_ sender: Any) {
        
    }
    
    
    @IBAction func addCountryButton(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let countriesListVC = storyboard.instantiateViewController(withIdentifier: "CountriesListViewController") as? CountriesListViewController {
            self.navigationController?.pushViewController(countriesListVC, animated: true)
        }
    }
}





