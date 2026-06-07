import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var store = TempoStore()

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            if !store.focusMode {
                SidebarView(store: store)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Group {
                if store.isPracticeWorkspacePresented {
                    PracticeWorkspaceView(store: store)
                } else {
                    destinationView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if store.isPracticeWorkspacePresented,
               store.inspectorVisible,
               !store.focusMode {
                FeedbackPanel(store: store)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minWidth: 980, minHeight: 680)
        .animation(TempoTheme.Motion.standard, value: store.focusMode)
        .animation(TempoTheme.Motion.standard, value: store.inspectorVisible)
        .fileImporter(
            isPresented: $store.showingImporter,
            allowedContentTypes: scoreTypes,
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            store.importFiles(urls)
        }
        .sheet(isPresented: $store.showingPairing) {
            PairingView(midiName: store.midiService.activeSourceName)
        }
        .sheet(isPresented: $store.showingSessionReview) {
            SessionReviewView(store: store)
        }
        .onReceive(timer) { _ in
            store.tick()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tempoToggleSidebar)) { _ in
            withAnimation(TempoTheme.Motion.standard) {
                store.sidebarCollapsed.toggle()
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

    private var scoreTypes: [UTType] {
        ["musicxml", "xml", "mxl"]
            .compactMap { UTType(filenameExtension: $0) }
    }

    @ViewBuilder
    private var destinationView: some View {
        switch store.destination {
        case .home:
            HomeView(store: store)
        case .library, .recent, .favorites:
            LibraryView(store: store)
        case .progress:
            ProgressScreen(store: store)
        }
    }
}
