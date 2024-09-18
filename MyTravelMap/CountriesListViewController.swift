//
//  CountriesListViewController.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 21.08.2024.
//

import UIKit
import CountryPickerView

class CountriesListViewController: UIViewController, CountryPickerViewDelegate, CountryPickerViewDataSource, UITableViewDataSource, UITableViewDelegate {
 
    @IBOutlet var countriesTableView: UITableView!
    @IBOutlet var countryPickerView: CountryPickerView!
    var countryArray: [CPVCountry] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        countryPickerView.showCountryCodeInView = true
        countryPickerView.showPhoneCodeInView = false
        countryPickerView.showCountryCodeInView = true
        countryPickerView.flagSpacingInView = 15
        
        countryPickerView.delegate = self
        countryPickerView.dataSource = self
        countriesTableView.dataSource = self
        countriesTableView.delegate = self
        
        let nib = UINib(nibName: "CountryTableViewCell", bundle: nil)
        countriesTableView.register(nib, forCellReuseIdentifier: "CountryTableViewCell")
        
    }
    
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: CPVCountry){
        countryArray.append(country)
        countriesTableView.reloadData()
        print(countryArray)
        
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        countryArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryTableViewCell") as! CountryTableViewCell
        cell.setup(with: countryArray[indexPath.row])
        return cell

    }

}
