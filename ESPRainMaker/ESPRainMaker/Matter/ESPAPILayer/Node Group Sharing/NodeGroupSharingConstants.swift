// Copyright 2026 Espressif Systems
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
//  NodeGroupSharingConstants.swift
//  ESPRainmaker
//

struct NodeGroupSharingConstants {
    // Feature UI/message constants
    static let titleGroupSharing = "Group Sharing"
    static let titleGroupDetails = "Group Details"
    static let titleGroupInfo = "Group Info"
    static let titleSharedWith = "Shared With"
    static let titleSharedBy = "Shared by"
    static let titleAddMember = "Add Member"
    static let usernamePlaceholder = "Username"
    static let unknownUser = "Unknown"
    static let statusPending = "pending"
    
    static let sharingGroupMsg = "Sharing group..."
    static let fetchingSharingDetailsMsg = "Fetching sharing details..."
    static let fetchingSharingRequestsMsg = "Fetching sharing requests..."
    static let acceptingRequestMsg = "Accepting request..."
    static let decliningRequestMsg = "Declining request..."
    static let revokingRequestMsg = "Revoking request..."
    static let cancellingRequestMsg = "Cancelling request..."
    static let groupShareFailedMsg = "Failed to share group."
    static let cancelRequestFailedMsg = "Failed to cancel request."
    static let revokeRequestFailedMsg = "Failed to revoke request."
    static let requestAcceptFailedMsg = "Failed to accept request."
    static let requestDeclinedMsg = "Request declined successfully."
    
    static let cancelRequestTitle = "Cancel Request"
    static let revokeRequestTitle = "Revoke Request"
    static let revokeGroupSharingAccessConfirmationMsg = "Do you want to revoke group sharing access?"
    static let cancelGroupSharingRequestConfirmationMsg = "Do you want to cancel group sharing request?"
    static let expiresToday = "Expires today"
    static func expiresInDays(_ days: Int) -> String {
        return "Expires in \(days) days"
    }
}
