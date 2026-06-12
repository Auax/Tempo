import AppKit
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
    func previewImagePathRoundTripsWithPiece() throws {
        let piece = Piece(
            title: "Autumn Leaves",
            composer: "Joseph Kosma",
            collection: "MUSICXML",
            previewImagePath: "/tmp/score-preview.png",
            progress: 0,
            bestAccuracy: 0,
            difficulty: PieceDifficulty.easy.rawValue,
            sections: []
        )

        let decoded = try JSONDecoder().decode(
            Piece.self,
            from: JSONEncoder().encode(piece)
        )

        #expect(decoded.previewImagePath == piece.previewImagePath)
    }

    @Test
    func scorePreviewRendererWritesLoadableImage() async {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <part-list>
            <score-part id="P1"><part-name>Piano</part-name></score-part>
          </part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>1</divisions>
                <time><beats>4</beats><beat-type>4</beat-type></time>
                <clef><sign>G</sign><line>2</line></clef>
              </attributes>
              <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>4</duration>
                <type>whole</type>
              </note>
            </measure>
          </part>
        </score-partwise>
        """
        let identifier = UUID()
        let previewURL = await ScorePreviewRenderer.renderAndSave(
            xml: xml,
            identifier: identifier
        )
        defer {
            if let previewURL {
                try? FileManager.default.removeItem(at: previewURL)
            }
        }

        #expect(previewURL?.lastPathComponent.hasSuffix("-preview-v5.png") == true)
        #expect(previewURL.flatMap(NSImage.init(contentsOf:)) != nil)
        if let previewURL,
           let data = try? Data(contentsOf: previewURL),
           let bitmap = NSBitmapImageRep(data: data) {
            #expect(bitmap.pixelsHigh > bitmap.pixelsWide)
            let hasVisibleInk = stride(from: 0, to: bitmap.pixelsHigh, by: 4).contains {
                y in
                stride(from: 0, to: bitmap.pixelsWide, by: 4).contains { x in
                    guard let color = bitmap.colorAt(x: x, y: y) else { return false }
                    return color.redComponent < 0.8
                        || color.greenComponent < 0.8
                        || color.blueComponent < 0.8
                }
            }
            #expect(hasVisibleInk)
        } else {
            Issue.record("The saved score preview could not be inspected.")
        }
    }

    @Test
    func editingPieceUpdatesLibraryDetails() {
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
            sections: []
        )
        store.pieces = [piece]
        store.folders = [folder]

        store.finishEditing(
            pieceID: piece.id,
            title: "  New Title  ",
            composer: " New Composer ",
            difficulty: .advanced,
            genre: .film,
            folderID: folder.id
        )

        let edited = store.pieces[0]
        #expect(edited.title == "New Title")
        #expect(edited.composer == "New Composer")
        #expect(edited.difficulty == PieceDifficulty.advanced.rawValue)
        #expect(edited.genre == PieceGenre.film.rawValue)
        #expect(edited.folderID == folder.id)
        #expect(edited.progress == piece.progress)
        #expect(edited.bestAccuracy == piece.bestAccuracy)
    }

}
