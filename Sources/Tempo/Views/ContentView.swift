import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var store = TempoStore()
    @State private var isSidebarToggleHovered = false
    @State private var isInspectorToggleHovered = false
    @State private var titleBarInset: CGFloat = 52

    private let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            if !store.focusMode {
                SidebarView(store: store, compact: store.sidebarHidden)
            }

            mainContent

            if store.isPracticeWorkspacePresented,
               store.inspectorVisible,
               !store.focusMode {
                FeedbackPanel(store: store)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minWidth: 980, minHeight: 680)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.safeAreaInsets.top, initial: true) { _, newValue in
                        titleBarInset = newValue
                    }
            }
        }
        .overlay(alignment: .top) {
            practiceTitleBarOverlay
        }
        .tempoGlassWindowChrome()
        .toolbar {
            if !store.focusMode {
                ToolbarItem(placement: .navigation) {
                    sidebarToggleButton
                }
            }

            if store.isPracticeWorkspacePresented, !store.focusMode {
                ToolbarItem {
                    Spacer()
                }

                ToolbarItem(placement: .primaryAction) {
                    inspectorToggleButton
                }
            }
        }
        .animation(TempoTheme.Motion.standard, value: store.sidebarHidden)
        .animation(TempoTheme.Motion.standard, value: store.focusMode)
        .animation(TempoTheme.Motion.standard, value: store.inspectorVisible)
        .fileImporter(
            isPresented: $store.showingImporter,
            allowedContentTypes: scoreTypes,
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            store.prepareImport(url)
        }
        .sheet(item: $store.pendingImport, onDismiss: {
            if store.pendingImport != nil {
                store.cancelImport()
            }
        }) { pendingImport in
            ScoreImportDetailsView(store: store, pendingImport: pendingImport)
        }
        .sheet(isPresented: $store.showingNewFolder) {
            NewFolderView(store: store)
        }
        .sheet(isPresented: $store.showingPairing) {
            PairingView(midiName: store.midiService.activeSourceName)
        }
        .sheet(isPresented: $store.showingMIDIConnection) {
            MIDIConnectionView(midiService: store.midiService)
        }
        .sheet(isPresented: $store.showingSessionReview) {
            SessionReviewView(store: store)
        }
        .onReceive(timer) { _ in
            store.tick(interval: 0.02)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tempoToggleSidebar)) { _ in
            withAnimation(TempoTheme.Motion.standard) {
                store.sidebarHidden.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tempoToggleInspector)) { _ in
            withAnimation(TempoTheme.Motion.standard) {
                store.inspectorVisible.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tempoToggleFocus)) { _ in
            withAnimation(TempoTheme.Motion.standard) {
                store.focusMode.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tempoTogglePlayback)) { _ in
            store.playPause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tempoImportScore)) { _ in
            store.showingImporter = true
        }
    }

    private var sidebarToggleButton: some View {
        Button {
            withAnimation(TempoTheme.Motion.standard) {
                store.sidebarHidden.toggle()
            }
        } label: {
            Image(systemName: "sidebar.left")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 24)
                .background(
                    isSidebarToggleHovered ? Color.primary.opacity(0.08) : .clear,
                    in: RoundedRectangle(cornerRadius: TempoTheme.Radius.small)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isSidebarToggleHovered = $0 }
        .help(store.sidebarHidden ? "Expand Sidebar" : "Collapse Sidebar")
    }

    private var inspectorToggleButton: some View {
        Button {
            withAnimation(TempoTheme.Motion.standard) {
                store.inspectorVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.trailing")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 24)
                .background(
                    isInspectorToggleHovered ? Color.primary.opacity(0.08) : .clear,
                    in: RoundedRectangle(cornerRadius: TempoTheme.Radius.small)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isInspectorToggleHovered = $0 }
        .help(store.inspectorVisible ? "Hide Feedback" : "Show Feedback")
    }

    @ViewBuilder
    private var practiceTitleBarOverlay: some View {
        if store.isPracticeWorkspacePresented {
            PracticeTitleBarRow(
                store: store,
                sidebarWidth: sidebarWidth,
                sidebarCollapsed: store.sidebarHidden,
                inspectorWidth: TempoTheme.Layout.inspectorWidth,
                showsInspector: store.inspectorVisible,
                focusMode: store.focusMode
            )
            .frame(height: titleBarInset)
            .frame(maxWidth: .infinity)
            .padding(.top, -titleBarInset)
        }
    }

    private var sidebarWidth: CGFloat {
        store.sidebarHidden
            ? TempoTheme.Layout.sidebarCollapsed
            : TempoTheme.Layout.sidebarExpanded
    }

    private var mainContent: some View {
        Group {
            if store.isPracticeWorkspacePresented {
                PracticeWorkspaceView(store: store)
            } else {
                destinationView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tempoWorkspaceBackground)
    }

    private var scoreTypes: [UTType] {
        ["musicxml", "xml", "mxl"]
            .compactMap { UTType(filenameExtension: $0) }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch store.destination {
        case .home:
            HomeView(store: store)
        case .library:
            LibraryView(store: store)
        case .progress:
            ProgressScreen(store: store)
        }
    }
}
