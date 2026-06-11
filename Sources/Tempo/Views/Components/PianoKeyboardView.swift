import SwiftUI

struct PianoKeyboardView: View {
    @Bindable var store: TempoStore

    private static let allNotes = Array(21...108)
    private static let whiteNotes = allNotes.filter { !isBlack($0) }
    private static let blackNotes = allNotes.filter(isBlack)
    private static let precedingWhiteKeyCounts = Dictionary(
        uniqueKeysWithValues: blackNotes.map { note in
            (note, whiteNotes.partitioningIndex { $0 >= note })
        }
    )

    var body: some View {
        GeometryReader { proxy in
            let activeNotes = store.activeNotes
            let expectedNotesByHand = store.expectedNotesByHand
            let whiteWidth = proxy.size.width / CGFloat(Self.whiteNotes.count)
            let blackWidth = max(5, whiteWidth * 0.66)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(Self.whiteNotes, id: \.self) { note in
                        PianoKeyButton(
                            note: note,
                            feedback: activeNotes[note],
                            expectedHand: expectedNotesByHand[note],
                            isBlack: false
                        ) {
                            store.receive(note: note, previewSound: true)
                        }
                        .frame(width: whiteWidth)
                    }
                }

                ForEach(Self.blackNotes, id: \.self) { note in
                    let precedingWhiteKeys = Self.precedingWhiteKeyCounts[note] ?? 0
                    PianoKeyButton(
                        note: note,
                        feedback: activeNotes[note],
                        expectedHand: expectedNotesByHand[note],
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

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(fillStyle)

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
                    ? Color.tempoGreen
                    : Color.tempoRed
            )
        }
        if let expectedHand {
            return AnyShapeStyle(handColor(expectedHand))
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
}

private extension Array {
    func partitioningIndex(where predicate: (Element) -> Bool) -> Int {
        firstIndex(where: predicate) ?? endIndex
    }
}

#if DEBUG
#Preview("Piano Keyboard") {
    PianoKeyboardView(store: PreviewFixtures.store(practicing: true))
        .padding()
        .frame(width: 1_080)
}
#endif
