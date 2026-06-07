import Foundation

struct SessionMetrics: Codable, Equatable {
    var correctNotes = 0
    var mistakes = 0
    var missedNotes = 0
    var extraNotes = 0
    var rhythm = 0.0
    var practicedSeconds: TimeInterval = 0
    var longestStreak = 0
    var currentStreak = 0

    var totalNotes: Int {
        correctNotes + mistakes + missedNotes + extraNotes
    }

    var accuracy: Double {
        guard totalNotes > 0 else { return 0 }
        return Double(correctNotes) / Double(totalNotes)
    }

    mutating func register(correct: Bool) {
        if correct {
            correctNotes += 1
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            mistakes += 1
            currentStreak = 0
        }
    }

    mutating func reset() {
        self = SessionMetrics(
            correctNotes: 0,
            mistakes: 0,
            missedNotes: 0,
            extraNotes: 0,
            rhythm: 1,
            practicedSeconds: 0,
            longestStreak: 0,
            currentStreak: 0
        )
    }
}

enum NoteFeedback: String, Codable {
    case correct
    case incorrect
    case expected
}
