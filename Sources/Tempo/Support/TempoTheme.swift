import SwiftUI

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
        static let medium: CGFloat = 12
        static let large: CGFloat = 18
        static let xLarge: CGFloat = 24
    }

    enum Layout {
        static let sidebarExpanded: CGFloat = 248
        static let sidebarCollapsed: CGFloat = 76
        static let inspectorWidth: CGFloat = 286
        static let topBarHeight: CGFloat = 64
        static let transportHeight: CGFloat = 66
        static let keyboardHeight: CGFloat = 148
    }

    enum Motion {
        static let quick = Animation.easeOut(duration: 0.18)
        static let standard = Animation.spring(duration: 0.3, bounce: 0.08)
    }
}

extension Color {
    static let tempoPurple = Color(red: 0.49, green: 0.27, blue: 0.96)
    static let tempoPurpleSoft = Color(red: 0.58, green: 0.43, blue: 1)
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

    init(light: NSColor, dark: NSColor) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}

extension View {
    func tempoCard(padding: CGFloat = TempoTheme.Spacing.large) -> some View {
        self
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TempoTheme.Radius.large))
            .overlay {
                RoundedRectangle(cornerRadius: TempoTheme.Radius.large)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
    }
}
