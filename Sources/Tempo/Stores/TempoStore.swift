import Foundation
import Observation

@MainActor
@Observable
final class TempoStore {
    var destination: AppDestination = .library
    var isPracticeWorkspacePresented = false
    var selectedPieceID: Piece.ID?
    var selectedSectionID: PracticeSection.ID?
    var practiceMode: PracticeMode = .guided
    var handSelection: HandSelection = .both

    var isPlaying = false
    var isMetronomeEnabled = true
    var isLoopEnabled = true
    var tempo = 66
    var scoreZoom = 1.0
    var currentBeat = 0.0
    var currentMeasure = 1
    var showingImporter = false
    var showingPairing = false
    var showingSessionReview = false

    var sidebarCollapsed: Bool {
        didSet { defaults.set(sidebarCollapsed, forKey: Keys.sidebarCollapsed) }
    }
    var inspectorVisible: Bool {
        didSet { defaults.set(inspectorVisible, forKey: Keys.inspectorVisible) }
    }
    var focusMode = false
    var activeNotes: [Int: NoteFeedback] = [:]
    var activeScoreFeedback: [String: NoteFeedback] = [:]
    var metrics = SessionMetrics()
    var pieces: [Piece]
    var searchText = ""
    var parsedScore: ParsedScore?
    var scoreError: String?

    let midiService: MIDIService

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let playbackService = PianoPlaybackService()
    @ObservationIgnored private var beatAccumulator = 0.0

    init(defaults: UserDefaults = .standard, midiService: MIDIService? = nil) {
        self.defaults = defaults
        self.sidebarCollapsed = defaults.bool(forKey: Keys.sidebarCollapsed)
        self.inspectorVisible = defaults.object(forKey: Keys.inspectorVisible) as? Bool ?? true
        self.pieces = Self.loadPieces(defaults: defaults)
        self.midiService = midiService ?? MIDIService()

        selectedPieceID = pieces.first?.id
        selectedSectionID = pieces.first?.sections.first?.id
        isPracticeWorkspacePresented = selectedPieceID != nil
        loadSelectedScore()

        self.midiService.onNote = { [weak self] note, velocity in
            self?.receive(note: note, velocity: velocity)
        }
    }

    var selectedPiece: Piece? {
        pieces.first(where: { $0.id == selectedPieceID })
    }

    var selectedSection: PracticeSection? {
        selectedPiece?.sections.first(where: { $0.id == selectedSectionID })
    }

    var filteredPieces: [Piece] {
        let destinationFiltered: [Piece]
        switch destination {
        case .favorites:
            destinationFiltered = pieces.filter(\.isFavorite)
        case .recent:
            destinationFiltered = pieces.sorted { $0.lastPracticed > $1.lastPracticed }
        default:
            destinationFiltered = pieces
        }

        guard !searchText.isEmpty else { return destinationFiltered }
        return destinationFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.composer.localizedCaseInsensitiveContains(searchText)
        }
    }

    var expectedEvents: [ScoreNoteEvent] {
        guard let parsedScore else { return [] }
        let selectable = parsedScore.events.filter(matchesSelectedHand)
        let active = selectable.filter {
            $0.startBeat <= currentBeat + 0.04 && $0.endBeat > currentBeat - 0.04
        }
        if !active.isEmpty {
            return active
        }
        guard let nextBeat = selectable.first(where: { $0.startBeat >= currentBeat })?.startBeat else {
            return []
        }
        return selectable.filter { abs($0.startBeat - nextBeat) < 0.001 }
    }

    var expectedNotesByHand: [Int: PianoHand] {
        Dictionary(
            expectedEvents.map { ($0.midiNote, $0.hand) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var expectedScoreNotes: [String: PianoHand] {
        Dictionary(uniqueKeysWithValues: expectedEvents.map { ($0.id, $0.hand) })
    }

    var hasSessionData: Bool {
        metrics.totalNotes > 0 || metrics.practicedSeconds > 0
    }

    func selectPiece(_ piece: Piece, startPractice: Bool = false) {
        playbackService.stopAll()
        isPlaying = false
        selectedPieceID = piece.id
        selectedSectionID = piece.sections.first?.id
        currentBeat = 0
        currentMeasure = 1
        metrics.reset()
        loadSelectedScore()
        if startPractice {
            destination = .library
            isPracticeWorkspacePresented = true
        }
    }

    func openDestination(_ destination: AppDestination) {
        self.destination = destination
        isPracticeWorkspacePresented = false
    }

    func toggleFavorite(_ pieceID: Piece.ID) {
        guard let index = pieces.firstIndex(where: { $0.id == pieceID }) else { return }
        pieces[index].isFavorite.toggle()
        persistPieces()
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            let canAccess = url.startAccessingSecurityScopedResource()
            defer {
                if canAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let storedURL = copyToScoreLibrary(url)
            let parsed = storedURL.flatMap { try? MusicXMLScoreParser.parse(url: $0) }
            let title = parsed?.title ?? url.deletingPathExtension().lastPathComponent
            let measureCount = max(parsed?.measureCount ?? 1, 1)
            let piece = Piece(
                title: title,
                composer: parsed?.composer ?? "",
                collection: url.pathExtension.uppercased(),
                fileName: url.lastPathComponent,
                scorePath: storedURL?.path,
                progress: 0,
                bestAccuracy: 0,
                difficulty: "Unrated",
                sections: [
                    PracticeSection(
                        name: "Full score",
                        startMeasure: 1,
                        endMeasure: measureCount,
                        mastery: 0
                    )
                ]
            )
            pieces.insert(piece, at: 0)
            selectPiece(piece, startPractice: true)
        }
        persistPieces()
    }

    func playPause() {
        guard parsedScore != nil else { return }
        isPlaying.toggle()
        if isPlaying, currentBeat >= (parsedScore?.durationBeats ?? 0) {
            currentBeat = 0
            currentMeasure = 1
        }
        playbackService.sync(
            events: parsedScore?.events ?? [],
            at: currentBeat,
            isPlaying: isPlaying
        )
    }

    func restartSection() {
        playbackService.stopAll()
        currentBeat = parsedScore?.beat(atMeasure: selectedSection?.startMeasure ?? 1) ?? 0
        currentMeasure = selectedSection?.startMeasure ?? 1
        activeNotes.removeAll()
        activeScoreFeedback.removeAll()
    }

    func skipForward() {
        let nextMeasure = min(currentMeasure + 1, parsedScore?.measureCount ?? currentMeasure)
        currentBeat = parsedScore?.beat(atMeasure: nextMeasure) ?? currentBeat
        currentMeasure = nextMeasure
        syncPlayback()
    }

    func skipBackward() {
        let previousMeasure = max(currentMeasure - 1, 1)
        currentBeat = parsedScore?.beat(atMeasure: previousMeasure) ?? 0
        currentMeasure = previousMeasure
        syncPlayback()
    }

    func tick(interval: TimeInterval = 0.05) {
        guard isPlaying else { return }
        guard let parsedScore else {
            isPlaying = false
            return
        }

        metrics.practicedSeconds += interval
        beatAccumulator += interval * Double(tempo) / 60

        if beatAccumulator >= 0.02 {
            currentBeat += beatAccumulator
            beatAccumulator = 0
            currentMeasure = parsedScore.measure(at: currentBeat)

            if isLoopEnabled, let section = selectedSection, currentMeasure > section.endMeasure {
                currentBeat = parsedScore.beat(atMeasure: section.startMeasure)
                currentMeasure = section.startMeasure
            } else if currentBeat >= parsedScore.durationBeats {
                isPlaying = false
                playbackService.stopAll()
            }
            syncPlayback()
        }
    }

    func receive(note: Int, velocity: Int = 80, previewSound: Bool = false) {
        guard velocity > 0 else { return }
        if previewSound {
            playbackService.preview(note: note, velocity: velocity)
        }

        let matches = expectedEvents.filter { $0.midiNote == note }
        let isCorrect = !matches.isEmpty
        activeNotes[note] = isCorrect ? .correct : .incorrect
        metrics.register(correct: isCorrect)
        for event in matches {
            activeScoreFeedback[event.id] = .correct
        }

        Task {
            try? await Task.sleep(for: .milliseconds(480))
            activeNotes[note] = nil
            for event in matches {
                activeScoreFeedback[event.id] = nil
            }
        }
    }

    func resetSession() {
        isPlaying = false
        metrics.reset()
        restartSection()
    }

    func toggleFocusMode() {
        focusMode.toggle()
    }

    private func persistPieces() {
        guard let data = try? JSONEncoder().encode(pieces) else { return }
        defaults.set(data, forKey: Keys.pieces)
    }

    private func loadSelectedScore() {
        parsedScore = nil
        scoreError = nil
        guard let path = selectedPiece?.scorePath else {
            scoreError = "Import a MusicXML score to begin."
            return
        }

        do {
            let parsed = try MusicXMLScoreParser.parse(url: URL(fileURLWithPath: path))
            parsedScore = parsed
            if let parsedTempo = parsed.tempo {
                tempo = min(max(parsedTempo, 30), 180)
            }
            currentMeasure = parsed.measure(at: currentBeat)

            if let index = pieces.firstIndex(where: { $0.id == selectedPieceID }) {
                if let title = parsed.title, !title.isEmpty {
                    pieces[index].title = title
                }
                if let composer = parsed.composer, !composer.isEmpty {
                    pieces[index].composer = composer
                }
                pieces[index].sections = [
                    PracticeSection(
                        name: "Full score",
                        startMeasure: 1,
                        endMeasure: max(parsed.measureCount, 1),
                        mastery: 0
                    )
                ]
                selectedSectionID = pieces[index].sections.first?.id
                persistPieces()
            }
        } catch {
            scoreError = "This file could not be parsed for playback."
        }
    }

    private func matchesSelectedHand(_ event: ScoreNoteEvent) -> Bool {
        switch handSelection {
        case .both:
            return true
        case .left:
            return event.hand == .left
        case .right:
            return event.hand == .right
        }
    }

    private func syncPlayback() {
        playbackService.sync(
            events: parsedScore?.events ?? [],
            at: currentBeat,
            isPlaying: isPlaying
        )
    }

    private func copyToScoreLibrary(_ sourceURL: URL) -> URL? {
        let fileManager = FileManager.default
        guard
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return nil
        }

        let scoresDirectory = applicationSupport
            .appendingPathComponent("Tempo", isDirectory: true)
            .appendingPathComponent("Scores", isDirectory: true)

        do {
            try fileManager.createDirectory(
                at: scoresDirectory,
                withIntermediateDirectories: true
            )
            let destination = scoresDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: sourceURL, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private static func loadPieces(defaults: UserDefaults) -> [Piece] {
        guard
            let data = defaults.data(forKey: Keys.pieces),
            let pieces = try? JSONDecoder().decode([Piece].self, from: data)
        else {
            return []
        }
        return pieces.filter { piece in
            guard let path = piece.scorePath else { return false }
            return FileManager.default.fileExists(atPath: path)
        }
    }

    private enum Keys {
        static let pieces = "tempo.pieces"
        static let sidebarCollapsed = "tempo.sidebarCollapsed"
        static let inspectorVisible = "tempo.inspectorVisible"
    }
}
