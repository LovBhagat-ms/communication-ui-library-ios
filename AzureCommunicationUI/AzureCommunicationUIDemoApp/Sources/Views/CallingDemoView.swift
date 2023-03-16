//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI
import AzureCommunicationCommon
import AVFoundation
#if DEBUG
@testable import AzureCommunicationUICalling
#else
import AzureCommunicationUICalling
#endif
struct CallingDemoView: View {
    @State var isErrorDisplayed: Bool = false
    @State var isSettingsDisplayed: Bool = false
    @State var isStartExperienceLoading: Bool = false
    @State var errorMessage: String = ""
    @State var isShowingCallHistory: Bool = false
    @ObservedObject var envConfigSubject: EnvConfigSubject
    @ObservedObject var callingViewModel: CallingDemoViewModel

    let verticalPadding: CGFloat = 5
    let horizontalPadding: CGFloat = 10
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    let roomRoleChoices: [String] = ["Presenter", "Attendee"]
#if DEBUG
    var callingSDKWrapperMock: UITestCallingSDKWrapper?
#endif
    var body: some View {
        VStack {
            Text("UI Library - SwiftUI Sample")
            Spacer()
            acsTokenSelector
            displayNameTextField
            meetingSelector
            if envConfigSubject.selectedMeetingType == .roomCall {
                roomRoleSelector
            } else {
                roomRoleSelector.hidden()
            }
            settingButton
            showCallHistoryButton
            .alert(isPresented: $isShowingCallHistory) {
                Alert(
                    title: Text(callingViewModel.callHistoryTitle),
                    message: Text(callingViewModel.callHistoryMessage),
                    dismissButton:
                            .default(Text("Dismiss"), action: {
                                isShowingCallHistory = false
                            }))
            }
            startExperienceButton
            .alert(isPresented: $isErrorDisplayed) {
                 Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton:
                            .default(Text("Dismiss"), action: {
                        isErrorDisplayed = false
                    }))
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $isSettingsDisplayed) {
            SettingsView(envConfigSubject: envConfigSubject)
        }
    }

    var acsTokenSelector: some View {
        Group {
            Picker("Token Type", selection: $envConfigSubject.selectedAcsTokenType) {
                Text("Token URL").tag(ACSTokenType.tokenUrl)
                Text("Token").tag(ACSTokenType.token)
            }.pickerStyle(.segmented)
            switch envConfigSubject.selectedAcsTokenType {
            case .tokenUrl:
                TextField("ACS Token URL", text: $envConfigSubject.acsTokenUrl)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
            case .token:
                TextField("ACS Token", text:
                            !envConfigSubject.useExpiredToken ?
                          $envConfigSubject.acsToken : $envConfigSubject.expiredAcsToken)
                    .modifier(TextFieldClearButton(text: $envConfigSubject.acsToken))
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
    }

    var displayNameTextField: some View {
        TextField("Display Name", text: $envConfigSubject.displayName)
            .disableAutocorrection(true)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .textFieldStyle(.roundedBorder)
    }

    var meetingSelector: some View {
        Group {
            Picker("Call Type", selection: $envConfigSubject.selectedMeetingType) {
                Text("Group Call").tag(MeetingType.groupCall)
                Text("Teams Meeting").tag(MeetingType.teamsMeeting)
                Text("Room Call").tag(MeetingType.roomCall)
            }.pickerStyle(.segmented)
            switch envConfigSubject.selectedMeetingType {
            case .groupCall:
                TextField(
                    "Group Call Id",
                    text: $envConfigSubject.groupCallId)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
            case .teamsMeeting:
                TextField(
                    "Team Meeting",
                    text: $envConfigSubject.teamsMeetingLink)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
            case .roomCall:
                TextField(
                    "Room Id",
                    text: $envConfigSubject.roomId)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
    }
    var roomRoleSelector: some View {

        Section {
            Picker("Room Role Type", selection: $envConfigSubject.selectedRoomRoleType) {
                Text("Presenter").tag(RoomRoleType.presenter)
                Text("Attendee").tag(RoomRoleType.attendee)
            }.pickerStyle(.segmented)
        }
    }

    var settingButton: some View {
        Button("Settings") {
            isSettingsDisplayed = true
        }
        .buttonStyle(DemoButtonStyle())
        .accessibility(identifier: AccessibilityId.settingsButtonAccessibilityID.rawValue)
    }

    var startExperienceButton: some View {
        Button("Start Experience") {
            isStartExperienceLoading = true
            Task { @MainActor in
                if getAudioPermissionStatus() == .denied && envConfigSubject.skipSetupScreen {
                    showError(for: CallCompositeErrorCode.microphonePermissionNotGranted)
                    isStartExperienceLoading = false
                    return
                }
                await startCallComposite()
                isStartExperienceLoading = false
            }
        }
        .buttonStyle(DemoButtonStyle())
        .disabled(isStartExperienceDisabled || isStartExperienceLoading)
        .accessibility(identifier: AccessibilityId.startExperienceAccessibilityID.rawValue)
    }

    var showCallHistoryButton: some View {
        Button("Show call history") {
            isShowingCallHistory = true
        }
        .buttonStyle(DemoButtonStyle())
    }

    var isStartExperienceDisabled: Bool {
        let acsToken = envConfigSubject.useExpiredToken ? envConfigSubject.expiredAcsToken : envConfigSubject.acsToken
        if (envConfigSubject.selectedAcsTokenType == .token && acsToken.isEmpty)
            || envConfigSubject.selectedAcsTokenType == .tokenUrl && envConfigSubject.acsTokenUrl.isEmpty {
            return true
        }

        if (envConfigSubject.selectedMeetingType == .groupCall && envConfigSubject.groupCallId.isEmpty)
            || envConfigSubject.selectedMeetingType == .teamsMeeting && envConfigSubject.teamsMeetingLink.isEmpty {
            return true
        }

        return false
    }
}

extension CallingDemoView {
    func startCallComposite() async {
        let link = getMeetingLink()

        var localizationConfig: LocalizationOptions?
        let layoutDirection: LayoutDirection = envConfigSubject.isRightToLeft ? .rightToLeft : .leftToRight
        if !envConfigSubject.localeIdentifier.isEmpty {
            let locale = Locale(identifier: envConfigSubject.localeIdentifier)
            localizationConfig = LocalizationOptions(locale: locale,
                                                           layoutDirection: layoutDirection)
        } else if !envConfigSubject.locale.identifier.isEmpty {
            localizationConfig = LocalizationOptions(
                locale: envConfigSubject.locale,
                layoutDirection: layoutDirection)
        }

        let callCompositeOptions = CallCompositeOptions(
            theme: envConfigSubject.useCustomColors
            ? CustomColorTheming(envConfigSubject: envConfigSubject)
            : Theming(envConfigSubject: envConfigSubject),
            localization: localizationConfig)
        #if DEBUG
        let useMockCallingSDKHandler = envConfigSubject.useMockCallingSDKHandler
        let callComposite = useMockCallingSDKHandler ?
            CallComposite(withOptions: callCompositeOptions,
                          callingSDKWrapperProtocol: callingSDKWrapperMock)
            : CallComposite(withOptions: callCompositeOptions)
        #else
        let callComposite = CallComposite(withOptions: callCompositeOptions)
        #endif

        let onRemoteParticipantJoinedHandler: ([CommunicationIdentifier]) -> Void = { [weak callComposite] ids in
            guard let composite = callComposite else {
                return
            }
            self.onRemoteParticipantJoined(to: composite,
                                           identifiers: ids)
        }
        let onErrorHandler: (CallCompositeError) -> Void = { [weak callComposite] error in
            guard let composite = callComposite else {
                return
            }
            onError(error,
                    callComposite: composite)
        }
        callComposite.events.onRemoteParticipantJoined = onRemoteParticipantJoinedHandler
        callComposite.events.onError = onErrorHandler

        let renderDisplayName = envConfigSubject.renderedDisplayName.isEmpty ?
                                nil:envConfigSubject.renderedDisplayName
        let participantViewData = ParticipantViewData(avatar: UIImage(named: envConfigSubject.avatarImageName),
                                                      displayName: renderDisplayName)
        let roomRole = envConfigSubject.selectedRoomRoleType
        var roomRoleData: ParticipantRole?
        if envConfigSubject.selectedMeetingType == .roomCall {
            if roomRole == .presenter {
                roomRoleData = ParticipantRole.presenter
            } else if roomRole == .attendee {
                roomRoleData = ParticipantRole.attendee
            }
        }

        let setupScreenViewData = SetupScreenViewData(title: envConfigSubject.navigationTitle,
                                                          subtitle: envConfigSubject.navigationSubtitle)
        let localOptions = LocalOptions(participantViewData: participantViewData,
                                        setupScreenViewData: setupScreenViewData,
                                        cameraOnByDefault: envConfigSubject.cameraDefault,
                                        microphoneOnByDefault: envConfigSubject.micDefault,
                                        skipSetup: envConfigSubject.skipSetupScreen,
                                        roleHint: roomRoleData)
        if let credential = try? await getTokenCredential() {
            switch envConfigSubject.selectedMeetingType {
            case .groupCall:
                let uuid = UUID(uuidString: link) ?? UUID()
                if envConfigSubject.displayName.isEmpty {
                    callComposite.launch(remoteOptions: RemoteOptions(for: .groupCall(groupId: uuid),
                                                                      credential: credential),
                                         localOptions: localOptions)
                } else {
                    callComposite.launch(remoteOptions: RemoteOptions(for: .groupCall(groupId: uuid),
                                                                      credential: credential,
                                                                      displayName: envConfigSubject.displayName),
                                         localOptions: localOptions)
                }
            case .teamsMeeting:
                if envConfigSubject.displayName.isEmpty {
                    callComposite.launch(remoteOptions: RemoteOptions(for: .teamsMeeting(teamsLink: link),
                                                                      credential: credential),
                                         localOptions: localOptions)
                } else {
                    callComposite.launch(remoteOptions: RemoteOptions(for: .teamsMeeting(teamsLink: link),
                                                                      credential: credential,
                                                                      displayName: envConfigSubject.displayName),
                                         localOptions: localOptions)
                }
            case .roomCall:
                if envConfigSubject.displayName.isEmpty {
                    callComposite.launch(remoteOptions:
                                            RemoteOptions(for: .roomCall(roomId: link),
                                                          credential: credential),
                                         localOptions: localOptions)
                } else {
                    callComposite.launch(
                        remoteOptions: RemoteOptions(for:
                                .roomCall(roomId: link),
                                                     credential: credential,
                                                     displayName: envConfigSubject.displayName),
                        localOptions: localOptions)
                }
            }
        } else {
            showError(for: DemoError.invalidToken.getErrorCode())
            return
        }
    }

    private func getTokenCredential() async throws -> CommunicationTokenCredential {
        switch envConfigSubject.selectedAcsTokenType {
        case .token:
            let acsToken = envConfigSubject.useExpiredToken ?
                           envConfigSubject.expiredAcsToken : envConfigSubject.acsToken
            if let communicationTokenCredential = try? CommunicationTokenCredential(token: acsToken) {
                return communicationTokenCredential
            } else {
                throw DemoError.invalidToken
            }
        case .tokenUrl:
            if let url = URL(string: envConfigSubject.acsTokenUrl) {
                let tokenRefresher = AuthenticationHelper.getCommunicationToken(tokenUrl: url,
                                                                                aadToken: envConfigSubject.aadToken)
                let initialToken = await AuthenticationHelper.fetchInitialToken(with: tokenRefresher)
                let communicationTokenRefreshOptions = CommunicationTokenRefreshOptions(initialToken: initialToken,
                                                                                        refreshProactively: true,
                                                                                        tokenRefresher: tokenRefresher)
                if let credential = try? CommunicationTokenCredential(withOptions: communicationTokenRefreshOptions) {
                    return credential
                }
            }
            throw DemoError.invalidToken
        }
    }

    private func getMeetingLink() -> String {
        switch envConfigSubject.selectedMeetingType {
        case .groupCall:
            return envConfigSubject.groupCallId
        case .teamsMeeting:
            return envConfigSubject.teamsMeetingLink
        case .roomCall:
            return envConfigSubject.roomId
        }
    }

    private func showError(for errorCode: String) {
        switch errorCode {
        case CallCompositeErrorCode.tokenExpired:
            errorMessage = "Token is invalid"
        case CallCompositeErrorCode.microphonePermissionNotGranted:
            errorMessage = "Microphone Permission is denied"
        case CallCompositeErrorCode.internetDisconnected:
            errorMessage = "Internet error"
        default:
            errorMessage = "Unknown error"
        }
        isErrorDisplayed = true
    }

    private func getAudioPermissionStatus() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }

    private func onError(_ error: CallCompositeError, callComposite: CallComposite) {
        print("::::CallingDemoView::getEventsHandler::onError \(error)")
        print("::::CallingDemoView error.code \(error.code)")
        callingViewModel.callHistory.last?.callIds.forEach { print("::::CallingDemoView call id \($0)") }
        showError(for: error.code)
    }

    private func onRemoteParticipantJoined(to callComposite: CallComposite, identifiers: [CommunicationIdentifier]) {
        print("::::CallingDemoView::getEventsHandler::onRemoteParticipantJoined \(identifiers)")
        guard envConfigSubject.useCustomRemoteParticipantViewData else {
            return
        }

        RemoteParticipantAvatarHelper.onRemoteParticipantJoined(to: callComposite,
                                                                identifiers: identifiers)
    }
}
