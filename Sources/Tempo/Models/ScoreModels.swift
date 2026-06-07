import Foundation

enum PianoHand: String, Codable, Hashable, Sendable {
    case left
    case right
}

struct ScoreNoteEvent: Identifiable, Hashable, Sendable {
    let id: String
    let midiNote: Int
    let startBeat: Double
    let duration: Double
    let measure: Int
    let hand: PianoHand

    var endBeat: Double {
        startBeat + duration
    }
}

struct ParsedScore: Sendable {
    let xml: String
    let events: [ScoreNoteEvent]
    let measureStartBeats: [Int: Double]
    let measureDurations: [Int: Double]
    let title: String?
    let composer: String?
    let tempo: Int?

    var measureCount: Int {
        measureStartBeats.keys.max() ?? 0
    }

    var durationBeats: Double {
        events.map(\.endBeat).max() ?? 0
    }

    func measure(at beat: Double) -> Int {
        measureStartBeats
            .filter { $0.value <= beat + 0.0001 }
            .max { $0.value < $1.value }?
            .key ?? 1
    }

    func beat(atMeasure measure: Int) -> Double {
        measureStartBeats[measure] ?? 0
    }
}
