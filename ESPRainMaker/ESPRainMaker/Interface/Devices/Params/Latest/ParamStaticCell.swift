// Copyright 2025 Espressif Systems
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
//  ParamStaticCell.swift
//  ESPRainMaker
//

import UIKit

class ParamStaticCell: UITableViewCell {
    
    static let reuseIdentifier = "ParamStaticCell"
    
    // MARK: - UI Elements (Programmatically Created)
    // Made internal for component extensions
    let backView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.cellBackgroundLightGray
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 10
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.masksToBounds = true
        return view
    }()
    
    let controlNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = Constants.textColorDarkGray
        label.alpha = 0.5
        return label
    }()
    
    let controlValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = Constants.textColorDarkGray
        return label
    }()
    
    // MARK: - Properties
    var attribute: Attribute? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use programmatic initialization")
    }
    
    // MARK: - Setup
    // UI setup is handled in ParamStaticCell+UI.swift
    
    // MARK: - prepareForReuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset attribute
        attribute = nil
        
        // Reset UI
        controlNameLabel.text = nil
        controlValueLabel.text = nil
    }
    
    // MARK: - UI Updates
    // UI update logic is handled in ParamStaticCell+UI.swift
}

