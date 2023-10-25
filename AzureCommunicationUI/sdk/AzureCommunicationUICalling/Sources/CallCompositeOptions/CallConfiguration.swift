//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCommon

struct CallConfiguration {
    let groupId: UUID?
    let meetingLink: String?
    let compositeCallType: CompositeCallType
    let credential: CommunicationTokenCredential
    let displayName: String?
    let diagnosticConfig: DiagnosticConfig
    let participants: [String]?
    let callKitOptions: CallCompositeCallKitOption?

    init(locator: JoinLocator,
         credential: CommunicationTokenCredential,
         displayName: String?,
         callKitOptions: CallCompositeCallKitOption? = nil) {
        switch locator {
        case let .groupCall(groupId: groupId):
            self.groupId = groupId
            self.meetingLink = nil
            self.compositeCallType = .groupCall
        case let .teamsMeeting(teamsLink: meetingLink):
            self.groupId = nil
            self.meetingLink = meetingLink
            self.compositeCallType = .teamsMeeting
        }
        self.credential = credential
        self.displayName = displayName
        self.participants = nil
        self.diagnosticConfig = DiagnosticConfig()
        self.callKitOptions = callKitOptions
    }
    init(startCallOptions: StartCallOptionsOneToNCall,
         credential: CommunicationTokenCredential,
         displayName: String?,
         callKitOptions: CallCompositeCallKitOption? = nil) {
        self.participants = startCallOptions.partipants
        self.compositeCallType = .oneToNCall
        self.credential = credential
        self.displayName = displayName
        self.groupId = nil
        self.meetingLink = nil
        self.diagnosticConfig = DiagnosticConfig()
        self.callKitOptions = callKitOptions
    }
}

enum CompositeCallType {
    case groupCall
    case teamsMeeting
    case oneToNCall
}
