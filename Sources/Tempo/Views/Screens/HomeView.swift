import SwiftUI

struct HomeView: View {
    @Bindable var store: TempoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
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
                    if let piece = store.selectedPiece {
                        ContinuePracticeCard(piece: piece, store: store)
                    }

                    Text("Your Scores")
                        .font(.title2.weight(.semibold))

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 220), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(store.pieces) { piece in
                            PieceCard(piece: piece, store: store)
                        }
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 1180)
            .frame(maxWidth: .infinity)
        }
        .background(Color.primary.opacity(0.025))
    }
}

private struct ContinuePracticeCard: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 24) {
            PieceArtwork(title: piece.title, size: 96)

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

struct PieceCard: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        Button {
            store.selectPiece(piece, startPractice: true)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    PieceArtwork(title: piece.title, size: 58)
                    Spacer()
                    Button {
                        store.toggleFavorite(piece.id)
                    } label: {
                        Image(systemName: piece.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(
                                piece.isFavorite ? Color.tempoOrange : .secondary
                            )
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(piece.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(piece.composer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack {
                    Label(piece.collection, systemImage: "doc.text")
                    Spacer()
                    Text(piece.sections.first?.measureLabel ?? "")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .tempoCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
