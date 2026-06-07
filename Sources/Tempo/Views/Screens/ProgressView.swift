import SwiftUI

struct ProgressScreen: View {
    @Bindable var store: TempoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.largeTitle.weight(.semibold))
                    Text("Results from the current practice session.")
                        .foregroundStyle(.secondary)
                }

                if store.hasSessionData {
                    HStack(spacing: 16) {
                        SessionStat(
                            value: TempoFormatters.duration(store.metrics.practicedSeconds),
                            label: "Practice time"
                        )
                        SessionStat(
                            value: store.metrics.accuracy.formatted(
                                .percent.precision(.fractionLength(0))
                            ),
                            label: "Accuracy"
                        )
                        SessionStat(
                            value: "\(store.metrics.correctNotes)",
                            label: "Correct notes"
                        )
                        SessionStat(
                            value: "\(store.metrics.longestStreak)",
                            label: "Longest streak"
                        )
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Practice Data", systemImage: "chart.xyaxis.line")
                    } description: {
                        Text("Play notes during a practice session to record results.")
                    }
                    .frame(maxWidth: .infinity, minHeight: 380)
                }
            }
            .padding(30)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primary.opacity(0.025))
    }
}

private struct SessionStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(value)
                .font(.title2.weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .tempoCard()
        .frame(maxWidth: .infinity)
    }
}
