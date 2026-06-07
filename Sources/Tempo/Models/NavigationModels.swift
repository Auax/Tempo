import Foundation

enum AppDestination: String, CaseIterable, Identifiable, Codable {
    case home
    case library
    case progress

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .progress: "Progress"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .library: "music.note.list"
        case .progress: "chart.xyaxis.line"
        }
    }
}

enum LibrarySection: String, CaseIterable, Identifiable {
    case allScores = "All Scores"
    case folders = "Folders"
    case composers = "Composers"

    var id: String { rawValue }
}

enum LibraryQuickFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case recent = "Recent"
    case favorites = "Favorites"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .all: "square.grid.2x2"
        case .recent: "clock"
        case .favorites: "star"
        }
    }
}

enum LibrarySort: String, CaseIterable, Identifiable {
    case lastOpened = "Last opened"
    case recentlyAdded = "Recently added"
    case title = "Title"
    case composer = "Composer"

    var id: String { rawValue }
}

enum PracticeMode: String, CaseIterable, Identifiable, Codable {
    case guided = "Guided"
    case section = "Section"
    case performance = "Performance"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .guided: "sparkles"
        case .section: "repeat"
        case .performance: "waveform.path"
        }
    }
}

enum HandSelection: String, CaseIterable, Identifiable, Codable {
    case both = "Both hands"
    case right = "Right hand"
    case left = "Left hand"

    var id: String { rawValue }
}
