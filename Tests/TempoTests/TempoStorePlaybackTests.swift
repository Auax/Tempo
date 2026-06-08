import Testing
@testable import Tempo

struct TempoStorePlaybackTests {
    @Test
    func playAfterFinishingRestartsAtBeginning() {
        let startBeat = TempoStore.playbackStartBeat(
            currentBeat: 20,
            targetBeat: 19,
            durationBeats: 20,
            sectionStartBeat: 0,
            isGuided: true
        )

        #expect(startBeat == 0)
    }
}
