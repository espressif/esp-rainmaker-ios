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
//  ParamActionCell+Actions.swift
//  ESPRainMaker
//
//  Component: Action Handling
//  Handles: Action invocation, delegate communication

import UIKit

extension ParamActionCell {
    
    // MARK: - Invoke Action
    @objc func invokeAction(_ sender: Any) {
        guard let paramNameToUse = paramName.isEmpty ? param?.name : paramName, !paramNameToUse.isEmpty else { return }
        delegate?.actionInvoked(device: device, param: param, paramName: paramNameToUse)
    }
}

