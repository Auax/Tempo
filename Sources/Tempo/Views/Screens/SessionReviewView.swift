import SwiftUI

struct SessionReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: TempoStore

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Session Review")
                        .font(.title2.weight(.semibold))
                    Text(store.selectedPiece?.title ?? "Practice session")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .tempoBorderedButton()
            }

            HStack(spacing: 14) {
                ReviewMetric(
                    value: store.metrics.accuracy.formatted(
                        .percent.precision(.fractionLength(0))
                    ),
                    label: "Accuracy",
                    color: .tempoGreen
                )
                ReviewMetric(
                    value: TempoFormatters.duration(store.metrics.practicedSeconds),
                    label: "Time in score",
                    color: .tempoBlue
                )
                ReviewMetric(
                    value: "\(store.metrics.longestStreak)",
                    label: "Longest streak",
                    color: .tempoOrange
                )
                ReviewMetric(
                    value: "\(store.metrics.mistakes)",
                    label: "Mistakes",
                    color: .tempoRed
                )
            }
        }
        .padding(28)
        .frame(width: 680)
    }
}

private struct ReviewMetric: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .tempoCard()
    }
}

#if DEBUG
#Preview("Session Review") {
    SessionReviewView(store: PreviewFixtures.store(practicing: true, withSession: true))
}
#endif
