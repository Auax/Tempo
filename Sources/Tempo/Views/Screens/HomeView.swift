import SwiftUI

struct HomeView: View {
    @Bindable var store: TempoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TempoTheme.Spacing.xLarge) {
                HomeHeader(store: store)

                if store.pieces.isEmpty {
                    HomeEmptyState(store: store)
                } else {
                    if let piece = store.recentlyPracticedPiece {
                        ContinuePracticeCard(piece: piece, store: store)
                    }

                    HomeOverviewGrid(store: store)
                    PianoConnectionCard(store: store)
                }
            }
            .frame(maxWidth: 1_240, alignment: .leading)
            .padding(TempoTheme.Spacing.xLarge)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primary.opacity(0.025))
    }
}

private struct HomeHeader: View {
    @Bindable var store: TempoStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: TempoTheme.Spacing.large) {
                greeting
                Spacer(minLength: TempoTheme.Spacing.large)
                actions
            }

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
                greeting
                actions
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
            Text(greetingTitle)
                .font(.largeTitle.weight(.semibold))
            Text("Ready for a focused practice session?")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack(spacing: TempoTheme.Spacing.medium) {
            // if let piece = store.recentlyPracticedPiece {
            //     Button {
            //         store.selectPiece(piece, startPractice: true)
            //     } label: {
            //         Label("Continue Practice", systemImage: "play.fill")
            //             .frame(minWidth: 126)
            //     }
            //     .tempoProminentButton()
            // }

            Button {
                store.showingImporter = true
            } label: {
                Label("Import Score", systemImage: "square.and.arrow.down")
            }
            .tempoBorderedButton()
        }
    }

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
}

private struct HomeEmptyState: View {
    @Bindable var store: TempoStore

    var body: some View {
        ContentUnavailableView {
            Label("No Scores Yet", systemImage: "music.note.list")
        } description: {
            Text("Import a MusicXML file to start practicing.")
        } actions: {
            Button("Import Score") {
                store.showingImporter = true
            }
            .tempoProminentButton()
        }
        .frame(maxWidth: .infinity, minHeight: 420)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }
}

private struct ContinuePracticeCard: View {
    let piece: Piece
    @Bindable var store: TempoStore

    private var activeSection: PracticeSection? {
        piece.sections.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            HStack {
                Text("Continue Practicing")
                    .font(.title3.weight(.semibold))
                Spacer()
                LibraryPieceMenu(piece: piece, store: store)
            }

            ViewThatFits(in: .horizontal) {
                wideContent
                compactContent
            }
        }
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }

    private var wideContent: some View {
        HStack(spacing: TempoTheme.Spacing.xLarge) {
            artwork
            details
            Spacer(minLength: TempoTheme.Spacing.large)
            continueButton
        }
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                artwork
                details
            }
            continueButton
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var artwork: some View {
        ScoreArtworkView(
            title: piece.title,
            composer: piece.composer,
            artwork: piece.artwork,
            difficulty: piece.difficulty,
            genre: piece.genre,
            scorePath: piece.scorePath
        )
            .frame(width: 142)
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.small) {
            Text(piece.title)
                .font(.title.weight(.semibold))
                .lineLimit(2)
            Text(piece.composer.isEmpty ? "Unknown composer" : piece.composer)
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.small) {
                Text("CURRENT SECTION")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.tempoBlue)

                Text(activeSection?.measureLabel ?? "Full score")
                    .font(.headline)

                ProgressView(value: piece.progress)
                    .tint(.tempoBlue)
                    .frame(maxWidth: 360)

                Text("Last practiced \(TempoFormatters.relativeDate.localizedString(for: piece.lastPracticed, relativeTo: .now))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, TempoTheme.Spacing.medium)
        }
        .frame(maxWidth: 440, alignment: .leading)
    }

    private var continueButton: some View {
        Button {
            store.selectPiece(piece, startPractice: true)
        } label: {
            Label("Continue", systemImage: "play.fill")
                .frame(minWidth: 92)
        }
        .tempoProminentButton()
    }
}

private struct HomeOverviewGrid: View {
    @Bindable var store: TempoStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                PracticeOverviewCard(store: store)
                    .fixedSize(horizontal: true, vertical: false)
                RecentScoresCard(store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: TempoTheme.Spacing.large) {
                PracticeOverviewCard(store: store)
                RecentScoresCard(store: store)
            }
        }
    }
}

private struct PracticeOverviewCard: View {
    @Bindable var store: TempoStore

    private var piece: Piece? {
        store.recentlyPracticedPiece
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            Text("Practice Overview")
                .font(.title3.weight(.semibold))

            HStack(spacing: 15) {
                HomeMetric(
                    symbol: "clock",
                    color: .tempoBlue,
                    value: sessionDuration,
                    label: "Session Time"
                )

                Divider()
                    .frame(height: 74)

                HomeMetric(
                    symbol: "scope",
                    color: .tempoGreen,
                    value: accuracy,
                    label: "Best Accuracy"
                )

                Divider()
                    .frame(height: 74)

                HomeMetric(
                    symbol: "chart.line.uptrend.xyaxis",
                    color: .tempoOrange,
                    value: progress,
                    label: "Piece Progress"
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }

    private var sessionDuration: String {
        store.metrics.practicedSeconds > 0
            ? TempoFormatters.duration(store.metrics.practicedSeconds)
            : "0m"
    }

    private var accuracy: String {
        (piece?.bestAccuracy ?? 0).formatted(
            .percent.precision(.fractionLength(0))
        )
    }

    private var progress: String {
        (piece?.progress ?? 0).formatted(
            .percent.precision(.fractionLength(0))
        )
    }

}

private struct HomeMetric: View {
    let symbol: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: TempoTheme.Spacing.small) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(height: 34)

            Text(value)
                .font(.title2.weight(.semibold))
                .contentTransition(.numericText())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct RecentScoresCard: View {
    @Bindable var store: TempoStore

    private var recentPieces: [Piece] {
        Array(store.sortedPieces(store.pieces).prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            HStack {
                Text("Recent Scores")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("View All") {
                    store.openDestination(.library)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.tempoBlue)
            }

            VStack(spacing: TempoTheme.Spacing.medium) {
                ForEach(recentPieces) { piece in
                    RecentScoreRow(piece: piece, store: store)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }
}

private struct RecentScoreRow: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: TempoTheme.Spacing.medium) {
            Button {
                store.selectPiece(piece, startPractice: true)
            } label: {
                HStack(spacing: TempoTheme.Spacing.medium) {
                    PieceArtwork(title: piece.title, size: 44)

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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: TempoTheme.Spacing.small)

            Text(TempoFormatters.relativeDate.localizedString(for: piece.lastPracticed, relativeTo: .now))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            LibraryPieceMenu(piece: piece, store: store)
        }
    }
}

private struct PianoConnectionCard: View {
    @Bindable var store: TempoStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: TempoTheme.Spacing.large) {
                connectionIdentity
                Spacer()
                connectionStatus
                Spacer()
                configureButton
            }

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
                connectionIdentity
                HStack {
                    connectionStatus
                    Spacer()
                    configureButton
                }
            }
        }
        .tempoCard(padding: TempoTheme.Spacing.xLarge)
    }

    private var connectionIdentity: some View {
        HStack(spacing: TempoTheme.Spacing.medium) {
            Image(systemName: "pianokeys")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.tempoBlue)
                .frame(width: 34, height: 34)
            Text("Piano Connection")
                .font(.headline)
        }
    }

    private var connectionStatus: some View {
        HStack(alignment: .top, spacing: TempoTheme.Spacing.small) {
            Circle()
                .fill(store.midiService.isConnected ? Color.tempoGreen : Color.secondary)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.midiService.isConnected ? "Connected" : "Not connected")
                    .font(.subheadline.weight(.medium))
                Text(store.midiService.activeSourceName ?? "Choose a MIDI input")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var configureButton: some View {
        Button {
            store.midiService.refreshSources()
            store.showingMIDIConnection = true
        } label: {
            Label("Configure", systemImage: "gearshape")
        }
        .tempoBorderedButton()
    }
}

#if DEBUG
#Preview("Home") {
    HomeView(store: PreviewFixtures.store(withSession: true))
        .frame(width: 1_080, height: 760)
}
#endif
