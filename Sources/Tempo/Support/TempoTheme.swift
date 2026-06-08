import SwiftUI
import AppKit

struct TempoGlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct TempoWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configure(windowFor: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(windowFor: nsView)
        }
    }

    private func configure(windowFor view: NSView) {
        guard let window = view.window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.toolbarStyle = .unifiedCompact
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
        window.backgroundColor = .clear
        window.isOpaque = false
    }
}

enum TempoTheme {
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 8
        static let control: CGFloat = 9
        static let medium: CGFloat = 12
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
    }

    enum Layout {
        static let controlHeight: CGFloat = 30
        static let sidebarExpanded: CGFloat = 270
        static let sidebarItemHeight: CGFloat = 44
        static let sidebarItemIconWidth: CGFloat = 24
        static let sidebarItemInnerPadding: CGFloat = 12
        static let sidebarItemSpacing: CGFloat = 6
        static let sidebarHorizontalPadding: CGFloat = 18
        static let sidebarTopPadding: CGFloat = 12
        static var sidebarCollapsed: CGFloat {
            sidebarHorizontalPadding * 2
                + sidebarItemInnerPadding * 2
                + sidebarItemIconWidth
        }
        static let inspectorWidth: CGFloat = 286
        static let topBarHeight: CGFloat = 64
        static let transportHeight: CGFloat = 66
        static let keyboardHeight: CGFloat = 148
        static let libraryFilterWidth: CGFloat = 220
        static let librarySearchMaxWidth: CGFloat = 410
        static let librarySortPickerWidth: CGFloat = 200
        static let libraryScoreCardMin: CGFloat = 220
        static let libraryScoreCardMax: CGFloat = 270
        static let libraryBrowseCardMin: CGFloat = 220
    }

    enum Motion {
        static let quick = Animation.easeOut(duration: 0.18)
        static let standard = Animation.spring(duration: 0.3, bounce: 0.08)
    }
}

extension Color {
    static let tempoBlue = Color(red: 0.17, green: 0.49, blue: 1)
    static let tempoBlueSoft = Color(red: 0.58, green: 0.43, blue: 1)
    static let tempoGreen = Color(red: 0.29, green: 0.76, blue: 0.38)
    static let tempoRed = Color(red: 0.95, green: 0.29, blue: 0.32)
    static let tempoOrange = Color(red: 0.96, green: 0.64, blue: 0.18)
    static let tempoRightHand = Color(red: 0.47, green: 0.27, blue: 0.96)
    static let tempoLeftHand = Color(red: 0.04, green: 0.66, blue: 0.76)
    static let tempoScorePaper = Color(nsColor: .white)
    static let tempoPanel = Color(
        light: NSColor(calibratedWhite: 0.97, alpha: 0.82),
        dark: NSColor(calibratedRed: 0.065, green: 0.075, blue: 0.09, alpha: 0.78)
    )
    static let tempoControlSurface = Color(
        light: NSColor(calibratedWhite: 1.0, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.14, alpha: 1.0)
    )
    static let tempoControlBorder = Color(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.10),
        dark: NSColor(calibratedWhite: 1.0, alpha: 0.12)
    )
    static let tempoWorkspaceBackground = Color(
        light: NSColor(calibratedWhite: 0.98, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.055, green: 0.055, blue: 0.06, alpha: 1.0)
    )

    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

struct TempoBorderedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .padding(.horizontal, TempoTheme.Spacing.medium)
            .frame(height: TempoTheme.Layout.controlHeight)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
                    .stroke(.primary.opacity(0.11), lineWidth: 1)
            }
            .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.45)
    }
}

struct TempoToolbarIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TempoToolbarIconButtonBody(configuration: configuration)
    }
}

private struct TempoToolbarIconButtonBody: View {
    let configuration: ButtonStyle.Configuration
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .frame(width: 26, height: 22)
            .background(
                isHovered ? Color.primary.opacity(0.08) : .clear,
                in: RoundedRectangle(cornerRadius: TempoTheme.Radius.small)
            )
            .contentShape(RoundedRectangle(cornerRadius: TempoTheme.Radius.small))
            .onHover { isHovered = $0 }
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct TempoProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, TempoTheme.Spacing.medium)
            .frame(height: TempoTheme.Layout.controlHeight)
            .background(
                Color.tempoBlue.opacity(
                    isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.45
                ),
                in: RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
            )
    }
}

extension View {
    func tempoBorderedButton() -> some View {
        buttonStyle(TempoBorderedButtonStyle())
    }

    func tempoProminentButton() -> some View {
        buttonStyle(TempoProminentButtonStyle())
    }

    func tempoCard(padding: CGFloat = TempoTheme.Spacing.large) -> some View {
        self
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TempoTheme.Radius.large))
            .overlay {
                RoundedRectangle(cornerRadius: TempoTheme.Radius.large)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
    }

    func tempoGlassPanel() -> some View {
        background {
            TempoGlassBackground()
                .ignoresSafeArea()
        }
    }

    func tempoGlassWindowChrome() -> some View {
        background {
            TempoWindowConfigurator()
                .frame(width: 0, height: 0)
        }
        .background {
            TempoGlassBackground()
                .ignoresSafeArea()
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    }
}
