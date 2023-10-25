//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
import AzureCommunicationCommon

// CallComposite Start Call for 1:N Calling
public struct CallCompositeStartCallOptions {
    public var partipants: [String]
}

/// CallComposite Locator for locating call destination
public enum JoinLocator {
    /// Group Call with UUID groupId
    case groupCall(groupId: UUID)
    /// Teams Meeting with string teamsLink URI
    case teamsMeeting(teamsLink: String)
}

/// Object for remote options for Call Composite
public struct RemoteOptions {
    /// The unique identifier for the group conversation.
    public var locator: JoinLocator?
    /// 1:N Start Call Object
    public var startCall: CallCompositeStartCallOptions?

    /// The token credential used for communication service authentication.
    public let credential: CommunicationTokenCredential

    /// The display name of the local participant when joining the call.
    /// The limit for string length is 256.
    public let displayName: String?

    /// CallKit options
    public let callKitOptions: CallCompositeCallKitOption?

    /// Create an instance of a RemoteOptions with options.
    /// - Parameters:
    ///   - locator: The JoinLocator type with unique identifier for joining a specific call.
    ///   - credential: The credential used for Azure Communication Service authentication.
    ///   - displayName: The display name of the local participant for the call. The limit for string length is 256.
    ///   - callKitOptions: CallKit options.
    public init(for locator: JoinLocator,
                credential: CommunicationTokenCredential,
                displayName: String? = nil,
                callKitOptions: CallCompositeCallKitOption? = nil) {
        self.locator = locator
        self.credential = credential
        self.displayName = displayName
        self.callKitOptions = callKitOptions
    }
    public init(for startCall: CallCompositeStartCallOptions,
                credential: CommunicationTokenCredential,
                displayName: String? = nil) {
        self.startCall = startCall
        self.credential = credential
        self.displayName = displayName
    }
}
