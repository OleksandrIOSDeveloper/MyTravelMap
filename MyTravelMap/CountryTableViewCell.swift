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
    @IBOutlet var borderView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.borderView.layer.cornerRadius = 10
        self.borderView.layer.masksToBounds = true
        
        self.borderView.layer.borderWidth = 1.0
        self.borderView.layer.borderColor = UIColor.lightGray.cgColor
        
        self.contentView.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
    }
    
    func setup(with country: CPVCountry) {
        countryLabel.text = country.name
    }
    
    
}
