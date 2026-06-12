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
                    ContinuePracticingSection(store: store)
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
                // actions
            }

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
                greeting
                // actions
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
            return "Good morning 👋"
        case 12..<18:
            return "Good afternoon 👋"
        default:
            return "Good evening 👋"
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

private struct ContinuePracticingSection: View {
    @Bindable var store: TempoStore

    private var pieces: [Piece] {
        Array(store.sortedPieces(store.pieces).prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            HStack {
                Text("Continue Practicing")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("View all") {
                    store.openDestination(.library)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.tempoBlue)
            }

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                    practiceCards
                }

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                        practiceCards
                    }
                    .padding(.vertical, TempoTheme.Spacing.medium)
                }
                .scrollClipDisabled()
                .scrollIndicators(.hidden)
            }
        }
    }

    @ViewBuilder
    private var practiceCards: some View {
        ForEach(pieces) { piece in
            SheetMusicCard(
                piece: piece,
                store: store,
                showsActions: false
            )
            .frame(width: TempoTheme.Layout.libraryScoreCardMin)
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
