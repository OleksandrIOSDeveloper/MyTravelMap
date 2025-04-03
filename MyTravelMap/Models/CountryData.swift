//
//  CountryData.swift
//  MyTravelMap
//
//  Created by Oleksandr Roditeiliev on 23.09.2024.
//

import Foundation
import CountryPickerView

struct CountryData: Codable {
    let name: String
    let code: String
    
    // init from CPVCountry
    init(country: CPVCountry) {
        self.name = country.name
        self.code = country.code
    }
    
    // init from сохран данних
    init(name: String, code: String) {
        self.name = name
        self.code = code
    }
}
