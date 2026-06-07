import SwiftUI

struct PianoKeyboardView: View {
    @Bindable var store: TempoStore

    private let allNotes = Array(21...108)

    private var whiteNotes: [Int] {
        allNotes.filter { !Self.isBlack($0) }
    }

    private var blackNotes: [Int] {
        allNotes.filter(Self.isBlack)
    }

    var body: some View {
        GeometryReader { proxy in
            let whiteWidth = proxy.size.width / CGFloat(whiteNotes.count)
            let blackWidth = max(5, whiteWidth * 0.66)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(whiteNotes, id: \.self) { note in
                        PianoKeyButton(
                            note: note,
                            feedback: store.activeNotes[note],
                            expectedHand: store.expectedNotesByHand[note],
                            isBlack: false
                        ) {
                            store.receive(note: note, previewSound: true)
                        }
                        .frame(width: whiteWidth)
                    }
                }

                ForEach(blackNotes, id: \.self) { note in
                    let precedingWhiteKeys = whiteNotes.filter { $0 < note }.count
                    PianoKeyButton(
                        note: note,
                        feedback: store.activeNotes[note],
                        expectedHand: store.expectedNotesByHand[note],
                        isBlack: true
                    ) {
                        store.receive(note: note, previewSound: true)
                    }
                    .frame(width: blackWidth, height: proxy.size.height * 0.64)
                    .offset(
                        x: whiteWidth * CGFloat(precedingWhiteKeys) - blackWidth / 2
                    )
                    .zIndex(1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.black.opacity(0.28))
            }
        }
        .frame(height: TempoTheme.Layout.keyboardHeight)
        .accessibilityLabel("Full 88-key piano keyboard")
    }

    private static func isBlack(_ note: Int) -> Bool {
        [1, 3, 6, 8, 10].contains(note % 12)
    }
}

private struct PianoKeyButton: View {
    let note: Int
    let feedback: NoteFeedback?
    let expectedHand: PianoHand?
    let isBlack: Bool
    let action: () -> Void

    @ViewBuilder
    var body: some View {
        if let shortcut {
            keyButton.keyboardShortcut(shortcut, modifiers: [])
        } else {
            keyButton
        }
    }

    private var keyButton: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(fillStyle)
                    .overlay(alignment: .bottom) {
                        if let expectedHand {
                            Rectangle()
                                .fill(handColor(expectedHand))
                                .frame(height: isBlack ? 5 : 8)
                        }
                    }
                    .overlay(alignment: .top) {
                        if expectedHand != nil {
                            Circle()
                                .fill(.white)
                                .frame(width: isBlack ? 4 : 6, height: isBlack ? 4 : 6)
                                .shadow(color: .black.opacity(0.25), radius: 1)
                                .padding(.top, isBlack ? 7 : 10)
                        }
                    }

                if !isBlack, note % 12 == 0 {
                    Text("C\(note / 12 - 1)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 12)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Piano note \(note)")
        .accessibilityValue(expectedHand.map { "\($0.rawValue) hand target" } ?? "")
    }

    private var fillStyle: AnyShapeStyle {
        if let feedback {
            return AnyShapeStyle(
                feedback == .correct
                    ? Color.tempoGreen.gradient
                    : Color.tempoRed.gradient
            )
        }
        if let expectedHand {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        handColor(expectedHand).opacity(isBlack ? 0.95 : 0.72),
                        handColor(expectedHand).opacity(isBlack ? 0.62 : 0.28)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        if isBlack {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(white: 0.18), Color(white: 0.025)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [.white, Color(white: 0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func handColor(_ hand: PianoHand) -> Color {
        hand == .right ? .tempoRightHand : .tempoLeftHand
    }

    private var shortcut: KeyEquivalent? {
        let mapping: [Int: Character] = [
            48: "a", 49: "w", 50: "s", 51: "e", 52: "d", 53: "f",
            54: "t", 55: "g", 56: "y", 57: "h", 58: "u", 59: "j"
        ]
        guard let character = mapping[note] else { return nil }
        return KeyEquivalent(character)
    }
}
