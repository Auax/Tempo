import SwiftUI

struct PracticeWorkspaceView: View {
    @Bindable var store: TempoStore
    @AppStorage("tempo.visualKeyboard") private var visualKeyboard = true

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    VerovioScoreView(
                        score: store.parsedScore,
                        errorMessage: store.scoreError,
                        currentMeasure: store.currentMeasure,
                        zoom: store.scoreZoom,
                        expectedNotes: store.expectedScoreNotes,
                        feedback: store.activeScoreFeedback
                    )
                    .frame(
                        minWidth: max(proxy.size.width - 36, 720),
                        minHeight: max(proxy.size.height - 36, 390)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: TempoTheme.Radius.large))
                    .overlay {
                        RoundedRectangle(cornerRadius: TempoTheme.Radius.large)
                            .stroke(.primary.opacity(0.08))
                    }
                    .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
                    .padding(18)
                }
                .background(Color.primary.opacity(0.025))
            }

            TransportControls(store: store)

            if visualKeyboard {
                PianoKeyboardView(store: store)
                    .padding(.horizontal, store.focusMode ? 12 : 20)
                    .padding(.vertical, 10)
                    .background(Color.tempoPanel)
            }

            if !store.focusMode {
                feedbackLegend
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var feedbackLegend: some View {
        HStack(spacing: 18) {
            LegendItem(label: "Correct note", color: .tempoGreen)
            LegendItem(label: "Wrong note", color: .tempoRed)
            LegendItem(label: "Right hand", color: .tempoRightHand)
            LegendItem(label: "Left hand", color: .tempoLeftHand)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

private struct LegendItem: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
        }
    }
}
