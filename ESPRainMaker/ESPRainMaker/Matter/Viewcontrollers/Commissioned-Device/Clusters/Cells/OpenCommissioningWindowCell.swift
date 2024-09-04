// Copyright 2023 Espressif Systems
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  OpenCommissioningWindowCell.swift
//  ESPRainmaker
//

import UIKit

protocol OpenCommissioningWindowCellDelegate: AnyObject {
    func openCommissioningWindow()
}

class OpenCommissioningWindowCell: UITableViewCell {

    static let reuseIdentifier = "OpenCommissioningWindowCell"
    weak var delegate: OpenCommissioningWindowCellDelegate?
    
    @IBOutlet weak var openCWButton: PrimaryButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        openCWButton.backgroundColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        openCWButton.tintColor = UIColor(hexString: ESPMatterConstants.customBackgroundColor)
        openCWButton.setTitleColor(UIColor.white, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowOpacity = 0.18
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 2
        layer.shadowColor = UIColor.black.cgColor
        layer.masksToBounds = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func openCommissioningWindow(_ sender: Any) {
        self.delegate?.openCommissioningWindow()
    }
}
