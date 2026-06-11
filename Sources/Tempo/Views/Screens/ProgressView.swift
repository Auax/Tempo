import Charts
import SwiftUI

struct ProgressScreen: View {
    @Bindable var store: TempoStore
    @State private var range: ProgressDateRange = .week

    private var filteredPieces: [Piece] {
        guard let startDate = range.startDate else {
            return store.pieces.sorted { $0.lastPracticed < $1.lastPracticed }
        }
        return store.pieces
            .filter { $0.lastPracticed >= startDate }
            .sorted { $0.lastPracticed < $1.lastPracticed }
    }

    private var rankedPieces: [Piece] {
        filteredPieces.sorted {
            if $0.progress == $1.progress {
                return $0.lastPracticed > $1.lastPracticed
            }
            return $0.progress > $1.progress
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TempoTheme.Spacing.xLarge) {
                ProgressHeader(range: $range)

                ProgressMetricGrid(store: store)

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                        NoteResultsCard(metrics: store.metrics)
                        AccuracyTrendCard(pieces: filteredPieces)
                    }

                    VStack(spacing: TempoTheme.Spacing.large) {
                        NoteResultsCard(metrics: store.metrics)
                        AccuracyTrendCard(pieces: filteredPieces)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                        ProgressHighlightsCard(store: store)
                            .frame(width: 320)
                        TopPiecesCard(pieces: rankedPieces, store: store)
                            .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: TempoTheme.Spacing.large) {
                        ProgressHighlightsCard(store: store)
                        TopPiecesCard(pieces: rankedPieces, store: store)
                    }
                }
            }
            .frame(maxWidth: 1_240, alignment: .leading)
            .padding(TempoTheme.Spacing.xLarge)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primary.opacity(0.025))
    }
}

private enum ProgressDateRange: String, CaseIterable, Identifiable {
    case week
    case month
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .week:
            "Last 7 Days"
        case .month:
            "Last 30 Days"
        case .all:
            "All Time"
        }
    }

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: .now))
        case .month:
            return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: .now))
        case .all:
            return nil
        }
    }

    var dateLabel: String {
        guard let startDate else { return title }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: .now))"
    }
}

private struct ProgressHeader: View {
    @Binding var range: ProgressDateRange

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: TempoTheme.Spacing.large) {
                title
                Spacer(minLength: TempoTheme.Spacing.large)
                rangeMenu
            }

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
                title
                rangeMenu
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
            Text("Progress")
                .font(.largeTitle.weight(.semibold))
            Text("See how your current session and score library are developing.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var rangeMenu: some View {
        Menu {
            Picker("Date Range", selection: $range) {
                ForEach(ProgressDateRange.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
        } label: {
            HStack(spacing: TempoTheme.Spacing.small) {
                Image(systemName: "calendar")
                Text(range.dateLabel)
                    .monospacedDigit()
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .tempoCard(padding: TempoTheme.Spacing.medium)
        .accessibilityLabel("Progress date range, \(range.title)")
    }
}

private struct ProgressMetricGrid: View {
    @Bindable var store: TempoStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: TempoTheme.Spacing.large) {
                cards
            }

            Grid(horizontalSpacing: TempoTheme.Spacing.large, verticalSpacing: TempoTheme.Spacing.large) {
                GridRow {
                    practiceTime
                    accuracy
                }
                GridRow {
                    notesPlayed
                    longestStreak
                }
            }
        }
    }

    @ViewBuilder
    private var cards: some View {
        practiceTime
        accuracy
        notesPlayed
        longestStreak
    }

    private var practiceTime: some View {
        ProgressMetricCard(
            symbol: "clock",
            color: .tempoBlue,
            label: "Practice Time",
            value: TempoFormatters.duration(store.metrics.practicedSeconds),
            detail: "Current session"
        )
    }

    private var accuracy: some View {
        ProgressMetricCard(
            symbol: "scope",
            color: .tempoGreen,
            label: "Accuracy",
            value: store.metrics.accuracy.formatted(
                .percent.precision(.fractionLength(0))
            ),
            detail: store.metrics.totalNotes == 0
                ? "Play notes to begin"
                : "\(store.metrics.correctNotes) of \(store.metrics.totalNotes) notes correct"
        )
    }

    private var notesPlayed: some View {
        ProgressMetricCard(
            symbol: "music.note",
            color: .tempoOrange,
            label: "Notes Played",
            value: "\(store.metrics.totalNotes)",
            detail: "\(store.metrics.mistakes + store.metrics.missedNotes + store.metrics.extraNotes) to review"
        )
    }

    private var longestStreak: some View {
        ProgressMetricCard(
            symbol: "bolt.fill",
            color: .tempoBlueSoft,
            label: "Longest Streak",
            value: "\(store.metrics.longestStreak)",
            detail: "Correct notes in a row"
        )
    }
}

private struct ProgressMetricCard: View {
    let symbol: String
    let color: Color
    let label: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
            HStack(spacing: TempoTheme.Spacing.small) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 18, alignment: .leading)

                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                Text(value)
                    .font(.title.weight(.semibold))
                    .contentTransition(.numericText())

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.large)
    }
}

private struct NoteResult: Identifiable {
    let name: String
    let value: Int
    let color: Color

    var id: String { name }
}

private struct NoteResultsCard: View {
    let metrics: SessionMetrics

    private var results: [NoteResult] {
        [
            NoteResult(name: "Correct", value: metrics.correctNotes, color: .tempoGreen),
            NoteResult(name: "Mistakes", value: metrics.mistakes, color: .tempoRed),
            NoteResult(name: "Missed", value: metrics.missedNotes, color: .tempoOrange),
            NoteResult(name: "Extra", value: metrics.extraNotes, color: .tempoBlueSoft)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            ChartCardHeader(
                title: "Note Results",
                subtitle: "Current session"
            )

            ZStack {
                Chart(results) { result in
                    BarMark(
                        x: .value("Result", result.name),
                        y: .value("Notes", result.value)
                    )
                    .foregroundStyle(result.color.gradient)
                    .cornerRadius(5)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(.hidden)

                if metrics.totalNotes == 0 {
                    ChartEmptyState(
                        symbol: "pianokeys",
                        message: "Practice results will appear here."
                    )
                }
            }
            .frame(height: 210)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }
}

private struct AccuracyTrendCard: View {
    let pieces: [Piece]

    private var accuracyPieces: [Piece] {
        pieces.filter { $0.bestAccuracy > 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            ChartCardHeader(
                title: "Accuracy by Piece",
                subtitle: "\(accuracyPieces.count) recent \(accuracyPieces.count == 1 ? "score" : "scores")"
            )

            ZStack {
                Chart(accuracyPieces) { piece in
                    LineMark(
                        x: .value("Practiced", piece.lastPracticed),
                        y: .value("Accuracy", piece.bestAccuracy)
                    )
                    .foregroundStyle(Color.tempoBlue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Practiced", piece.lastPracticed),
                        y: .value("Accuracy", piece.bestAccuracy)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.tempoBlue.opacity(0.24), .tempoBlue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Practiced", piece.lastPracticed),
                        y: .value("Accuracy", piece.bestAccuracy)
                    )
                    .foregroundStyle(Color.tempoBlue)
                    .symbolSize(42)
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 0.25, 0.5, 0.75, 1]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let accuracy = value.as(Double.self) {
                                Text(accuracy, format: .percent.precision(.fractionLength(0)))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartLegend(.hidden)

                if accuracyPieces.isEmpty {
                    ChartEmptyState(
                        symbol: "chart.xyaxis.line",
                        message: "No practiced scores in this date range."
                    )
                }
            }
            .frame(height: 210)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }
}

private struct ChartCardHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
            Spacer()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ChartEmptyState: View {
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: TempoTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TempoTheme.Radius.medium))
    }
}

private struct ProgressHighlightsCard: View {
    @Bindable var store: TempoStore

    private var bestPiece: Piece? {
        store.pieces.max { $0.bestAccuracy < $1.bestAccuracy }
    }

    private var mostAdvancedPiece: Piece? {
        store.pieces.max { $0.progress < $1.progress }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            Text("Highlights")
                .font(.title3.weight(.semibold))

            HighlightRow(
                symbol: "scope",
                color: .tempoGreen,
                title: "Best accuracy",
                detail: bestAccuracyDetail
            )

            Divider()

            HighlightRow(
                symbol: "bolt.fill",
                color: .tempoBlueSoft,
                title: "Longest streak",
                detail: "\(store.metrics.longestStreak) correct notes"
            )

            Divider()

            HighlightRow(
                symbol: "chart.line.uptrend.xyaxis",
                color: .tempoOrange,
                title: "Most advanced score",
                detail: mostAdvancedDetail
            )
        }
        .frame(maxWidth: .infinity, minHeight: 238, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }

    private var bestAccuracyDetail: String {
        guard let bestPiece else { return "No scores yet" }
        let accuracy = bestPiece.bestAccuracy.formatted(
            .percent.precision(.fractionLength(0))
        )
        return "\(accuracy) - \(bestPiece.title)"
    }

    private var mostAdvancedDetail: String {
        guard let mostAdvancedPiece else { return "No scores yet" }
        let progress = mostAdvancedPiece.progress.formatted(
            .percent.precision(.fractionLength(0))
        )
        return "\(progress) - \(mostAdvancedPiece.title)"
    }
}

private struct HighlightRow: View {
    let symbol: String
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: TempoTheme.Spacing.medium) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct TopPiecesCard: View {
    let pieces: [Piece]
    @Bindable var store: TempoStore

    private var visiblePieces: [Piece] {
        Array(pieces.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            HStack {
                Text("Top Pieces")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("View Library") {
                    store.openDestination(.library)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.tempoBlue)
            }

            if visiblePieces.isEmpty {
                ChartEmptyState(
                    symbol: "music.note.list",
                    message: "No practiced scores in this date range."
                )
                .frame(maxWidth: .infinity, minHeight: 176)
            } else {
                VStack(spacing: TempoTheme.Spacing.medium) {
                    ForEach(Array(visiblePieces.enumerated()), id: \.element.id) { index, piece in
                        TopPieceRow(rank: index + 1, piece: piece, store: store)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 238, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }
}

private struct TopPieceRow: View {
    let rank: Int
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        Button {
            store.selectPiece(piece, startPractice: true)
        } label: {
            HStack(spacing: TempoTheme.Spacing.medium) {
                Text("\(rank)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 18, alignment: .trailing)

                ScoreArtworkView(
                    title: piece.title,
                    composer: piece.composer,
                    artwork: piece.artwork,
                    scorePath: piece.scorePath
                )
                .frame(width: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(piece.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(piece.composer.isEmpty ? "Unknown composer" : piece.composer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: TempoTheme.Spacing.medium)

                Text(piece.bestAccuracy, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)

                ProgressView(value: piece.progress)
                    .tint(.tempoBlue)
                    .frame(width: 104)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Practice \(piece.title)")
    }
}

#if DEBUG
#Preview("Progress") {
    ProgressScreen(store: PreviewFixtures.store(withSession: true))
        .frame(width: 1_080, height: 760)
}
#endif
