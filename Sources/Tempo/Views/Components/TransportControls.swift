import SwiftUI

struct TransportControls: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack {
            HandToggleGroup(selection: $store.handSelection)
                .frame(width: 132, alignment: .leading)

            Spacer()

            HStack(spacing: 22) {
                Button(action: store.goToStart) {
                    Image(systemName: "backward.end.alt.fill")
                }
                .help("Back to Start")

                Button(action: store.skipBackward) {
                    Image(systemName: "backward.fill")
                }
                .help("Previous Measure")

                Button(action: store.playPause) {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [.tempoBlueSoft, .tempoBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Circle()
                        )
                        .shadow(color: .tempoBlue.opacity(0.28), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .help(store.isPlaying ? "Pause" : "Play")

                Button(action: store.skipForward) {
                    Image(systemName: "forward.fill")
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

private struct HandToggleGroup: View {
    @Binding var selection: HandSelection

    private var isLeftSelected: Bool {
        selection == .left || selection == .both
    }

    private var isRightSelected: Bool {
        selection == .right || selection == .both
    }

    var body: some View {
        HStack(spacing: 4) {
            handButton(
                label: "L",
                isSelected: isLeftSelected,
                activeColor: .tempoLeftHand,
                help: "Left hand"
            ) {
                toggleLeft()
            }

            handButton(
                label: "R",
                isSelected: isRightSelected,
                activeColor: .tempoRightHand,
                help: "Right hand"
            ) {
                toggleRight()
            }
        }
    }

    private func handButton(
        label: String,
        isSelected: Bool,
        activeColor: Color,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(isSelected ? Color.white : .secondary)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected ? activeColor : Color.primary.opacity(0.06))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isSelected ? activeColor.opacity(0.4) : Color.primary.opacity(0.08))
                }
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func toggleLeft() {
        switch selection {
        case .both:
            selection = .right
        case .left:
            break
        case .right:
            selection = .both
        }
    }

    private func toggleRight() {
        switch selection {
        case .both:
            selection = .left
        case .right:
            break
        case .left:
            selection = .both
        }
    }
}
