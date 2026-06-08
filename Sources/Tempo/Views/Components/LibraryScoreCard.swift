import SwiftUI

struct LibraryScoreCard: View {
    let piece: Piece
    @Bindable var store: TempoStore

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
            ZStack(alignment: .topLeading) {
                Button {
                    store.selectPiece(piece, startPractice: true)
                } label: {
                    ScoreGradientArtwork(piece: piece)
                }
                .buttonStyle(.plain)

                Button {
                    store.toggleFavorite(piece.id)
                } label: {
                    Image(systemName: piece.isFavorite ? "star.fill" : "star")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            piece.isFavorite ? Color.tempoOrange : .white.opacity(0.75)
                        )
                        .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
                        .padding(9)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

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
    @State private var isConfirmingDeletion = false

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

            Divider()

            Button(role: .destructive) {
                isConfirmingDeletion = true
            } label: {
                Label("Delete Score", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
                .frame(width: TempoTheme.Spacing.xLarge, height: TempoTheme.Spacing.xLarge)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .alert(
            "Delete “\(piece.title)”?",
            isPresented: $isConfirmingDeletion
        ) {
            Button("Delete", role: .destructive) {
                store.deletePiece(piece.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the score and its imported file. This action cannot be undone.")
        }
    }
}
