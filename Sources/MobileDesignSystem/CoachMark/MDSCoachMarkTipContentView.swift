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

    /// Binding the overlay uses to pull VoiceOver focus onto this tooltip's
    /// content section after a Next/Previous transition. The overlay owns the
    /// `@AccessibilityFocusState` and flips it to `true` once the new tooltip
    /// has been mounted; this binding ties that state to the correct leaf
    /// element so VoiceOver lands directly on the readable content rather than
    /// hunting through the view tree.
    var contentAccessibilityFocus: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            contentLayout
                // Collapse icon + title + description into a single accessibility
                // element. Without this, VoiceOver reads each piece separately
                // and the focus request from the overlay could land on the icon
                // (which has no useful label) instead of the text.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(contentAccessibilityLabel)
                // Read the content before the navigation bar when swiping.
                .accessibilitySortPriority(10)
                // This is the element the overlay drives focus to.
                .accessibilityFocused(contentAccessibilityFocus)
            Divider()
                .accessibilityHidden(true) // Purely decorative.
            navigationBar
        }
    }

    // MARK: - Accessibility

    /// The spoken description of this step. Leads with the step position so the
    /// user immediately knows where they are in the tour, then the title, then
    /// the optional description — mirroring how a sighted user scans the tip.
    ///
    /// The visual "N of M" indicator in the navigation bar is hidden from
    /// VoiceOver to avoid announcing the same information twice.
    private var contentAccessibilityLabel: String {
        var parts: [String] = ["Step \(stepIndex + 1) of \(totalSteps)", item.title]
        if let desc = item.description, !desc.isEmpty {
            parts.append(desc)
        }
        return parts.joined(separator: ". ")
    }

    // MARK: - Layout

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
            // The icon is decorative — the content label already conveys the
            // meaning. Without this, VoiceOver reads the SF Symbol name
            // ("gear", "star.fill", etc.) which is noise.
            .accessibilityHidden(true)
    }

    // MARK: - Navigation Bar

    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            Text("\(stepIndex + 1) of \(totalSteps)")
                .font(MDSCoachmarkConstants.stepIndicatorFont)
                .foregroundColor(MDSCoachmarkConstants.stepIndicatorColor)
                // Step position is already announced as the first part of
                // `contentAccessibilityLabel`. Hiding this avoids a duplicate
                // "1 of 5" announcement when the user swipes past the content.
                .accessibilityHidden(true)

            Spacer()

            if configuration.showExitButton && !isLast {
                Button(action: onSkip) {
                    Text(MDSCoachmarkConstants.exitButtonLabel)
                        .font(.subheadline)
                        .foregroundColor(MDSCoachmarkConstants.stepIndicatorColor)
                }
                .accessibilityLabel(MDSCoachmarkConstants.exitButtonLabel)
                .accessibilityHint("Exits the tour")
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
                // "Previous step" disambiguates this button from the navigation
                // bar's own Back button — the very element we're trying to stop
                // VoiceOver from jumping to.
                .accessibilityLabel("Previous step")
                .accessibilityHint("Goes to step \(stepIndex) of \(totalSteps)")
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
            .accessibilityLabel(
                isLast
                    ? MDSCoachmarkConstants.finishButtonLabel
                    : "Next step"
            )
            .accessibilityHint(
                isLast
                    ? "Completes the tour"
                    : "Goes to step \(stepIndex + 2) of \(totalSteps)"
            )
        }
    }
}
