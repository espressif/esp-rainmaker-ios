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
//  ESPGetUserNOCService.swift
//  ESPRainMaker
//

#if ESPRainMakerMatter
import Foundation

@available(iOS 16.4, *)
class ESPGetUserNOCService {
    
    let csrQueue = DispatchQueue(label: "com.matterqueue.generate.csr")
    var groups: [NodeGroup]
    var index: Int
    var completion: (() -> Void)?
    
    init(groups: [NodeGroup]) {
        index = 0
        self.groups = groups
    }
    
    func issueUserNOC(completion: @escaping () -> Void) {
        self.completion = completion
        self.issueUserNOC(index: index)
    }
    
    func issueUserNOC(index: Int) {
        if self.groups.count > 0, self.index < self.groups.count {
            let group = groups[index]
            if let groupId = group.group_id, let isMatter = group.is_matter, isMatter {
                guard let _ = ESPMatterFabricDetails.shared.getUserNOCDetails(groupId: groupId) else {
                    self.csrQueue.async {
                        var finalCSRString = ""
                        ESPMTRCommissioner.shared.generateCSR(groupId: groupId) { csr in
                            if let csr = csr {
                                finalCSRString = csr.replacingOccurrences(of: "\n", with: "")
                                finalCSRString = "\(ESPMatterConstants.csrHeader)\n" + finalCSRString + "\n\(ESPMatterConstants.csrFooter)"
                            }
                            let nodeGroupURL = Configuration.shared.awsConfiguration.baseURL + "/" + Constants.apiVersion
                            let service = ESPIssueUserNOCService(presenter: self)
                            service.issueUserNOC(url: nodeGroupURL, groupId: groupId, operation: ESPMatterConstants.add, csr: finalCSRString)
                        }
                    }
                    return
                }
                self.index+=1
                self.issueUserNOC(index: self.index)
            } else {
                self.index+=1
                self.issueUserNOC(index: self.index)
            }
        } else {
            self.completion?()
        }
    }
}

@available(iOS 16.4, *)
extension ESPGetUserNOCService: ESPIssueUserNOCPresentationLogic {
    
    /// User noc received
    /// - Parameters:
    ///   - groupId: group id
    ///   - response: response
    ///   - error: error
    func userNOCReceived(groupId: String,
                         response: ESPIssueUserNOCResponse?,
                         error: Error?) {
        self.index+=1
        if let completion = self.completion {
            guard let _ = error else {
                if let response = response {
                    ESPMatterFabricDetails.shared.saveUserNOCDetails(groupId: groupId, data: response)
                }
                self.issueUserNOC(index: self.index)
                return
            }
            self.issueUserNOC(index: self.index)
        }
    }
}
#endif
