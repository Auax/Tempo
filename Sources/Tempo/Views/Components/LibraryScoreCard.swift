import SwiftUI

struct LibraryScoreCard: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
            Button {
                store.selectPiece(piece, startPractice: true)
            } label: {
                ScoreGradientArtwork(piece: piece)
            }
            .buttonStyle(.plain)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                    Text(piece.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(piece.composer.isEmpty ? "Unknown composer" : piece.composer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: TempoTheme.Spacing.xSmall)
                LibraryPieceMenu(piece: piece, store: store)
            }

            Text("\(piece.difficulty)  •  \(piece.genre)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(TempoTheme.Spacing.large)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: TempoTheme.Radius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: TempoTheme.Radius.medium)
                .stroke(.primary.opacity(0.08))
        }
    }
}

struct LibraryPieceMenu: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        Menu {
            Button {
                store.toggleFavorite(piece.id)
            } label: {
                Label(
                    piece.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: piece.isFavorite ? "star.slash" : "star"
                )
            }

            if !store.folders.isEmpty {
                Menu("Move to Folder") {
                    if piece.folderID != nil {
                        Button("Remove from Folder") {
                            store.movePiece(piece.id, to: nil)
                        }
                    }
                    ForEach(store.folders) { folder in
                        Button(folder.name) {
                            store.movePiece(piece.id, to: folder.id)
                        }
                        .disabled(piece.folderID == folder.id)
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
                .frame(width: TempoTheme.Spacing.xLarge, height: TempoTheme.Spacing.xLarge)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
