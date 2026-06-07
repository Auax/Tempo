import Foundation
import Testing
@testable import Tempo

@MainActor
struct LibraryStoreTests {
    @Test
    func searchFavoritesSortAndComposerSuggestionsCompose() {
        let suiteName = "LibraryStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TempoStore(defaults: defaults, midiService: MIDIService(defaults: defaults))
        let older = Piece(
            title: "Nocturne",
            composer: "Frédéric Chopin",
            collection: "MXL",
            progress: 0,
            bestAccuracy: 0,
            lastPracticed: Date(timeIntervalSince1970: 100),
            isFavorite: true,
            difficulty: PieceDifficulty.intermediate.rawValue,
            genre: PieceGenre.romantic.rawValue,
            addedAt: Date(timeIntervalSince1970: 100),
            sections: []
        )
        let newer = Piece(
            title: "Prelude",
            composer: "Johann Sebastian Bach",
            collection: "MUSICXML",
            progress: 0,
            bestAccuracy: 0,
            lastPracticed: Date(timeIntervalSince1970: 200),
            difficulty: PieceDifficulty.easy.rawValue,
            genre: PieceGenre.baroque.rawValue,
            addedAt: Date(timeIntervalSince1970: 200),
            sections: []
        )
        store.pieces = [older, newer]

        store.searchText = "chop"
        #expect(store.filteredPieces.map(\.title) == ["Nocturne"])

        store.searchText = ""
        store.libraryQuickFilter = .favorites
        #expect(store.filteredPieces.map(\.title) == ["Nocturne"])

        store.libraryQuickFilter = .all
        store.librarySort = .recentlyAdded
        #expect(store.filteredPieces.map(\.title) == ["Prelude", "Nocturne"])
        #expect(store.composerSuggestions(for: "Chop") == ["Frédéric Chopin"])
    }

    @Test
    func movePieceUpdatesFolderMembership() {
        let suiteName = "LibraryStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TempoStore(defaults: defaults, midiService: MIDIService(defaults: defaults))
        let folder = ScoreFolder(name: "Etudes")
        store.folders = [folder]
        let piece = Piece(
            title: "Nocturne",
            composer: "Frédéric Chopin",
            collection: "MXL",
            progress: 0,
            bestAccuracy: 0,
            difficulty: PieceDifficulty.intermediate.rawValue,
            genre: PieceGenre.romantic.rawValue,
            sections: []
        )
        store.pieces = [piece]

        store.movePiece(piece.id, to: folder.id)
        #expect(store.pieces.first?.folderID == folder.id)
        #expect(store.pieceCount(in: folder) == 1)

        store.movePiece(piece.id, to: nil)
        #expect(store.pieces.first?.folderID == nil)
        #expect(store.pieceCount(in: folder) == 0)
    }
}
