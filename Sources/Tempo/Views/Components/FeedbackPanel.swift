import SwiftUI

struct FeedbackPanel: View {
    @Bindable var store: TempoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Feedback")
                            .font(.headline)
                        Text(store.practiceMode.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(TempoTheme.Motion.standard) {
                            store.inspectorVisible = false
                        }
                    } label: {
                        Image(systemName: "sidebar.trailing")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Hide Feedback")
                }

                AccuracyRing(value: store.metrics.accuracy)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 0) {
                    CompactMetric(
                        title: "Correct",
                        value: "\(store.metrics.correctNotes)",
                        color: .tempoGreen
                    )
                    CompactMetric(
                        title: "Mistakes",
                        value: "\(store.metrics.mistakes)",
                        color: .tempoRed
                    )
                    CompactMetric(
                        title: "Missed",
                        value: "\(store.metrics.missedNotes)",
                        color: .tempoOrange
                    )
                }
                .padding(.vertical, 10)
                .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))

                Divider()

                VStack(alignment: .leading, spacing: 11) {
                    Text("Current Session")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    DetailMetricRow(
                        label: "Time practiced",
                        value: TempoFormatters.duration(store.metrics.practicedSeconds)
                    )
                    DetailMetricRow(
                        label: "Longest streak",
                        value: "\(store.metrics.longestStreak) notes"
                    )
                    DetailMetricRow(
                        label: "Current measure",
                        value: "\(store.currentMeasure)"
                    )
                    DetailMetricRow(
                        label: "Active hands",
                        value: store.handSelection.rawValue
                    )
                }

                Button {
                    store.showingSessionReview = true
                } label: {
                    Label("Review Session", systemImage: "chart.bar.doc.horizontal")
                        .frame(maxWidth: .infinity)
                }
                .tempoProminentButton()
                .disabled(!store.hasSessionData)

                Button {
                    store.resetSession()
                } label: {
                    Label("Reset Session", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .tempoBorderedButton()
            }
            .padding(18)
        }
        .frame(width: TempoTheme.Layout.inspectorWidth)
        .background(.ultraThinMaterial)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.primary.opacity(0.07))
                .frame(width: 1)
        }
    }
}

private struct AccuracyRing: View {
    let value: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.07), lineWidth: 9)
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    AngularGradient(
                        colors: [.tempoBlue, .tempoGreen],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(value, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .monospacedDigit()
                Text(value == 0 ? "No notes played" : "Current session")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 126, height: 126)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Overall accuracy")
    }
}

private struct CompactMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DetailMetricRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.caption)
    }
}
