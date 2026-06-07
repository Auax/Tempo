import Foundation

enum AppDestination: String, CaseIterable, Identifiable, Codable {
    case home
    case library
    case recent
    case favorites
    case progress

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .recent: "Recent"
        case .favorites: "Favorites"
        case .progress: "Progress"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .library: "music.note.list"
        case .recent: "clock"
        case .favorites: "star"
        case .progress: "chart.xyaxis.line"
        }
    }
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
