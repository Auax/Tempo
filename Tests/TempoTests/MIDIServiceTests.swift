import Foundation
import Testing
@testable import Tempo

@Suite("MIDI Service")
struct MIDIServiceTests {
    @Test("classifies virtual loopback sources")
    func virtualSourceClassification() {
        #expect(MIDIParser.isVirtualSource(name: "IAC Driver Bus 1"))
        #expect(MIDIParser.isVirtualSource(name: "iac bus 2"))
        #expect(MIDIParser.isVirtualSource(name: "Network Session 1"))
        #expect(!MIDIParser.isVirtualSource(name: "Yamaha Digital Piano"))
        #expect(!MIDIParser.isVirtualSource(name: "KOMPLETE KONTROL - 1"))
    }

    @Test("parses note-on UMP messages")
    func noteOnParsing() {
        let noteOn = umpWord(status: 0x90, note: 60, velocity: 88)
        let events = MIDIParser.noteEvents(fromUMPWords: [noteOn])

        #expect(events.count == 1)
        #expect(events[0].kind == .noteOn)
        #expect(events[0].note == 60)
        #expect(events[0].velocity == 88)
    }

    @Test("parses note-off UMP messages")
    func noteOffParsing() {
        let noteOff = umpWord(status: 0x80, note: 64, velocity: 0)
        let noteOnZeroVelocity = umpWord(status: 0x90, note: 64, velocity: 0)

        let events = MIDIParser.noteEvents(fromUMPWords: [noteOff, noteOnZeroVelocity])

        #expect(events.count == 2)
        #expect(events.allSatisfy { $0.kind == .noteOff })
        #expect(events.allSatisfy { $0.note == 64 })
    }

    @Test("ignores non-channel-voice UMP messages")
    func ignoresNonVoiceMessages() {
        let systemWord: UInt32 = 0x10000000
        #expect(MIDIParser.noteEvents(fromUMPWords: [systemWord]).isEmpty)
    }

    @Test("persists preferred source id")
    func preferredSourcePersistence() {
        let defaults = UserDefaults(suiteName: "MIDIServiceTests")!
        defaults.removePersistentDomain(forName: "MIDIServiceTests")

        #expect(MIDIParser.preferredSourceID(from: defaults) == nil)

        MIDIParser.savePreferredSourceID(42_001, to: defaults)
        #expect(MIDIParser.preferredSourceID(from: defaults) == 42_001)

        MIDIParser.savePreferredSourceID(nil, to: defaults)
        #expect(MIDIParser.preferredSourceID(from: defaults) == nil)
    }

    private func umpWord(status: UInt8, note: UInt8, velocity: UInt8) -> UInt32 {
        (0x2 << 28)
            | (UInt32(status) << 16)
            | (UInt32(note) << 8)
            | UInt32(velocity)
    }
}
