#if DEBUG
import Foundation

@MainActor
enum PreviewFixtures {
    static let folder = ScoreFolder(
        id: UUID(uuidString: "F0000000-0000-0000-0000-000000000001")!,
        name: "Recital"
    )

    static let piece = Piece(
        id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!,
        title: "Clair de lune",
        composer: "Claude Debussy",
        collection: "Suite bergamasque",
        fileName: "clair-de-lune.musicxml",
        progress: 0.68,
        bestAccuracy: 0.91,
        lastPracticed: Date.now.addingTimeInterval(-3_600),
        isFavorite: true,
        difficulty: PieceDifficulty.intermediate.rawValue,
        genre: PieceGenre.classical.rawValue,
        folderID: folder.id,
        sections: [
            PracticeSection(
                name: "Opening",
                startMeasure: 1,
                endMeasure: 8,
                mastery: 0.82
            ),
            PracticeSection(
                name: "Middle",
                startMeasure: 9,
                endMeasure: 18,
                mastery: 0.54
            )
        ]
    )

    static let secondPiece = Piece(
        id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002")!,
        title: "Gymnopedie No. 1",
        composer: "Erik Satie",
        collection: "Trois Gymnopedies",
        progress: 0.34,
        bestAccuracy: 0.79,
        lastPracticed: Date.now.addingTimeInterval(-86_400),
        difficulty: PieceDifficulty.easy.rawValue,
        genre: PieceGenre.classical.rawValue,
        sections: [
            PracticeSection(
                name: "Full score",
                startMeasure: 1,
                endMeasure: 16,
                mastery: 0.34
            )
        ]
    )

    static let parsedScore = ParsedScore(
        xml: """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="4.0">
          <work><work-title>Clair de lune</work-title></work>
          <identification><creator type="composer">Claude Debussy</creator></identification>
          <part-list>
            <score-part id="P1"><part-name>Piano</part-name></score-part>
          </part-list>
          <part id="P1">
            <measure number="1">
              <attributes>
                <divisions>1</divisions>
                <key><fifths>0</fifths></key>
                <time><beats>4</beats><beat-type>4</beat-type></time>
                <clef><sign>G</sign><line>2</line></clef>
              </attributes>
              <note>
                <pitch><step>C</step><octave>4</octave></pitch>
                <duration>4</duration><type>whole</type>
              </note>
            </measure>
          </part>
        </score-partwise>
        """,
        events: [
            ScoreNoteEvent(
                id: "preview-note-c4",
                midiNote: 60,
                startBeat: 0,
                duration: 4,
                measure: 1,
                hand: .right
            )
        ],
        measureStartBeats: [1: 0],
        measureDurations: [1: 4],
        title: "Clair de lune",
        composer: "Claude Debussy",
        tempo: 66
    )

    static var pendingImport: PendingScoreImport {
        PendingScoreImport(
            storedURL: URL(fileURLWithPath: "/tmp/clair-de-lune.musicxml"),
            originalFileName: "clair-de-lune.musicxml",
            parsedScore: parsedScore
        )
    }

    static func store(
        practicing: Bool = false,
        withSession: Bool = false
    ) -> TempoStore {
        let suiteName = "TempoPreview-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let midiService = MIDIService(defaults: defaults)
        let store = TempoStore(defaults: defaults, midiService: midiService)
        store.pieces = [piece, secondPiece]
        store.folders = [folder]
        store.selectedPieceID = piece.id
        store.selectedSectionID = piece.sections.first?.id
        store.parsedScore = parsedScore
        store.currentMeasure = 1
        store.isPracticeWorkspacePresented = practicing
        store.activeNotes = [60: .correct, 64: .incorrect]

        if withSession {
            store.metrics = SessionMetrics(
                correctNotes: 42,
                mistakes: 5,
                missedNotes: 2,
                extraNotes: 1,
                rhythm: 0.88,
                practicedSeconds: 754,
                longestStreak: 18,
                currentStreak: 6
            )
        }

        return store
    }
}
#endif
