import AudioToolbox
import AVFoundation
import Foundation

@MainActor
final class PianoPlaybackService {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var soundingNotes: Set<Int> = []

    init() {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = 0.8
        loadPiano()
    }

    func sync(events: [ScoreNoteEvent], at beat: Double, isPlaying: Bool) {
        guard isPlaying else {
            stopAll()
            return
        }
        startEngineIfNeeded()

        let target = Set(
            events
                .filter { $0.startBeat <= beat && $0.endBeat > beat }
                .map(\.midiNote)
        )

        for note in soundingNotes.subtracting(target) {
            sampler.stopNote(UInt8(note), onChannel: 0)
        }
        for note in target.subtracting(soundingNotes) {
            sampler.startNote(UInt8(note), withVelocity: 88, onChannel: 0)
        }
        soundingNotes = target
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
