import SwiftUI

struct PairingView: View {
    @Environment(\.dismiss) private var dismiss
    let midiName: String?

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Connect a Companion")
                        .font(.title2.weight(.semibold))
                    Text("Keep the Mac as the session host.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .tempoBorderedButton()
            }

            HStack(spacing: 28) {
                PairingCodeView()
                    .frame(width: 168, height: 168)
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.1), radius: 16, y: 6)

                VStack(alignment: .leading, spacing: 16) {
                    Label("Open Tempo on your phone or tablet", systemImage: "1.circle.fill")
                    Label("Choose Join Session", systemImage: "2.circle.fill")
                    Label("Scan this code or enter TEMPO-42", systemImage: "3.circle.fill")

                    Divider()

                    Label(
                        midiName.map { "\($0) is ready" } ?? "No MIDI piano selected",
                        systemImage: midiName == nil ? "pianokeys" : "checkmark.circle.fill"
                    )
                    .foregroundStyle(midiName == nil ? Color.secondary : .tempoGreen)
                }
                .font(.subheadline)
            }

            Text("Companion devices can show the score, session controls, or live statistics. Your practice continues if a device disconnects.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(28)
        .frame(width: 590)
    }
}

private struct PairingCodeView: View {
    private let cells: Set<Int> = [
        0, 1, 2, 3, 4, 6, 8, 9, 10, 11, 12,
        14, 18, 20, 24, 28, 30, 32, 34, 36, 38,
        40, 41, 42, 43, 44, 46, 48, 50, 51, 52,
        54, 57, 59, 61, 63, 64, 66, 68, 70, 72,
        74, 76, 77, 79, 81, 83, 85, 87, 88, 90,
        92, 94, 96, 98, 100, 101, 102, 103, 104,
        106, 108, 110, 112, 114, 116, 118, 120
    ]

    var body: some View {
        GeometryReader { proxy in
            let columns = 11
            let cell = proxy.size.width / CGFloat(columns)

            Canvas { context, _ in
                for index in cells {
                    let row = index / columns
                    let column = index % columns
                    let rect = CGRect(
                        x: CGFloat(column) * cell + 1,
                        y: CGFloat(row) * cell + 1,
                        width: cell - 2,
                        height: cell - 2
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: cell * 0.16),
                        with: .color(index % 7 == 0 ? .tempoBlue : .black)
                    )
                }
            }
        }
        .accessibilityLabel("Pairing code TEMPO-42")
    }
}

#if DEBUG
#Preview("Companion Pairing") {
    PairingView(midiName: "Digital Piano")
}
#endif
