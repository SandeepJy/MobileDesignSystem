import SwiftUI

struct MDSCoachmarkTipContentView: View {
    let item: MDSCoachmarkItem
    let stepIndex: Int
    let totalSteps: Int
    let isFirst: Bool
    let isLast: Bool
    let configuration: MDSCoachmarkConfiguration
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            contentLayout
            Divider()
            navigationBar
        }
    }

    @ViewBuilder
    private var contentLayout: some View {
        switch MDSCoachmarkConstants.tipLayoutStyle {
        case .horizontal: horizontalLayout
        case .vertical:   verticalLayout
        case .textOnly:   textOnlyLayout
        }
    }

    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            if let iconName = item.iconName { iconView(systemName: iconName) }
            textContent
        }
    }

    @ViewBuilder
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let iconName = item.iconName { iconView(systemName: iconName) }
            textContent
        }
    }

    @ViewBuilder
    private var textOnlyLayout: some View { textContent }

    @ViewBuilder
    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(MDSCoachmarkConstants.titleFont)
                .foregroundColor(MDSCoachmarkConstants.titleColor)
                .fixedSize(horizontal: false, vertical: true)
            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(MDSCoachmarkConstants.descriptionFont)
                    .foregroundColor(MDSCoachmarkConstants.descriptionColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func iconView(systemName: String) -> some View {
        let color = item.iconColor ?? MDSCoachmarkConstants.defaultIconColor
        Image(systemName: systemName)
            .font(.system(size: MDSCoachmarkConstants.defaultIconSize))
            .foregroundColor(color)
            .frame(
                width: MDSCoachmarkConstants.defaultIconSize + 8,
                height: MDSCoachmarkConstants.defaultIconSize + 8
            )
    }

    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            Text("\(stepIndex + 1) of \(totalSteps)")
                .font(MDSCoachmarkConstants.stepIndicatorFont)
                .foregroundColor(MDSCoachmarkConstants.stepIndicatorColor)
            Spacer()
            if configuration.showExitButton && !isLast {
                Button(action: onSkip) {
                    Text(MDSCoachmarkConstants.exitButtonLabel)
                        .font(.subheadline)
                        .foregroundColor(MDSCoachmarkConstants.stepIndicatorColor)
                }
                .padding(.trailing, 8)
            }
            if MDSCoachmarkConstants.showBackButton && !isFirst {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.caption.bold())
                        Text(MDSCoachmarkConstants.backButtonLabel)
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(MDSCoachmarkConstants.accentColor)
                }
                .padding(.trailing, 4)
            }
            Button(action: isLast ? onFinish : onNext) {
                HStack(spacing: 4) {
                    Text(
                        isLast
                            ? MDSCoachmarkConstants.finishButtonLabel
                            : MDSCoachmarkConstants.nextButtonLabel
                    )
                    .font(.subheadline.bold())
                    if !isLast {
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }
                }
                .foregroundColor(isLast ? .white : MDSCoachmarkConstants.accentColor)
                .padding(.horizontal, isLast ? 16 : 0)
                .padding(.vertical, isLast ? 6 : 0)
                .background(
                    Group {
                        if isLast {
                            Capsule().fill(MDSCoachmarkConstants.accentColor)
                        }
                    }
                )
            }
        }
    }
}
