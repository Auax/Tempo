import SwiftUI

struct HomeView: View {
    @Bindable var store: TempoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Welcome back")
                            .font(.largeTitle.weight(.semibold))
                        Text("Pick up where you left off or start something new.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        store.showingImporter = true
                    } label: {
                        Label("Import Score", systemImage: "square.and.arrow.down")
                    }
                    .tempoProminentButton()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, TempoTheme.Spacing.xLarge)
                .padding(.top, TempoTheme.Spacing.xLarge)
                .padding(.bottom, TempoTheme.Spacing.large)

                VStack(alignment: .leading, spacing: 26) {
                    if store.pieces.isEmpty {
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
                        .frame(maxWidth: .infinity, minHeight: 360)
                    } else {
                        if let piece = store.recentlyPracticedPiece {
                            ContinuePracticeCard(piece: piece, store: store)
                        }

                        Text("Your Scores")
                            .font(.title2.weight(.semibold))

                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .adaptive(
                                        minimum: TempoTheme.Layout.libraryScoreCardMin,
                                        maximum: TempoTheme.Layout.libraryScoreCardMax
                                    ),
                                    spacing: TempoTheme.Spacing.large
                                )
                            ],
                            spacing: TempoTheme.Spacing.large
                        ) {
                            ForEach(store.pieces) { piece in
                                LibraryScoreCard(piece: piece, store: store)
                            }
                        }
                    }
                }
                .padding(.horizontal, TempoTheme.Spacing.xLarge)
                .padding(.top, TempoTheme.Spacing.xLarge)
                .padding(.bottom, TempoTheme.Spacing.xLarge)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.primary.opacity(0.025))
    }
}

private struct ContinuePracticeCard: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 24) {
            ScoreGradientArtwork(piece: piece)
                .frame(width: 132)

            VStack(alignment: .leading, spacing: 7) {
                Text("CONTINUE PRACTICING")
                    .font(.caption.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.tempoBlue)
                Text(piece.title)
                    .font(.title.weight(.semibold))
                Text("\(piece.composer) • \(piece.collection)")
                    .foregroundStyle(.secondary)

                Text(piece.fileName ?? piece.collection)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.selectPiece(piece, startPractice: true)
            } label: {
                Label("Continue", systemImage: "play.fill")
                    .frame(minWidth: 92)
            }
            .tempoProminentButton()
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.tempoBlue.opacity(0.14),
                    Color.tempoBlue.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: TempoTheme.Radius.xLarge)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TempoTheme.Radius.xLarge)
                .stroke(Color.tempoBlue.opacity(0.18))
        }
    }
}
