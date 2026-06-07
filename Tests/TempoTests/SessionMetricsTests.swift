import Testing
@testable import Tempo

struct SessionMetricsTests {
    @Test
    func accuracyIncludesAllFeedbackTypes() {
        let metrics = SessionMetrics(
            correctNotes: 80,
            mistakes: 10,
            missedNotes: 5,
            extraNotes: 5,
            rhythm: 0.9,
            practicedSeconds: 60,
            longestStreak: 12,
            currentStreak: 0
        )

        #expect(metrics.accuracy == 0.8)
    }

    @Test
    func resetClearsSession() {
        var metrics = SessionMetrics()
        metrics.reset()

        #expect(metrics.correctNotes == 0)
        #expect(metrics.totalNotes == 0)
        #expect(metrics.practicedSeconds == 0)
    }
}
