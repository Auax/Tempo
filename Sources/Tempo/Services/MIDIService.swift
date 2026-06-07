import CoreMIDI
import Foundation
import Observation

@MainActor
@Observable
final class MIDIService {
    private(set) var sourceNames: [String] = []
    private(set) var activeSourceName: String?
    private(set) var lastNote: Int?
    private(set) var lastVelocity: Int?

    var onNote: ((Int, Int) -> Void)?

    @ObservationIgnored private let handles = MIDIHandles()

    init() {
        configure()
    }

    var isConnected: Bool {
        activeSourceName != nil
    }

    func refreshSources() {
        handles.connectedSources.forEach {
            MIDIPortDisconnectSource(handles.inputPort, $0)
        }
        handles.connectedSources.removeAll()
        sourceNames.removeAll()

        let sourceCount = MIDIGetNumberOfSources()
        for index in 0..<sourceCount {
            let source = MIDIGetSource(index)
            guard source != 0 else { continue }

            let name = displayName(for: source)
            sourceNames.append(name)
            handles.connectedSources.append(source)
            MIDIPortConnectSource(handles.inputPort, source, nil)
        }

        activeSourceName = sourceNames.first
    }

    private func configure() {
        MIDIClientCreateWithBlock(
            "Tempo MIDI Client" as CFString,
            &handles.client
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshSources()
            }
        }

        MIDIInputPortCreateWithProtocol(
            handles.client,
            "Tempo MIDI Input" as CFString,
            ._1_0,
            &handles.inputPort
        ) { [weak self] eventList, _ in
            let messages = Self.noteMessages(from: eventList)
            guard !messages.isEmpty else { return }

            Task { @MainActor in
                guard let self else { return }
                for message in messages {
                    self.lastNote = message.note
                    self.lastVelocity = message.velocity
                    self.onNote?(message.note, message.velocity)
                }
            }
        }

        refreshSources()
    }

    private func displayName(for endpoint: MIDIEndpointRef) -> String {
        var unmanagedName: Unmanaged<CFString>?
        let result = MIDIObjectGetStringProperty(
            endpoint,
            kMIDIPropertyDisplayName,
            &unmanagedName
        )

        guard result == noErr, let unmanagedName else {
            return "MIDI Piano"
        }
        return unmanagedName.takeRetainedValue() as String
    }

    nonisolated private static func noteMessages(
        from eventList: UnsafePointer<MIDIEventList>
    ) -> [(note: Int, velocity: Int)] {
        var messages: [(Int, Int)] = []
        var packet = eventList.pointee.packet

        for _ in 0..<eventList.pointee.numPackets {
            let words: [UInt32] = withUnsafeBytes(of: packet.words) { bytes in
                Array(bytes.bindMemory(to: UInt32.self).prefix(Int(packet.wordCount)))
            }

            for word in words where ((word >> 28) & 0x0F) == 0x02 {
                let status = UInt8((word >> 16) & 0xFF)
                let note = Int((word >> 8) & 0x7F)
                let velocity = Int(word & 0x7F)
                let command = status & 0xF0

                if command == 0x90, velocity > 0 {
                    messages.append((note, velocity))
                }
            }

            packet = withUnsafePointer(to: &packet) {
                MIDIEventPacketNext($0).pointee
            }
        }

        return messages
    }
}

private final class MIDIHandles {
    var client = MIDIClientRef()
    var inputPort = MIDIPortRef()
    var connectedSources: [MIDIEndpointRef] = []

    deinit {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }
}
