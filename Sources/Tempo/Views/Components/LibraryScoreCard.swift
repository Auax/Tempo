import SwiftUI

struct LibraryScoreCard: View {
    let piece: Piece
    @Bindable var store: TempoStore
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .top) {
            Button {
                store.selectPiece(piece, startPractice: true)
            } label: {
                ScoreArtworkView(
                    title: piece.title,
                    composer: piece.composer,
                    artwork: piece.artwork,
                    difficulty: piece.difficulty,
                    genre: piece.genre,
                    scorePath: piece.scorePath
                )
            }
            .buttonStyle(.plain)

            HStack {
                Button {
                    store.toggleFavorite(piece.id)
                } label: {
                    Image(systemName: piece.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.tempoBlue)
                        .shadow(color: .black.opacity(0.28), radius: 2, x: 0, y: 1)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(piece.isFavorite ? "Remove from Favorites" : "Add to Favorites")
                .opacity(piece.isFavorite || isHovered ? 1 : 0)
                .allowsHitTesting(piece.isFavorite || isHovered)

                Spacer()

                LibraryPieceMenu(piece: piece, store: store)
                    .colorScheme(.dark)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.2), in: Circle())
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(isHovered)
            }
            .padding(10)
        }
        .onHover { hovering in
            withAnimation(TempoTheme.Motion.quick) {
                isHovered = hovering
            }
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

            Button {
                store.editPiece(piece)
            } label: {
                Label("Edit Score", systemImage: "pencil")
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

#if DEBUG
#Preview("Library Score Card") {
    LibraryScoreCard(
        piece: PreviewFixtures.piece,
        store: PreviewFixtures.store()
    )
    .padding()
    .frame(width: 300)
}

#Preview("Library Piece Menu") {
    LibraryPieceMenu(
        piece: PreviewFixtures.piece,
        store: PreviewFixtures.store()
    )
    .padding()
}
#endif
