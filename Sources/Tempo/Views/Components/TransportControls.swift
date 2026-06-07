import SwiftUI

struct TransportControls: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack {
            Menu {
                Picker("Hands", selection: $store.handSelection) {
                    ForEach(HandSelection.allCases) { selection in
                        Text(selection.rawValue).tag(selection)
                    }
                }
            } label: {
                Label(store.handSelection.rawValue, systemImage: "hands.and.sparkles")
                    .font(.caption)
            }
            .menuStyle(.button)
            .frame(width: 132, alignment: .leading)

            Spacer()

            HStack(spacing: 22) {
                Button(action: store.skipBackward) {
                    Image(systemName: "backward.end.fill")
                }
                .help("Previous Measure")

                Button(action: store.playPause) {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [.tempoPurpleSoft, .tempoPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: .tempoPurple.opacity(0.28), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .help(store.isPlaying ? "Pause" : "Play")

                Button(action: store.skipForward) {
                    Image(systemName: "forward.end.fill")
                }
                .help("Next Measure")
            }
            .buttonStyle(.borderless)

            Spacer()

            HStack(spacing: 14) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(store.metrics.accuracy, format: .percent.precision(.fractionLength(0)))
                        .font(.headline.monospacedDigit())
                    Text("Accuracy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button {
                    withAnimation(TempoTheme.Motion.standard) {
                        store.inspectorVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .help("Toggle Feedback")
            }
            .frame(width: 132, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: TempoTheme.Layout.transportHeight)
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
