import Foundation

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
    var progress: Double
    var bestAccuracy: Double
    var lastPracticed: Date
    var isFavorite: Bool
    var difficulty: String
    var sections: [PracticeSection]

    init(
        id: UUID = UUID(),
        title: String,
        composer: String,
        collection: String,
        fileName: String? = nil,
        scorePath: String? = nil,
        progress: Double,
        bestAccuracy: Double,
        lastPracticed: Date = .now,
        isFavorite: Bool = false,
        difficulty: String,
        sections: [PracticeSection]
    ) {
        self.id = id
        self.title = title
        self.composer = composer
        self.collection = collection
        self.fileName = fileName
        self.scorePath = scorePath
        self.progress = progress
        self.bestAccuracy = bestAccuracy
        self.lastPracticed = lastPracticed
        self.isFavorite = isFavorite
        self.difficulty = difficulty
        self.sections = sections
    }
}
