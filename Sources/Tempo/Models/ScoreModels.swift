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

struct ParsedScore: Identifiable, Sendable {
    let id = UUID()
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
        events.reduce(0) { max($0, $1.endBeat) }
    }

    func measure(at beat: Double) -> Int {
        var currentMeasure = 1
        var currentStart = -Double.infinity
        for (measure, startBeat) in measureStartBeats
        where startBeat <= beat + 0.0001 && startBeat > currentStart {
            currentMeasure = measure
            currentStart = startBeat
        }
        return currentMeasure
    }

    func beat(atMeasure measure: Int) -> Double {
        measureStartBeats[measure] ?? 0
    }
}

enum ScoreTimeline {
    static let beatEqualityEpsilon = 0.001

    static func events(atStartBeat beat: Double, in events: [ScoreNoteEvent]) -> [ScoreNoteEvent] {
        events.filter { abs($0.startBeat - beat) < beatEqualityEpsilon }
    }

    static func activeStartBeat(at beat: Double, in events: [ScoreNoteEvent]) -> Double? {
        var activeBeat: Double?
        for event in events {
            guard event.startBeat <= beat else { break }
            activeBeat = event.startBeat
        }
        return activeBeat
    }

    static func isSounding(_ event: ScoreNoteEvent, at beat: Double) -> Bool {
        event.startBeat <= beat && event.endBeat > beat
    }

    static func nextStartBeat(after beat: Double, in events: [ScoreNoteEvent]) -> Double? {
        events.first { $0.startBeat > beat + beatEqualityEpsilon }?.startBeat
    }

    static func firstStartBeat(from beat: Double, in events: [ScoreNoteEvent]) -> Double? {
        events.first { $0.startBeat >= beat - beatEqualityEpsilon }?.startBeat
    }
}
