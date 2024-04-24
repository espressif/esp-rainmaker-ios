// Copyright 2024 Espressif Systems
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
//  ClusterSelectionCell.swift
//  ESPRainmaker
//

import UIKit

protocol ClusterSelectedDelegate: AnyObject {
    func clusterSelected(cluster: String)
}

class ClusterSelectionCell: UITableViewCell {

    static let reuseIdentifier = "ClusterSelectionCell"
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var cluster: UILabel!
    var clusterString = ""
    weak var clusterSelectedDelegate: ClusterSelectedDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        self.configure()
        let tap = UITapGestureRecognizer(target: self, action: #selector(clusterSelected))
        self.cluster.addGestureRecognizer(tap)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure() {
        self.container.layer.borderWidth = 1
        self.container.layer.cornerRadius = 10
        self.container.layer.borderColor = UIColor.lightGray.cgColor
        self.container.layer.masksToBounds = true
    }
    
    @objc func clusterSelected() {
        self.clusterSelectedDelegate?.clusterSelected(cluster: clusterString)
    }
}
