import Foundation
import Observation

@MainActor
@Observable
final class TempoStore {
    var destination: AppDestination = .home
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
    var pendingImport: PendingScoreImport?
    var showingNewFolder = false
    var showingPairing = false
    var showingMIDIConnection = false
    var showingSessionReview = false

    var sidebarHidden: Bool {
        didSet { defaults.set(sidebarHidden, forKey: Keys.sidebarHidden) }
    }
    var inspectorVisible: Bool {
        didSet { defaults.set(inspectorVisible, forKey: Keys.inspectorVisible) }
    }
    var focusMode = false
    var activeNotes: [Int: NoteFeedback] = [:]
    var activeScoreFeedback: [String: NoteFeedback] = [:]
    var metrics = SessionMetrics()
    var pieces: [Piece]
    var folders: [ScoreFolder]
    var searchText = ""
    var librarySection: LibrarySection = .allScores
    var libraryQuickFilter: LibraryQuickFilter = .all
    var librarySort: LibrarySort = .lastOpened
    var selectedDifficulties: Set<String> = []
    var selectedGenres: Set<String> = []
    var parsedScore: ParsedScore?
    var scoreError: String?

    let midiService: MIDIService

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private lazy var playbackService = PianoPlaybackService()
    @ObservationIgnored private var beatAccumulator = 0.0
    @ObservationIgnored private var targetBeat = 0.0
    @ObservationIgnored private var hitNotesForTarget: Set<Int> = []
    @ObservationIgnored private var chordGraceStartedAt: Date?
    @ObservationIgnored private var lastTickAt: Date?
    @ObservationIgnored private var lastMetronomeBeat = -1

    private static let chordGracePeriod: TimeInterval = 0.45

    init(defaults: UserDefaults = .standard, midiService: MIDIService? = nil) {
        self.defaults = defaults
        self.sidebarHidden = defaults.object(forKey: Keys.sidebarHidden) as? Bool
            ?? defaults.bool(forKey: Keys.sidebarCollapsed)
        self.inspectorVisible = defaults.object(forKey: Keys.inspectorVisible) as? Bool ?? true
        self.pieces = Self.loadPieces(defaults: defaults)
        self.folders = Self.loadFolders(defaults: defaults)
        self.midiService = midiService ?? MIDIService()

        self.midiService.onNote = { [weak self] note, velocity in
            self?.receive(note: note, velocity: velocity)
        }
        self.midiService.onNoteOff = { [weak self] note in
            self?.release(note: note)
        }
    }

    var selectedPiece: Piece? {
        pieces.first(where: { $0.id == selectedPieceID })
    }

    var recentlyPracticedPiece: Piece? {
        pieces.max(by: { $0.lastPracticed < $1.lastPracticed })
    }

    var selectedSection: PracticeSection? {
        selectedPiece?.sections.first(where: { $0.id == selectedSectionID })
    }

    var filteredPieces: [Piece] {
        var result = pieces

        switch libraryQuickFilter {
        case .all:
            break
        case .recent:
            result = result.filter { Calendar.current.dateComponents(
                [.day],
                from: $0.lastPracticed,
                to: .now
            ).day ?? 0 <= 30 }
        case .favorites:
            result = result.filter(\.isFavorite)
        }

        if !selectedDifficulties.isEmpty {
            result = result.filter { selectedDifficulties.contains($0.difficulty) }
        }
        if !selectedGenres.isEmpty {
            result = result.filter { selectedGenres.contains($0.genre) }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.composer.localizedCaseInsensitiveContains(searchText)
                    || $0.genre.localizedCaseInsensitiveContains(searchText)
                    || $0.difficulty.localizedCaseInsensitiveContains(searchText)
            }
        }

        return sortedPieces(result)
    }

    func sortedPieces(_ pieces: [Piece]) -> [Piece] {
        switch librarySort {
        case .lastOpened:
            pieces.sorted { $0.lastPracticed > $1.lastPracticed }
        case .recentlyAdded:
            pieces.sorted { $0.addedAt > $1.addedAt }
        case .title:
            pieces.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .composer:
            pieces.sorted {
                let comparison = $0.composer.localizedCaseInsensitiveCompare($1.composer)
                return comparison == .orderedSame
                    ? $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    : comparison == .orderedAscending
            }
        }
    }

    func pieces(in folder: ScoreFolder) -> [Piece] {
        sortedPieces(pieces.filter { $0.folderID == folder.id })
    }

    func pieces(by composer: String) -> [Piece] {
        sortedPieces(pieces.filter {
            $0.composer.localizedCaseInsensitiveCompare(composer) == .orderedSame
        })
    }

    var composers: [String] {
        Array(Set(pieces.map(\.composer).filter { !$0.isEmpty }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func composerSuggestions(for query: String) -> [String] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Array(composers.prefix(5))
        }
        return composers.filter {
            $0.localizedCaseInsensitiveContains(query)
        }
        .prefix(5)
        .map { $0 }
    }

    func pieceCount(in folder: ScoreFolder) -> Int {
        pieces.filter { $0.folderID == folder.id }.count
    }

    func pieceCount(by composer: String) -> Int {
        pieces.filter {
            $0.composer.localizedCaseInsensitiveCompare(composer) == .orderedSame
        }.count
    }

    var expectedEvents: [ScoreNoteEvent] {
        guard let parsedScore else { return [] }
        let selectable = parsedScore.events.filter(matchesSelectedHand)
        guard !selectable.isEmpty else { return [] }

        let positionBeat: Double
        switch practiceMode {
        case .guided where !isPlaying:
            positionBeat = targetBeat
        case .guided, .section, .performance:
            guard let activeStart = ScoreTimeline.activeStartBeat(at: currentBeat, in: selectable) else {
                return []
            }
            positionBeat = activeStart
        }

        return ScoreTimeline.events(atStartBeat: positionBeat, in: selectable)
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

    var nowPlayingScoreNotes: [String: PianoHand] {
        guard isPlaying, let parsedScore else { return [:] }
        let sounding = parsedScore.events.filter {
            matchesSelectedHand($0) && ScoreTimeline.isSounding($0, at: currentBeat)
        }
        return Dictionary(
            sounding.map { ($0.id, $0.hand) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    var hasSessionData: Bool {
        metrics.totalNotes > 0 || metrics.practicedSeconds > 0
    }

    func selectPiece(_ piece: Piece, startPractice: Bool = false) {
        playbackService.stopAll()
        isPlaying = false
        selectedPieceID = piece.id
        if let index = pieces.firstIndex(where: { $0.id == piece.id }) {
            pieces[index].lastPracticed = .now
            persistPieces()
        }
        selectedSectionID = piece.sections.first?.id
        metrics.reset()
        loadSelectedScore()
        resetPracticePosition(from: parsedScore?.beat(atMeasure: selectedSection?.startMeasure ?? 1) ?? 0)
        if startPractice {
            destination = .library
            isPracticeWorkspacePresented = true
        }
    }

    func openDestination(_ destination: AppDestination) {
        self.destination = destination
        isPracticeWorkspacePresented = false
    }

    func clearLibraryFilters() {
        libraryQuickFilter = .all
        selectedDifficulties.removeAll()
        selectedGenres.removeAll()
    }

    func movePiece(_ pieceID: Piece.ID, to folderID: ScoreFolder.ID?) {
        guard let index = pieces.firstIndex(where: { $0.id == pieceID }) else { return }
        pieces[index].folderID = folderID
        persistPieces()
    }

    func toggleFavorite(_ pieceID: Piece.ID) {
        guard let index = pieces.firstIndex(where: { $0.id == pieceID }) else { return }
        pieces[index].isFavorite.toggle()
        persistPieces()
    }

    func prepareImport(_ url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard
            let storedURL = copyToScoreLibrary(url),
            let parsed = try? MusicXMLScoreParser.parse(url: storedURL)
        else {
            scoreError = "This file could not be imported as MusicXML."
            return
        }

        pendingImport = PendingScoreImport(
            storedURL: storedURL,
            originalFileName: url.lastPathComponent,
            parsedScore: parsed
        )
    }

    func finishImport(
        title: String,
        composer: String,
        difficulty: PieceDifficulty,
        genre: PieceGenre,
        folderID: ScoreFolder.ID?
    ) {
        guard let pendingImport else { return }
        let parsed = pendingImport.parsedScore
        let piece = Piece(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            composer: composer.trimmingCharacters(in: .whitespacesAndNewlines),
            collection: pendingImport.storedURL.pathExtension.uppercased(),
            fileName: pendingImport.originalFileName,
            scorePath: pendingImport.storedURL.path,
            progress: 0,
            bestAccuracy: 0,
            difficulty: difficulty.rawValue,
            genre: genre.rawValue,
            folderID: folderID,
            sections: [
                PracticeSection(
                    name: "Full score",
                    startMeasure: 1,
                    endMeasure: max(parsed.measureCount, 1),
                    mastery: 0
                )
            ]
        )
        pieces.insert(piece, at: 0)
        self.pendingImport = nil
        persistPieces()
        selectPiece(piece)
        destination = .library
        isPracticeWorkspacePresented = false
    }

    func cancelImport() {
        guard let pendingImport else { return }
        try? FileManager.default.removeItem(at: pendingImport.storedURL)
        self.pendingImport = nil
    }

    func createFolder(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            !folders.contains(where: {
                $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
            })
        else {
            return
        }
        folders.append(ScoreFolder(name: trimmed))
        folders.sort {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        persistFolders()
    }

    func playPause() {
        guard let parsedScore else { return }
        isPlaying.toggle()

        if isPlaying {
            if practiceMode == .guided {
                currentBeat = targetBeat
                currentMeasure = parsedScore.measure(at: targetBeat)
            }
            if currentBeat >= parsedScore.durationBeats {
                resetPracticePosition(from: parsedScore.beat(atMeasure: selectedSection?.startMeasure ?? 1))
            }
            lastTickAt = nil
            resetMetronomeCursor(before: currentBeat)
            playbackService.resetSyncCursor()
        } else if practiceMode == .guided {
            syncPracticeTargetToPlaybackPosition()
        }

        syncPlayback()
    }

    func goToStart() {
        playbackService.stopAll()
        if practiceMode == .guided {
            resetPracticePosition(from: 0)
        } else {
            currentBeat = 0
            currentMeasure = 1
            playbackService.resetSyncCursor()
        }
        lastTickAt = nil
        activeNotes.removeAll()
        activeScoreFeedback.removeAll()
        resetMetronomeCursor(before: currentBeat)
        syncPlayback()
    }

    func restartSection() {
        playbackService.stopAll()
        let sectionStart = parsedScore?.beat(atMeasure: selectedSection?.startMeasure ?? 1) ?? 0
        resetPracticePosition(from: sectionStart)
        activeNotes.removeAll()
        activeScoreFeedback.removeAll()
        resetMetronomeCursor(before: currentBeat)
    }

    func skipForward() {
        guard let parsedScore else { return }
        let nextMeasure = min(currentMeasure + 1, parsedScore.measureCount)
        let nextBeat = parsedScore.beat(atMeasure: nextMeasure)
        if practiceMode == .guided {
            resetPracticePosition(from: nextBeat)
        } else {
            currentBeat = nextBeat
            currentMeasure = nextMeasure
            playbackService.resetSyncCursor()
        }
        activeNotes.removeAll()
        activeScoreFeedback.removeAll()
        resetMetronomeCursor(before: currentBeat)
        syncPlayback()
    }

    func skipBackward() {
        guard let parsedScore else { return }
        let previousMeasure = max(currentMeasure - 1, 1)
        let previousBeat = parsedScore.beat(atMeasure: previousMeasure)
        if practiceMode == .guided {
            resetPracticePosition(from: previousBeat)
        } else {
            currentBeat = previousBeat
            currentMeasure = previousMeasure
            playbackService.resetSyncCursor()
        }
        activeNotes.removeAll()
        activeScoreFeedback.removeAll()
        resetMetronomeCursor(before: currentBeat)
        syncPlayback()
    }

    func tick(interval: TimeInterval = 0.02) {
        if practiceMode == .guided, !isPlaying {
            checkChordGraceTimeout()
            lastTickAt = nil
            return
        }

        guard isPlaying else {
            lastTickAt = nil
            return
        }
        guard let parsedScore else {
            isPlaying = false
            lastTickAt = nil
            return
        }

        // Advance by real elapsed wall-clock time so the tempo is accurate
        // regardless of timer jitter (prevents notes bunching up / rushing).
        let now = Date()
        let elapsed = lastTickAt.map { now.timeIntervalSince($0) } ?? interval
        lastTickAt = now
        let delta = min(max(elapsed, 0), 0.25)

        metrics.practicedSeconds += delta
        currentBeat += delta * Double(tempo) / 60
        currentMeasure = parsedScore.measure(at: currentBeat)

        if isLoopEnabled, let section = selectedSection, currentMeasure > section.endMeasure {
            let loopStart = parsedScore.beat(atMeasure: section.startMeasure)
            currentBeat = loopStart
            currentMeasure = section.startMeasure
            playbackService.resetSyncCursor()
            resetMetronomeCursor(before: loopStart)
        } else if currentBeat >= parsedScore.durationBeats {
            isPlaying = false
            lastTickAt = nil
            playbackService.stopAll()
            if practiceMode == .guided {
                syncPracticeTargetToPlaybackPosition()
            }
        }
        syncMetronome()
        syncPlayback()
    }

    private func syncMetronome() {
        guard isMetronomeEnabled, isPlaying else { return }
        let beat = Int(floor(currentBeat))
        guard beat > lastMetronomeBeat else { return }
        lastMetronomeBeat = beat
        playbackService.metronomeClick()
    }

    private func resetMetronomeCursor(before beat: Double) {
        lastMetronomeBeat = Int(floor(beat)) - 1
    }

    func receive(note: Int, velocity: Int = 80, previewSound: Bool = false) {
        guard velocity > 0 else { return }
        if previewSound {
            playbackService.preview(note: note, velocity: velocity)
        }

        let targets = expectedEvents
        let matches = targets.filter { $0.midiNote == note }
        let isCorrect = !matches.isEmpty
        activeNotes[note] = isCorrect ? .correct : .incorrect
        metrics.register(correct: isCorrect)

        if isCorrect {
            for event in matches {
                activeScoreFeedback[event.id] = .correct
            }

            if practiceMode == .guided, !isPlaying {
                registerGuidedHit(note: note)
            }
        }

        if previewSound {
            Task {
                try? await Task.sleep(for: .milliseconds(480))
                clearFeedback(for: note, matches: matches)
            }
        }
    }

    func release(note: Int) {
        guard practiceMode != .guided else { return }
        let matches = expectedEvents.filter { $0.midiNote == note }
        clearFeedback(for: note, matches: matches)
    }

    private func clearFeedback(for note: Int, matches: [ScoreNoteEvent]) {
        activeNotes[note] = nil
        for event in matches {
            activeScoreFeedback[event.id] = nil
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

    private func persistFolders() {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        defaults.set(data, forKey: Keys.folders)
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
            resetPracticePosition(from: currentBeat)

            if let index = pieces.firstIndex(where: { $0.id == selectedPieceID }) {
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

    private func resetPracticePosition(from beat: Double) {
        let selectable = parsedScore?.events.filter(matchesSelectedHand) ?? []
        let startBeat = ScoreTimeline.firstStartBeat(from: beat, in: selectable) ?? beat
        targetBeat = startBeat
        currentBeat = startBeat
        currentMeasure = parsedScore?.measure(at: startBeat) ?? 1
        hitNotesForTarget.removeAll()
        chordGraceStartedAt = nil
        beatAccumulator = 0
        playbackService.resetSyncCursor()
    }

    private func registerGuidedHit(note: Int) {
        guard !hitNotesForTarget.contains(note) else { return }
        hitNotesForTarget.insert(note)
        if chordGraceStartedAt == nil {
            chordGraceStartedAt = Date()
        }
        tryCompleteTargetGroup()
    }

    private func tryCompleteTargetGroup() {
        let expectedNotes = Set(expectedEvents.map(\.midiNote))
        guard !expectedNotes.isEmpty, expectedNotes.isSubset(of: hitNotesForTarget) else { return }
        advanceToNextTarget()
    }

    private func advanceToNextTarget() {
        guard let parsedScore else { return }
        let selectable = parsedScore.events.filter(matchesSelectedHand)
        guard let nextBeat = ScoreTimeline.nextStartBeat(after: targetBeat, in: selectable) else {
            isPlaying = false
            playbackService.stopAll()
            clearTargetFeedback()
            return
        }

        targetBeat = nextBeat
        currentBeat = nextBeat
        currentMeasure = parsedScore.measure(at: nextBeat)
        clearTargetFeedback()
        playbackService.resetSyncCursor()
        syncPlayback()
    }

    private func clearTargetFeedback() {
        hitNotesForTarget.removeAll()
        chordGraceStartedAt = nil
        activeNotes.removeAll()
        activeScoreFeedback.removeAll()
    }

    private func syncPracticeTargetToPlaybackPosition() {
        guard practiceMode == .guided, let parsedScore else { return }
        let selectable = parsedScore.events.filter(matchesSelectedHand)
        if let activeStart = ScoreTimeline.activeStartBeat(at: currentBeat, in: selectable) {
            targetBeat = activeStart
        } else if let nextBeat = ScoreTimeline.firstStartBeat(from: currentBeat, in: selectable) {
            targetBeat = nextBeat
        } else {
            targetBeat = currentBeat
        }
        clearTargetFeedback()
    }

    private func checkChordGraceTimeout() {
        guard practiceMode == .guided,
              let startedAt = chordGraceStartedAt,
              !expectedEvents.isEmpty
        else {
            return
        }

        let expectedNotes = Set(expectedEvents.map(\.midiNote))
        guard !expectedNotes.isSubset(of: hitNotesForTarget) else { return }
        guard Date().timeIntervalSince(startedAt) >= Self.chordGracePeriod else { return }

        hitNotesForTarget.removeAll()
        chordGraceStartedAt = nil
        for note in expectedNotes {
            activeNotes[note] = nil
        }
        for event in expectedEvents {
            activeScoreFeedback[event.id] = nil
        }
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
            let destination = scoresDirectory.appendingPathComponent(
                "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
            )
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

    private static func loadFolders(defaults: UserDefaults) -> [ScoreFolder] {
        guard
            let data = defaults.data(forKey: Keys.folders),
            let folders = try? JSONDecoder().decode([ScoreFolder].self, from: data)
        else {
            return []
        }
        return folders
    }

    private enum Keys {
        static let pieces = "tempo.pieces"
        static let folders = "tempo.folders"
        static let sidebarHidden = "tempo.sidebarHidden"
        static let sidebarCollapsed = "tempo.sidebarCollapsed"
        static let inspectorVisible = "tempo.inspectorVisible"
    }
}
