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
    func activeStartBeatDoesNotSelectFutureGroupWithinEpsilon() {
        let justBeforeSecondGroup = 0.25 - (ScoreTimeline.beatEqualityEpsilon / 2)

        #expect(ScoreTimeline.activeStartBeat(at: justBeforeSecondGroup, in: events) == 0)
    }

    @Test
    func soundingEventsUseExactPlaybackBoundaries() {
        let first = events[0]
        let second = events[1]
        let justBeforeSecondGroup = 0.25 - (ScoreTimeline.beatEqualityEpsilon / 2)

        #expect(ScoreTimeline.isSounding(first, at: justBeforeSecondGroup))
        #expect(!ScoreTimeline.isSounding(second, at: justBeforeSecondGroup))
        #expect(!ScoreTimeline.isSounding(first, at: 0.25))
        #expect(ScoreTimeline.isSounding(second, at: 0.25))
    }

    @Test
    func nextStartBeatAdvancesByGroup() {
        #expect(ScoreTimeline.nextStartBeat(after: 0, in: events) == 0.25)
        #expect(ScoreTimeline.nextStartBeat(after: 0.25, in: events) == 0.5)
        #expect(ScoreTimeline.nextStartBeat(after: 0.5, in: events) == nil)
    }
}
