import SwiftUI

// ═══════════════════════════════════════════════════════════════════
// MARK: - Environment Plumbing (compiles on every deployment target)
// ═══════════════════════════════════════════════════════════════════

struct MDSCoachmarkCoordinatorBox: @unchecked Sendable {
    let ref: AnyObject?
    static let empty = MDSCoachmarkCoordinatorBox(ref: nil)
}

struct MDSTipKitCoordinatorKey: EnvironmentKey {
    static let defaultValue = MDSCoachmarkCoordinatorBox.empty
}

struct MDSTipKitStepInfo: Sendable {
    let index: Int
    let total: Int
    let isFirst: Bool
    let isLast: Bool
    let showExitButton: Bool
}

struct MDSTipKitStepInfoKey: EnvironmentKey {
    static let defaultValue: MDSTipKitStepInfo? = nil
}

extension EnvironmentValues {
    var mdsTipKitCoordinator: MDSCoachmarkCoordinatorBox {
        get { self[MDSTipKitCoordinatorKey.self] }
        set { self[MDSTipKitCoordinatorKey.self] = newValue }
    }
    var mdsTipKitStepInfo: MDSTipKitStepInfo? {
        get { self[MDSTipKitStepInfoKey.self] }
        set { self[MDSTipKitStepInfoKey.self] = newValue }
    }
}

// ═══════════════════════════════════════════════════════════════════
// MARK: - TipKit Bootstrap (iOS 18+)
// ═══════════════════════════════════════════════════════════════════

#if canImport(TipKit)
import TipKit

@available(iOS 18.0, *)
@MainActor
public enum MDSTipKitSetup {

    private static var isConfigured = false

    /// Call once at launch. Uses an ephemeral temp-directory datastore
    /// so tip state is never persisted across launches.
    public static func configureIfNeeded() {
        guard !isConfigured else { return }
        do {
            try Tips.configure([
                .datastoreLocation(
                    .url(FileManager.default.temporaryDirectory
                            .appendingPathComponent("mds_tipkit_coachmarks"))
                )
            ])
        } catch { /* already configured by host app */ }
        isConfigured = true
    }

    /// Wipes all display / invalidation records and re-establishes the
    /// TipKit configuration so that previously invalidated tips in a
    /// `TipGroup` are eligible again on the next tour start.
    public static func resetDatastore() {
        try? Tips.resetDatastore()
        isConfigured = false
        configureIfNeeded()
    }
}
#endif
