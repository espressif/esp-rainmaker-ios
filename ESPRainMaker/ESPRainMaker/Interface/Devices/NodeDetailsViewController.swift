// Copyright 2020 Espressif Systems
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
//  NodeDetailsViewController.swift
//  ESPRainMaker
//

import UIKit

class NodeDetailsViewController: UIViewController {
    var currentNode: Node!
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var nodeIDLabel: UILabel!
    @IBOutlet var configVersionLabel: UILabel!
    @IBOutlet var fwVersionLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        deviceNameLabel.text = currentNode.info?.name ?? ""
        nodeIDLabel.text = currentNode.node_id ?? ""
        configVersionLabel.text = currentNode.config_version ?? ""
        fwVersionLabel.text = currentNode.info?.fw_version ?? ""
        typeLabel.text = currentNode.info?.type ?? ""
    }

    @IBAction func deleteNode(_: Any) {
        Utility.showLoader(message: "Deleting node", view: view)
        let parameters = ["user_id": User.shared.userInfo.userID, "node_id": currentNode.node_id!, "secret_key": "", "operation": "remove"]
        NetworkManager.shared.addDeviceToUser(parameter: parameters) { _, error in
            if error == nil {
                User.shared.associatedNodeList?.removeAll(where: { node -> Bool in
                    node.node_id == self.currentNode.node_id
                })
            }
            DispatchQueue.main.async {
                Utility.hideLoader(view: self.view)
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
    }

    @IBAction func backButtonPressed(_: Any) {
        navigationController?.popViewController(animated: true)
    }
}
