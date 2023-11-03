//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI
import Foundation
import AzureCommunicationCommon
import AVFoundation
import CallKit

// swiftlint:disable line_length
#if DEBUG
@testable import AzureCommunicationUICalling
#else
import AzureCommunicationUICalling
#endif
struct CallingDemoView: View {
    @State var isAlertDisplayed: Bool = false
    @State var isSettingsDisplayed: Bool = false
    @State var isStartExperienceLoading: Bool = false
    @State var isPushNotificationAvailable: Bool = false
    @State var exitCompositeExecuted: Bool = false
    @State var alertTitle: String = ""
    @State var alertMessage: String = ""
    @State var callState: String = ""
    @ObservedObject var envConfigSubject: EnvConfigSubject
    @ObservedObject var callingViewModel: CallingDemoViewModel

    let verticalPadding: CGFloat = 5
    let horizontalPadding: CGFloat = 10
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
            Group {
                registerButton
                settingButton
                showCallHistoryButton
                startExperienceButton
                Text(callState)
            }
            Spacer()
        }
        .padding()
        .alert(isPresented: $isAlertDisplayed) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton:
                        .default(Text("Dismiss"), action: {
                            isAlertDisplayed = false
                }))
        }
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
                Text("1:N Call").tag(MeetingType.oneToNCall)
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
            case .oneToNCall:
                TextField(
                    "One To N Calling",
                    text: $envConfigSubject.participantIds)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
    }

    var settingButton: some View {
        Button("Settings") {
            isSettingsDisplayed = true
//            envConfigSubject.acsToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjVFODQ4MjE0Qzc3MDczQUU1QzJCREU1Q0NENTQ0ODlEREYyQzRDODQiLCJ4NXQiOiJYb1NDRk1kd2M2NWNLOTVjelZSSW5kOHNUSVEiLCJ0eXAiOiJKV1QifQ.eyJza3lwZWlkIjoiYWNzOmI2YWFkYTFmLTBiMWQtNDdhYy04NjZmLTkxYWFlMDBhMWQwMV8wMDAwMDAxYy0yYjkxLTYyZjItZTNjNy01OTNhMGQwMDRjODAiLCJzY3AiOjE3OTIsImNzaSI6IjE2OTg4NTU2MzIiLCJleHAiOjE2OTg5NDIwMzIsInJnbiI6ImFtZXIiLCJhY3NTY29wZSI6ImNoYXQsdm9pcCIsInJlc291cmNlSWQiOiJiNmFhZGExZi0wYjFkLTQ3YWMtODY2Zi05MWFhZTAwYTFkMDEiLCJyZXNvdXJjZUxvY2F0aW9uIjoidW5pdGVkc3RhdGVzIiwiaWF0IjoxNjk4ODU1NjMyfQ.ctUSdM9kZaYUca9DbYfs_f8Cj6vNHeZYxFJZtj1KIqfPquwEvVPFz7WGPgAqhR-BUn5BwFL2PKncLycuejapPal793eJlyZ6Zg9rsJb2bA1nKG8IYiVrWgwCzsprOPCbEpaeY05y9sivKhmB0QNAX0aXzldpgZBkX8FXDVcU_ATw4H4FW0Qu85SPktjHVdzbGkeUj3mIbaxbXptNA7I8RDqnS52HOxgbklaDMzjS9OFaQ5P3r6WxnvUXCzEHochfhC6VzCFRRtNl1qAXuPcztquLn236i922PEBFDYUnUX2sldCNBJHj4xf0irz6eeveqaRiBOqpahxdZp9WjzvD5w"
//            envConfigSubject.participantIds = "8:acs:b6aada1f-0b1d-47ac-866f-91aae00a1d01_0000001c-2b91-b9f0-ec8d-084822004b56"
            envConfigSubject.acsToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjVFODQ4MjE0Qzc3MDczQUU1QzJCREU1Q0NENTQ0ODlEREYyQzRDODQiLCJ4NXQiOiJYb1NDRk1kd2M2NWNLOTVjelZSSW5kOHNUSVEiLCJ0eXAiOiJKV1QifQ.eyJza3lwZWlkIjoiYWNzOmI2YWFkYTFmLTBiMWQtNDdhYy04NjZmLTkxYWFlMDBhMWQwMV8wMDAwMDAxYy0zNDNmLTM5ODgtMGQ4Yi0wODQ4MjIwMDVmODAiLCJzY3AiOjE3OTIsImNzaSI6IjE2OTkwMDEyNDMiLCJleHAiOjE2OTkwODc2NDMsInJnbiI6ImFtZXIiLCJhY3NTY29wZSI6InZvaXAiLCJyZXNvdXJjZUlkIjoiYjZhYWRhMWYtMGIxZC00N2FjLTg2NmYtOTFhYWUwMGExZDAxIiwicmVzb3VyY2VMb2NhdGlvbiI6InVuaXRlZHN0YXRlcyIsImlhdCI6MTY5OTAwMTI0M30.HaTBXTIzkgcBaj2J-IeZzlMTeMaSl72ffm63IR_ka_ZLeOU4YcrzhcQEN9Fbr9qG-Wd9OrOF-w0F3WnKbg-h1AcvgoxETUwa-4IpTpFdAVoasqIN9YRRrphLvyypAl1Uzl0ZdmmSvBa14q0vxLcGRF0AeuxSasIJ6bW-ncawhhAYH1pxKuGbULPaJuTqHcna1_v_XzB45NXgl01HOFSqW8iJDOfHwR1cPntHjFw43Xk2mzByXIya2RCvF8zQhWjYHumaXfQi4Mmvq6WuIpwI7qj9bATruyBy1o6MO86LtAIsszPfsf1_k43WVT6gYXI3ONWbBdVsuwWzn52uZg2LwA"
            envConfigSubject.participantIds = "8:acs:b6aada1f-0b1d-47ac-866f-91aae00a1d01_0000001c-3431-178c-e3c7-593a0d0050e2"
        }
        .buttonStyle(DemoButtonStyle())
        .accessibility(identifier: AccessibilityId.settingsButtonAccessibilityID.rawValue)
    }
    var registerButton: some View {
        Button("Register Voip Notification") {
            self.registerForNotification()
        }
        .disabled(isStartExperienceDisabled)
        .buttonStyle(DemoButtonStyle())
        .accessibility(identifier: AccessibilityId.registerButtonAccessibilityID.rawValue)
    }
    var handleNotificationButton: some View {
        Button("Handler push notification") {
            self.registerForNotification()
        }
        .disabled(isStartExperienceDisabled)
        .buttonStyle(DemoButtonStyle())
        .accessibility(identifier: AccessibilityId.registerButtonAccessibilityID.rawValue)
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
            alertTitle = callingViewModel.callHistoryTitle
            alertMessage = callingViewModel.callHistoryMessage
            isAlertDisplayed = true
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
    fileprivate func relaunchComposite() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
    }
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

        let setupViewOrientation = envConfigSubject.setupViewOrientation
        let callingViewOrientation = envConfigSubject.callingViewOrientation
        let callCompositeOptions = CallCompositeOptions(
            theme: envConfigSubject.useCustomColors
            ? CustomColorTheming(envConfigSubject: envConfigSubject)
            : Theming(envConfigSubject: envConfigSubject),
            localization: localizationConfig,
            setupScreenOrientation: setupViewOrientation,
            callingScreenOrientation: callingViewOrientation)
        #if DEBUG
        let useMockCallingSDKHandler = envConfigSubject.useMockCallingSDKHandler
        CallCompositeHandler.shared.callComposite = useMockCallingSDKHandler ?
                CallComposite(withOptions: callCompositeOptions,
                              callingSDKWrapperProtocol: callingSDKWrapperMock)
                : CallComposite(withOptions: callCompositeOptions)
        #else
        CallCompositeHandler.shared.callComposite = CallComposite(withOptions: callCompositeOptions)
        #endif
        guard let callComposite = CallCompositeHandler.shared.callComposite else {
            return
        }
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
        let onCallStateChangedHandler: (CallState) -> Void = { [weak callComposite] callStateEvent in
            guard let composite = callComposite else {
                return
            }
            onCallStateChanged(callStateEvent,
                    callComposite: composite)
        }
        let onDismissedHandler: (CallCompositeDismissed) -> Void = { [] _ in
            if envConfigSubject.useRelaunchOnDismissedToggle && exitCompositeExecuted {
                relaunchComposite()
            }
            print("Call State ::::onDismissedHandler ")
        }
        exitCompositeExecuted = false
        if !envConfigSubject.exitCompositeAfterDuration.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() +
                                          Float64(envConfigSubject.exitCompositeAfterDuration)!
            ) { [weak callComposite] in
                exitCompositeExecuted = true
                callComposite?.dismiss()
            }
        }
        callComposite.events.onRemoteParticipantJoined = onRemoteParticipantJoinedHandler
        callComposite.events.onError = onErrorHandler
        callComposite.events.onCallStateChanged = onCallStateChangedHandler
        callComposite.events.onDismissed = onDismissedHandler

        let renderDisplayName = envConfigSubject.renderedDisplayName.isEmpty ?
                                nil:envConfigSubject.renderedDisplayName
        let participantViewData = ParticipantViewData(avatar: UIImage(named: envConfigSubject.avatarImageName),
                                                      displayName: renderDisplayName)
        let setupScreenViewData = SetupScreenViewData(title: envConfigSubject.navigationTitle,
                                                          subtitle: envConfigSubject.navigationSubtitle)
        let localOptions = LocalOptions(participantViewData: participantViewData,
                                        setupScreenViewData: setupScreenViewData,
                                        cameraOn: envConfigSubject.cameraOn,
                                        microphoneOn: envConfigSubject.microphoneOn,
                                        skipSetupScreen: envConfigSubject.skipSetupScreen)

        let cxHandle = CXHandle(type: .generic, value: link)
        let cxProvider = CallCompositeCallKitOption.getDefaultCXProviderConfiguration()
        var remoteInfoDisplayName = envConfigSubject.callkitRemoteInfo
        if remoteInfoDisplayName.isEmpty {
            remoteInfoDisplayName = "ACS \(envConfigSubject.selectedMeetingType)"
        }
        let callKitRemoteInfo = CallCompositeCallKitRemoteInfo(displayName: remoteInfoDisplayName,
                                                               cxHandle: cxHandle)
        let isCallHoldSupported = $envConfigSubject.enableRemoteHold.wrappedValue
        let callKitOptions = CallCompositeCallKitOption(cxProvideConfig: cxProvider,
                                                       isCallHoldSupported: isCallHoldSupported,
                                                       remoteInfo: $envConfigSubject.enableRemoteInfo.wrappedValue
                                                        ? callKitRemoteInfo : nil)
        if let credential = try? await getTokenCredential() {
            switch envConfigSubject.selectedMeetingType {
            case .groupCall:
                let uuid = UUID(uuidString: link) ?? UUID()
                let displayName = envConfigSubject.displayName.isEmpty ? nil : envConfigSubject.displayName

                let remoteOptions = RemoteOptions(for: .groupCall(groupId: uuid),
                                                  credential: credential,
                                                  displayName: displayName,
                                                  callKitOptions: $envConfigSubject.enableCallKit.wrappedValue
                                                  ? callKitOptions : nil)

                callComposite.launch(remoteOptions: remoteOptions, localOptions: localOptions)

            case .teamsMeeting:
                let remoteOptions = RemoteOptions(for: .teamsMeeting(teamsLink: link),
                                                  credential: credential,
                                                  displayName: envConfigSubject.displayName.isEmpty
                                                  ? nil : envConfigSubject.displayName,
                                                  callKitOptions: $envConfigSubject.enableCallKit.wrappedValue
                                                  ? callKitOptions : nil)

                callComposite.launch(remoteOptions: remoteOptions, localOptions: localOptions)
            case .oneToNCall:
                let localOptionsForOneToN = LocalOptions(participantViewData: participantViewData,
                                                setupScreenViewData: setupScreenViewData,
                                                cameraOn: envConfigSubject.cameraOn,
                                                microphoneOn: envConfigSubject.microphoneOn,
                                                skipSetupScreen: true)
                let ids: [String] = link.split(separator: ",").map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                let startCallOptions = StartCallOptionsOneToNCall(participants: ids)
                let remoteOptions = RemoteOptions(for: startCallOptions,
                                                  credential: credential,
                                                  callKitOptions: $envConfigSubject.enableCallKit.wrappedValue
                                                  ? callKitOptions : nil)
                callComposite.launch(remoteOptions: remoteOptions,
                                     localOptions: localOptionsForOneToN)
            }
        } else {
            showError(for: DemoError.invalidToken.getErrorCode())
            return
        }
    }
    func registerForNotification() {
        guard let deviceToken = CallCompositeHandler.shared.deviceToken,
              let callComposite = CallCompositeHandler.shared.callComposite else { return }
        asyncBridgeForTokenCredential { (result) in
            switch result {
            case .success(let credential):
                let notificationOptions = PushNotificationOptions(deviceToken: deviceToken, credential: credential)
                callComposite.registerPushNotification(notificationOptions: notificationOptions)
            case .failure(let error):
                print("::::CallingDemoView::credentials::error \(error)")
            }
        }
    }
    func handlePushNotification() {
    }

    func asyncBridgeForTokenCredential(completion: @escaping (Result<CommunicationTokenCredential, Error>) -> Void) {
        Task {
            do {
                let credential = try await getTokenCredential()
                completion(.success(credential))
            } catch {
                completion(.failure(error))
            }
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
        case .oneToNCall:
            return envConfigSubject.participantIds
        }
    }

    private func showError(for errorCode: String) {
        switch errorCode {
        case CallCompositeErrorCode.tokenExpired:
            alertMessage = "Token is invalid"
        case CallCompositeErrorCode.microphonePermissionNotGranted:
            alertMessage = "Microphone Permission is denied"
        case CallCompositeErrorCode.networkConnectionNotAvailable:
            alertMessage = "Internet error"
        default:
            alertMessage = "Unknown error"
        }
        alertTitle = "Error"
        isAlertDisplayed = true
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

    private func onCallStateChanged(_ callState: CallState, callComposite: CallComposite) {
        print("::::CallingDemoView::getEventsHandler::onCallStateChanged \(callState.requestString)")
        self.callState = callState.requestString
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
