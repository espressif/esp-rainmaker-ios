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
//  DocumentViewController.swift
//  ESPRainMaker
//

import UIKit
import WebKit

class DocumentViewController: UIViewController {
    var documentLink: String!
    @IBOutlet var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.load(URLRequest(url: URL(string: documentLink)!))
        // Do any additional setup after loading the view.
    }

    @IBAction func closeWebView(_: Any) {
        dismiss(animated: true, completion: nil)
    }
}
