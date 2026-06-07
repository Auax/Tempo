import SwiftUI

struct LibraryView: View {
    @Bindable var store: TempoStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.destination.title)
                        .font(.largeTitle.weight(.semibold))
                    Text("\(store.filteredPieces.count) scores ready to practice")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                TextField("Search music", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 230)

                Button {
                    store.showingImporter = true
                } label: {
                    Label("Import", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.tempoPurple)
            }
            .padding(26)

            Divider()

            if store.filteredPieces.isEmpty {
                ContentUnavailableView {
                    Label("No Scores Found", systemImage: "music.note.list")
                } description: {
                    Text("Import MusicXML, MuseScore, or MIDI, or adjust your search.")
                } actions: {
                    Button("Import Score") {
                        store.showingImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.tempoPurple)
                }
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 250), spacing: 18)],
                        spacing: 18
                    ) {
                        ForEach(store.filteredPieces) { piece in
                            PieceCard(piece: piece, store: store)
                        }
                    }
                    .padding(26)
                }
            }
        }
        .background(Color.primary.opacity(0.025))
    }
}
