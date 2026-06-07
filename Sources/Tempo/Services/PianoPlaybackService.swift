import AudioToolbox
import AVFoundation
import Foundation

@MainActor
final class PianoPlaybackService {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var soundingNotes: Set<Int> = []
    private var lastSyncedBeat = -1.0

    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = 0.8
        loadPiano()
    }

    func sync(events: [ScoreNoteEvent], at beat: Double, isPlaying: Bool) {
        guard isPlaying else {
            stopAll()
            resetSyncCursor()
            return
        }
        startEngineIfNeeded()

        if lastSyncedBeat < 0 || beat < lastSyncedBeat - ScoreTimeline.beatEqualityEpsilon {
            lastSyncedBeat = beat - (ScoreTimeline.beatEqualityEpsilon * 2)
        }

        let boundary = beat + ScoreTimeline.beatEqualityEpsilon
        let previous = lastSyncedBeat + ScoreTimeline.beatEqualityEpsilon

        enum EdgeKind {
            case noteOff
            case noteOn
        }

        struct Edge: Comparable {
            let time: Double
            let kind: EdgeKind
            let midiNote: Int

            static func < (lhs: Edge, rhs: Edge) -> Bool {
                if lhs.time != rhs.time {
                    return lhs.time < rhs.time
                }
                // Release before attack when events share a beat boundary.
                if lhs.kind != rhs.kind {
                    return lhs.kind == .noteOff
                }
                return lhs.midiNote < rhs.midiNote
            }
        }

        var edges: [Edge] = []
        for event in events {
            if event.startBeat > previous && event.startBeat <= boundary {
                edges.append(Edge(time: event.startBeat, kind: .noteOn, midiNote: event.midiNote))
            }
            if event.endBeat > previous && event.endBeat <= boundary {
                edges.append(Edge(time: event.endBeat, kind: .noteOff, midiNote: event.midiNote))
            }
        }

        for edge in edges.sorted() {
            switch edge.kind {
            case .noteOff:
                stopNote(edge.midiNote)
            case .noteOn:
                startNote(edge.midiNote)
            }
        }

        lastSyncedBeat = beat
    }

    func resetSyncCursor() {
        lastSyncedBeat = -1
    }

    func preview(note: Int, velocity: Int = 84) {
        startEngineIfNeeded()
        sampler.startNote(UInt8(note), withVelocity: UInt8(clamping: velocity), onChannel: 0)
        Task {
            try? await Task.sleep(for: .milliseconds(380))
            sampler.stopNote(UInt8(note), onChannel: 0)
        }
    }

    func stopAll() {
        for note in soundingNotes {
            sampler.stopNote(UInt8(note), onChannel: 0)
        }
        soundingNotes.removeAll()
        resetSyncCursor()
    }

    private func startNote(_ note: Int) {
        if soundingNotes.contains(note) {
            sampler.stopNote(UInt8(note), onChannel: 0)
        }
        sampler.startNote(UInt8(note), withVelocity: 88, onChannel: 0)
        soundingNotes.insert(note)
    }

    private func stopNote(_ note: Int) {
        guard soundingNotes.contains(note) else { return }
        sampler.stopNote(UInt8(note), onChannel: 0)
        soundingNotes.remove(note)
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            assertionFailure("Could not start piano audio engine: \(error)")
        }
    }

    private func loadPiano() {
        let soundBank = URL(
            fileURLWithPath:
                "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
        )
        try? sampler.loadSoundBankInstrument(
            at: soundBank,
            program: 0,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
    }
}
