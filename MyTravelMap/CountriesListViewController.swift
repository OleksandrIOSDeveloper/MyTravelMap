//
//  CountriesListViewController.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 21.08.2024.
//

import UIKit
import CountryPickerView

class CountriesListViewController: UIViewController, CountryPickerViewDelegate, CountryPickerViewDataSource, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate {
  
    @IBOutlet var countriesTableView: UITableView!
    @IBOutlet var countryPickerView: CountryPickerView!
    @IBOutlet var backButton: UIButton!
    
    var countryArray: [CountryData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCountries()
        
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
            let countryData = CountryData(country: country) // Создаем объект CountryData
            countryArray.append(countryData)
            saveCountries()
            print(countryData)//
            countriesTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countryArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryTableViewCell", for: indexPath) as! CountryTableViewCell
        let countryData = countryArray[indexPath.row]
        
        // Используем countryPickerView для получения объекта CPVCountry
        if let country = countryPickerView.countries.first(where: { $0.code == countryData.code }) {
            cell.setup(with: country) // Передаем найденный объект в ячейку
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
    
    // Позначити, що всі рядки можна переміщувати
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Логіка переміщення рядка
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let mover = countryArray.remove(at: sourceIndexPath.row)
        countryArray.insert(mover, at: destinationIndexPath.row)
        saveCountries() // Зберегти зміни у масиві країн
    }
   
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
          dragItem.localObject = countryArray[indexPath.row]
          return [ dragItem ]
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
          return 50 
      }
    
    // MARK: - сохр и загрузк стран в UserDefoults
    
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
}


