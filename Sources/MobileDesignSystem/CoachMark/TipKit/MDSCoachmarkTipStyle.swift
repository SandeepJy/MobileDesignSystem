#if canImport(TipKit)
import SwiftUI
import TipKit

/// Renders a coachmark tip using the same layout as the legacy overlay,
/// so both code paths look identical.
@available(iOS 18.0, *)
struct MDSCoachmarkTipViewStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        MDSCoachmarkTipStyleBody(configuration: configuration)
    }
}

@available(iOS 18.0, *)
private struct MDSCoachmarkTipStyleBody: View {

    let configuration: TipViewStyleConfiguration

    private var coordinator: MDSTipKitTourCoordinator? {
        MDSTipKitTourCoordinator.current
    }

    private var stepInfo: MDSTipKitStepInfo {
        let prefix = "__stepinfo__:"
        guard let infoAction = configuration.actions.first(where: { $0.id.hasPrefix(prefix) }) else {
            return MDSTipKitStepInfo(index: 0, total: 1, isFirst: true, isLast: true, showExitButton: true)
        }

        let payload = String(infoAction.id.dropFirst(prefix.count))
        let components = payload.split(separator: "|")
        guard components.count == 4,
              let index = Int(components[0]),
              let total = Int(components[1]) else {
            return MDSTipKitStepInfo(index: 0, total: 1, isFirst: true, isLast: true, showExitButton: true)
        }

        let isFirst = components[2] == "1"
        let isLast = components[3] == "1"
        let showExit = coordinator?.configuration.showExitButton ?? true

        return MDSTipKitStepInfo(
            index: index,
            total: total,
            isFirst: isFirst,
            isLast: isLast,
            showExitButton: showExit
        )
    }

    private var visibleActions: [Tip.Action] {
        configuration.actions.filter { !$0.id.hasPrefix("__stepinfo__:") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            contentArea
            Divider()
            navigationBar
        }
        .padding(.horizontal, MDSCoachmarkConstants.tipHorizontalPadding)
        .padding(.vertical, MDSCoachmarkConstants.tipVerticalPadding)
    }

    // MARK: Content

    @ViewBuilder
    private var contentArea: some View {
        switch MDSCoachmarkConstants.tipLayoutStyle {
        case .horizontal: horizontalLayout
        case .vertical:   verticalLayout
        case .textOnly:   textOnlyLayout
        }
    }

    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            tipImage
            textContent
        }
    }

    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            tipImage
            textContent
        }
    }

    private var textOnlyLayout: some View { textContent }

    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.title
                .font(MDSCoachmarkConstants.titleFont)
                .foregroundColor(MDSCoachmarkConstants.titleColor)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(MDSCoachmarkAccessibility.title)

            if let message = configuration.message {
                message
                    .font(MDSCoachmarkConstants.descriptionFont)
                    .foregroundColor(MDSCoachmarkConstants.descriptionColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(MDSCoachmarkAccessibility.description)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var tipImage: some View {
        if let image = configuration.image {
            image
                .font(.system(size: MDSCoachmarkConstants.defaultIconSize))
                .foregroundColor(MDSCoachmarkConstants.defaultIconColor)
                .frame(
                    width: MDSCoachmarkConstants.defaultIconSize + 8,
                    height: MDSCoachmarkConstants.defaultIconSize + 8
                )
        }
    }

    // MARK: Navigation bar

    @ViewBuilder
    private var navigationBar: some View {
        let info = stepInfo

        HStack {
            Text("\(info.index + 1) of \(info.total)")
                .font(MDSCoachmarkConstants.stepIndicatorFont)
                .foregroundColor(MDSCoachmarkConstants.stepIndicatorColor)
                .accessibilityIdentifier(MDSCoachmarkAccessibility.stepIndicator)

            Spacer()

            ForEach(visibleActions) { action in
                actionButton(action, info: info)
            }
        }
    }

    @ViewBuilder
    private func actionButton(
        _ action: Tip.Action,
        info: MDSTipKitStepInfo
    ) -> some View {
        switch action.id {
        case "skip":
            if info.showExitButton && !info.isLast {
                Button {
                    coordinator?.skip()
                } label: {
                    Text(MDSCoachmarkConstants.exitButtonLabel)
                        .font(.subheadline)
                        .foregroundColor(MDSCoachmarkConstants.stepIndicatorColor)
                }
                .accessibilityIdentifier(MDSCoachmarkAccessibility.skipButton)
                .padding(.trailing, 8)
            }

        case "next":
            Button {
                coordinator?.next()
            } label: {
                HStack(spacing: 4) {
                    Text(MDSCoachmarkConstants.nextButtonLabel)
                        .font(.subheadline.bold())
                    Image(systemName: "chevron.right").font(.caption.bold())
                }
                .foregroundColor(MDSCoachmarkConstants.accentColor)
            }
            .accessibilityIdentifier(MDSCoachmarkAccessibility.nextButton)

        case "done":
            Button {
                coordinator?.finish()
            } label: {
                Text(MDSCoachmarkConstants.finishButtonLabel)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(MDSCoachmarkConstants.accentColor))
            }
            .accessibilityIdentifier(MDSCoachmarkAccessibility.finishButton)

        default:
            EmptyView()
        }
    }
}
#endif
