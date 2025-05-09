//
//  CountriesListViewController.swift
//  MyTravelMap
//
//  Created by Oleksandr Roditeiliev on 21.08.2024.
//

import UIKit
import CountryPickerView
import CoreLocation

class CountriesListViewController: UIViewController, CountryPickerViewDelegate, CountryPickerViewDataSource, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, CLLocationManagerDelegate {
  
    @IBOutlet var countriesTableView: UITableView!
    @IBOutlet var countryPickerView: CountryPickerView!
    @IBOutlet var backButton: UIButton!
    
    var countryArray: [CountryData] = []
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        loadCountries()
        setupUI()
    }
    
    func setupUI() {
           countryPickerView.delegate = self
           countryPickerView.dataSource = self
           countriesTableView.dataSource = self
           countriesTableView.delegate = self
           countriesTableView.dragDelegate = self
           countriesTableView.dragInteractionEnabled = true
           countriesTableView.separatorStyle = .none
           countriesTableView.dragInteractionEnabled = true
           countriesTableView.allowsSelection = false
           
           let nib = UINib(nibName: "CountryTableViewCell", bundle: nil)
           countriesTableView.register(nib, forCellReuseIdentifier: "CountryTableViewCell")
       }
    
    @IBAction func selectCountryButton(_ sender: Any) {
        countryPickerView.showCountriesList(from: self)
    }
    
    @IBAction func backButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: CPVCountry) {
        if !countryArray.contains(where: { $0.code == country.code }) {
            let countryData = CountryData(country: country)
            countryArray.append(countryData)
            saveCountries()
            print(countryData)
            countriesTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countryArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryTableViewCell", for: indexPath) as! CountryTableViewCell
        let countryData = countryArray[indexPath.row]
        // Use countryPickerView to get the CPVCountry object
        if let country = countryPickerView.countries.first(where: { $0.code == countryData.code }) {
            cell.setup(with: country) // Pass the found object to the cell
        } else {
            cell.countryLabel.text = "Country is NOT!!!"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            countryArray.remove(at: indexPath.row)
            saveCountries()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // Indicate that all rows can be moved
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Logic for moving a row
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let mover = countryArray.remove(at: sourceIndexPath.row)
        countryArray.insert(mover, at: destinationIndexPath.row)
        saveCountries() // Save changes to the country array
    }
   
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
          dragItem.localObject = countryArray[indexPath.row]
          return [ dragItem ]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
          return 50 
      }
    
    // MARK: - Saving and loading countries in UserDefaults
    func saveCountries() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(countryArray) {
            UserDefaults.standard.set(encoded, forKey: "SavedCountries")
        }
    }
    
    func loadCountries() {
        if let savedCountriesData = UserDefaults.standard.data(forKey: "SavedCountries") {
            let decoder = JSONDecoder()
            if let loadedCountries = try? decoder.decode([CountryData].self, from: savedCountriesData) {
                countryArray = loadedCountries
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
          let status = manager.authorizationStatus
          
          switch status {
          case .authorizedWhenInUse, .authorizedAlways:
              // Start updating location only if permission is granted
              locationManager.startUpdatingLocation()
          case .denied, .restricted:
              print("Разрешение на использование локации запрещено")
          case .notDetermined:
              // If the status is not yet determined, do nothing
              break
          @unknown default:
              break
          }
      }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Stop location updates
        locationManager.stopUpdatingLocation()
        // Get the country based on geolocation
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            if let error = error {
                print("Geocoding error: \(error)")
                return
            }
            if let placemark = placemarks?.first, let countryCode = placemark.isoCountryCode {
                self?.setCountryFromLocation(countryCode: countryCode)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
   
    func setCountryFromLocation(countryCode: String) {
        // Find the country in CountryPickerView by ISO code
        if let country = countryPickerView.countries.first(where: { $0.code == countryCode }) {
            let countryData = CountryData(country: country)
            // Add the country to the beginning of the countryArray
            if !countryArray.contains(where: { $0.code == country.code }) {
                countryArray.insert(countryData, at: 0)
                saveCountries()
                countriesTableView.reloadData()
                NotificationCenter.default.post(name: Notification.Name("CountrySelected"), object: nil, userInfo: ["countryData": countryData])
                     }
            }
            
        }
    }

    
    



