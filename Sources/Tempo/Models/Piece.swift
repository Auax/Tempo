import Foundation

enum PieceDifficulty: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case easy = "Easy"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
}

enum PieceGenre: String, CaseIterable, Identifiable, Codable {
    case classical = "Classical"
    case contemporary = "Contemporary"
    case jazz = "Jazz"
    case pop = "Pop"
    case film = "Film"
    case other = "Other"

    var id: String { rawValue }
}

struct ScoreFolder: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

struct PendingScoreImport: Identifiable {
    let id = UUID()
    let storedURL: URL
    let originalFileName: String
    let parsedScore: ParsedScore
}

struct PracticeSection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var startMeasure: Int
    var endMeasure: Int
    var mastery: Double

    init(
        id: UUID = UUID(),
        name: String,
        startMeasure: Int,
        endMeasure: Int,
        mastery: Double
    ) {
        self.id = id
        self.name = name
        self.startMeasure = startMeasure
        self.endMeasure = endMeasure
        self.mastery = mastery
    }

    var measureLabel: String {
        "Measures \(startMeasure)-\(endMeasure)"
    }
}

struct Piece: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var composer: String
    var collection: String
    var fileName: String?
    var scorePath: String?
    var previewImagePath: String?
    var progress: Double
    var bestAccuracy: Double
    var lastPracticed: Date
    var isFavorite: Bool
    var difficulty: String
    var genre: String
    var folderID: ScoreFolder.ID?
    var addedAt: Date
    var sections: [PracticeSection]

    init(
        id: UUID = UUID(),
        title: String,
        composer: String,
        collection: String,
        fileName: String? = nil,
        scorePath: String? = nil,
        previewImagePath: String? = nil,
        progress: Double,
        bestAccuracy: Double,
        lastPracticed: Date = .now,
        isFavorite: Bool = false,
        difficulty: String,
        genre: String = PieceGenre.classical.rawValue,
        folderID: ScoreFolder.ID? = nil,
        addedAt: Date = .now,
        sections: [PracticeSection]
    ) {
        self.id = id
        self.title = title
        self.composer = composer
        self.collection = collection
        self.fileName = fileName
        self.scorePath = scorePath
        self.previewImagePath = previewImagePath
        self.progress = progress
        self.bestAccuracy = bestAccuracy
        self.lastPracticed = lastPracticed
        self.isFavorite = isFavorite
        self.difficulty = difficulty
        self.genre = genre
        self.folderID = folderID
        self.addedAt = addedAt
        self.sections = sections
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case composer
        case collection
        case fileName
        case scorePath
        case previewImagePath
        case progress
        case bestAccuracy
        case lastPracticed
        case isFavorite
        case difficulty
        case genre
        case folderID
        case addedAt
        case sections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        composer = try container.decode(String.self, forKey: .composer)
        collection = try container.decode(String.self, forKey: .collection)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        scorePath = try container.decodeIfPresent(String.self, forKey: .scorePath)
        previewImagePath = try container.decodeIfPresent(
            String.self,
            forKey: .previewImagePath
        )
        progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        bestAccuracy = try container.decodeIfPresent(Double.self, forKey: .bestAccuracy) ?? 0
        lastPracticed = try container.decodeIfPresent(Date.self, forKey: .lastPracticed) ?? .now
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        let decodedDifficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        difficulty = PieceDifficulty(rawValue: decodedDifficulty ?? "")?.rawValue
            ?? PieceDifficulty.easy.rawValue
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
            ?? PieceGenre.classical.rawValue
        folderID = try container.decodeIfPresent(ScoreFolder.ID.self, forKey: .folderID)
        addedAt = try container.decodeIfPresent(Date.self, forKey: .addedAt) ?? lastPracticed
        sections = try container.decodeIfPresent([PracticeSection].self, forKey: .sections) ?? []
    }
}
