//
//  CountryData.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 23.09.2024.
//

import Foundation
import CountryPickerView

struct CountryData: Codable {
    let name: String
    let code: String
    
    // ініт із CPVCountry
    init(country: CPVCountry) {
        self.name = country.name
        self.code = country.code
    }
    
    // ініт із сохран данних
    init(name: String, code: String) {
        self.name = name
        self.code = code
    }
}
