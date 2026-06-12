import SwiftUI

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
                Menu("Add to Folder") {
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
                .foregroundStyle(Color.white)
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
#Preview("Library Piece Menu") {
    LibraryPieceMenu(
        piece: PreviewFixtures.piece,
        store: PreviewFixtures.store()
    )
    .padding()
}
#endif
