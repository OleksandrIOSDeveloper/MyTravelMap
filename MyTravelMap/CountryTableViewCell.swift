//
//  CountryTableViewCell.swift
//  MyTravelMap
//
//  Created by Александр Родителев on 18.09.2024.
//

import UIKit
import CountryPickerView

class CountryTableViewCell: UITableViewCell {

    
    @IBOutlet var countryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(with country: CPVCountry) {
        countryLabel.text = country.name
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
