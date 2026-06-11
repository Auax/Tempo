import SwiftUI

struct PracticeTitleBarRow: View {
    @Bindable var store: TempoStore
    let sidebarWidth: CGFloat
    let sidebarCollapsed: Bool
    let inspectorWidth: CGFloat
    let showsInspector: Bool
    let focusMode: Bool

    private let collapsedToggleClearance: CGFloat = 40

    var body: some View {
        HStack(spacing: 0) {
            if !focusMode {
                Color.clear
                    .frame(
                        width: sidebarWidth
                            + (sidebarCollapsed ? collapsedToggleClearance : 0)
                    )
                    .allowsHitTesting(false)
            }

            PracticeContentToolbar(store: store)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !focusMode {
                Color.clear
                    .frame(
                        width: showsInspector
                            ? inspectorWidth
                            : collapsedToggleClearance
                    )
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Practice Title Bar") {
    PracticeTitleBarRow(
        store: PreviewFixtures.store(practicing: true),
        sidebarWidth: TempoTheme.Layout.sidebarExpanded,
        sidebarCollapsed: false,
        inspectorWidth: TempoTheme.Layout.inspectorWidth,
        showsInspector: true,
        focusMode: false
    )
    .frame(width: 1_360, height: 52)
}
#endif
