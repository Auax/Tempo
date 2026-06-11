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
            genre: PieceGenre.classical.rawValue,
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
            genre: PieceGenre.other.rawValue,
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
            genre: PieceGenre.classical.rawValue,
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

    @Test
    func clickingSelectedQuickFilterReturnsToAll() {
        let suiteName = "LibraryStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TempoStore(defaults: defaults, midiService: MIDIService(defaults: defaults))

        store.toggleLibraryQuickFilter(.recent)
        #expect(store.libraryQuickFilter == .recent)

        store.toggleLibraryQuickFilter(.recent)
        #expect(store.libraryQuickFilter == .all)

        store.toggleLibraryQuickFilter(.favorites)
        #expect(store.libraryQuickFilter == .favorites)

        store.toggleLibraryQuickFilter(.all)
        #expect(store.libraryQuickFilter == .all)
    }

    @Test
    func deletePieceRemovesLibraryEntryAndImportedFile() throws {
        let suiteName = "LibraryStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let scoreURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).musicxml")
        try Data("<score-partwise/>".utf8).write(to: scoreURL)
        defer { try? FileManager.default.removeItem(at: scoreURL) }

        let store = TempoStore(defaults: defaults, midiService: MIDIService(defaults: defaults))
        let piece = Piece(
            title: "Temporary Score",
            composer: "",
            collection: "MUSICXML",
            scorePath: scoreURL.path,
            progress: 0,
            bestAccuracy: 0,
            difficulty: PieceDifficulty.easy.rawValue,
            sections: []
        )
        store.pieces = [piece]

        store.deletePiece(piece.id)

        #expect(store.pieces.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: scoreURL.path))
    }

    @Test
    func artworkConfigurationRoundTripsWithPiece() throws {
        let artwork = ScoreArtwork(
            preset: .autumn,
            customImagePath: "/tmp/custom-artwork.png",
            textAlignment: .trailing,
            usesDarkText: true,
            titleScale: 1.12,
            overlayOpacity: 0.08,
            imageOffsetX: -0.25,
            imageOffsetY: 0.4
        )
        let piece = Piece(
            title: "Autumn Leaves",
            composer: "Joseph Kosma",
            collection: "MUSICXML",
            progress: 0,
            bestAccuracy: 0,
            difficulty: PieceDifficulty.easy.rawValue,
            sections: [],
            artwork: artwork,
            artworkNotes: [
                ScoreArtworkNote(position: 0.2, pitch: 64, line: 0),
                ScoreArtworkNote(position: 0.7, pitch: 57, line: 1)
            ]
        )

        let decoded = try JSONDecoder().decode(
            Piece.self,
            from: JSONEncoder().encode(piece)
        )

        #expect(decoded.artwork == artwork)
        #expect(decoded.artworkNotes == piece.artworkNotes)
    }

    @Test
    func editingPieceUpdatesLibraryDetailsAndArtwork() {
        let suiteName = "LibraryStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TempoStore(defaults: defaults, midiService: MIDIService(defaults: defaults))
        let folder = ScoreFolder(name: "Recital")
        let piece = Piece(
            title: "Old Title",
            composer: "Old Composer",
            collection: "MUSICXML",
            progress: 0.4,
            bestAccuracy: 0.9,
            difficulty: PieceDifficulty.easy.rawValue,
            genre: PieceGenre.classical.rawValue,
            sections: [],
            artwork: .default
        )
        store.pieces = [piece]
        store.folders = [folder]

        var artwork = ScoreArtwork.default
        artwork.preset = .autumn
        artwork.textAlignment = .trailing

        store.finishEditing(
            pieceID: piece.id,
            title: "  New Title  ",
            composer: " New Composer ",
            difficulty: .advanced,
            genre: .film,
            folderID: folder.id,
            artwork: artwork,
            customArtworkData: nil
        )

        let edited = store.pieces[0]
        #expect(edited.title == "New Title")
        #expect(edited.composer == "New Composer")
        #expect(edited.difficulty == PieceDifficulty.advanced.rawValue)
        #expect(edited.genre == PieceGenre.film.rawValue)
        #expect(edited.folderID == folder.id)
        #expect(edited.artwork == artwork)
        #expect(edited.progress == piece.progress)
        #expect(edited.bestAccuracy == piece.bestAccuracy)
    }

}
