import Testing
@testable import Tempo

struct ScoreTimelineTests {
    private let events = [
        ScoreNoteEvent(id: "a", midiNote: 60, startBeat: 0, duration: 0.25, measure: 1, hand: .right),
        ScoreNoteEvent(id: "b", midiNote: 62, startBeat: 0.25, duration: 0.25, measure: 1, hand: .right),
        ScoreNoteEvent(id: "c", midiNote: 64, startBeat: 0.25, duration: 0.25, measure: 1, hand: .right),
        ScoreNoteEvent(id: "d", midiNote: 65, startBeat: 0.5, duration: 0.25, measure: 1, hand: .right),
    ]

    @Test
    func activeStartBeatSelectsSingleGroup() {
        #expect(ScoreTimeline.activeStartBeat(at: 0.26, in: events) == 0.25)
        #expect(ScoreTimeline.events(atStartBeat: 0.25, in: events).map(\.id) == ["b", "c"])
        #expect(ScoreTimeline.events(atStartBeat: 0, in: events).map(\.id) == ["a"])
    }

    @Test
    func nextStartBeatAdvancesByGroup() {
        #expect(ScoreTimeline.nextStartBeat(after: 0, in: events) == 0.25)
        #expect(ScoreTimeline.nextStartBeat(after: 0.25, in: events) == 0.5)
        #expect(ScoreTimeline.nextStartBeat(after: 0.5, in: events) == nil)
    }
}
