//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import SwiftUI

struct ContainerView: View {

    @ObservedObject var router: NavigationRouter

    let logger: Logger
    let viewFactory: CompositeViewFactoryProtocol
    let setupViewDefaultOrientation: UIInterfaceOrientationMask =
    UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .allButUpsideDown
    let setupViewOrientationMask: UIInterfaceOrientationMask?
    let callingViewOrientationMask: UIInterfaceOrientationMask?
    let isRightToLeft: Bool

    var body: some View {
        Group {
            switch router.currentView {
            case .setupView:
                setupView.supportedOrientations(setupViewOrientationMask ?? setupViewDefaultOrientation)
                    .accessibilityElement(children: .contain)
                    .accessibilityAddTraits(.isModal)
            case .callingView:
                callingView.proximitySensorEnabled(true)
                    .supportedOrientations(callingViewOrientationMask ?? .allButUpsideDown)
                    .accessibilityElement(children: .contain)
                    .accessibilityAddTraits(.isModal)
            }
        }
        .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
    }
    var setupView: SetupView {
        logger.debug("Displaying view: setupView")
        return viewFactory.makeSetupView()
    }

    var callingView: CallingView {
        logger.debug("Displaying view: callingView")
        return viewFactory.makeCallingView()
    }
}
