//
//  CountryTableViewCell.swift
//  MyTravelMap
//
//  Created by Oleksandr Roditeiliev on 18.09.2024.
//

import UIKit
import CountryPickerView

class CountryTableViewCell: UITableViewCell {
    
    @IBOutlet var countryLabel: UILabel!
    @IBOutlet var borderView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.borderView.layer.cornerRadius = 10
        self.borderView.layer.masksToBounds = true
        self.borderView.layer.borderWidth = 1.5
        self.borderView.layer.borderColor = UIColor(red: 3/255, green: 168/255, blue: 225/255, alpha: 1.0).cgColor
        self.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    func setup(with country: CPVCountry) {
        let flag = flag(from: country.code)
        countryLabel.text = "\(flag) \(country.name)"
    }

    func flag(from countryCode: String) -> String {
        let base: UInt32 = 127397
        var flagString = ""
        
        for scalar in countryCode.uppercased().unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                flagString.unicodeScalars.append(scalarValue)
            }
        }
        return flagString
    }

}
