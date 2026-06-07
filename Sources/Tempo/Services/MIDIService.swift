import CoreMIDI
import Foundation
import Observation
enum MIDIConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

struct MIDISource: Identifiable, Equatable, Sendable {
    let uniqueID: Int32
    let name: String
    let isVirtual: Bool

    var id: Int32 { uniqueID }
}

struct MIDINoteEvent: Equatable, Sendable {
    enum Kind: Sendable {
        case noteOn
        case noteOff
    }

    let kind: Kind
    let note: Int
    let velocity: Int
    let latencyMs: Double?
}

enum MIDIParser {
    static func isVirtualSource(name: String) -> Bool {
        let normalized = name.lowercased()
        let virtualMarkers = [
            "iac driver",
            "iac bus",
            "network session",
            "from logic",
            "to logic"
        ]
        return virtualMarkers.contains { normalized.contains($0) }
    }

    static func noteEvents(
        from eventList: UnsafePointer<MIDIEventList>,
        receivedAt: UInt64 = mach_absolute_time()
    ) -> [MIDINoteEvent] {
        var events: [MIDINoteEvent] = []
        var packet = eventList.pointee.packet

        for _ in 0..<eventList.pointee.numPackets {
            let latencyMs = latencyMilliseconds(
                packetTimestamp: packet.timeStamp,
                receivedAt: receivedAt
            )

            let words: [UInt32] = withUnsafeBytes(of: packet.words) { bytes in
                Array(bytes.bindMemory(to: UInt32.self).prefix(Int(packet.wordCount)))
            }

            for word in words {
                events.append(
                    contentsOf: noteEvents(
                        fromUMPWord: word,
                        latencyMs: latencyMs
                    )
                )
            }

            packet = withUnsafePointer(to: &packet) {
                MIDIEventPacketNext($0).pointee
            }
        }

        return events
    }

    static func noteEvents(fromUMPWords words: [UInt32]) -> [MIDINoteEvent] {
        words.flatMap { noteEvents(fromUMPWord: $0, latencyMs: nil) }
    }

    static func noteEvents(fromUMPWord word: UInt32, latencyMs: Double?) -> [MIDINoteEvent] {
        guard ((word >> 28) & 0x0F) == 0x02 else { return [] }

        let status = UInt8((word >> 16) & 0xFF)
        let note = Int((word >> 8) & 0x7F)
        let velocity = Int(word & 0x7F)
        let command = status & 0xF0

        switch command {
        case 0x90 where velocity > 0:
            return [
                MIDINoteEvent(
                    kind: .noteOn,
                    note: note,
                    velocity: velocity,
                    latencyMs: latencyMs
                )
            ]
        case 0x80:
            return [
                MIDINoteEvent(
                    kind: .noteOff,
                    note: note,
                    velocity: velocity,
                    latencyMs: latencyMs
                )
            ]
        case 0x90:
            return [
                MIDINoteEvent(
                    kind: .noteOff,
                    note: note,
                    velocity: 0,
                    latencyMs: latencyMs
                )
            ]
        default:
            return []
        }
    }

    static func preferredSourceID(from defaults: UserDefaults) -> Int32? {
        guard defaults.object(forKey: MIDIStorageKeys.preferredSourceID) != nil else {
            return nil
        }
        return Int32(defaults.integer(forKey: MIDIStorageKeys.preferredSourceID))
    }

    static func savePreferredSourceID(_ uniqueID: Int32?, to defaults: UserDefaults) {
        if let uniqueID {
            defaults.set(Int(uniqueID), forKey: MIDIStorageKeys.preferredSourceID)
        } else {
            defaults.removeObject(forKey: MIDIStorageKeys.preferredSourceID)
        }
    }

    private static func latencyMilliseconds(
        packetTimestamp: UInt64,
        receivedAt: UInt64
    ) -> Double? {
        guard packetTimestamp > 0, receivedAt >= packetTimestamp else { return nil }
        var timebase = mach_timebase_info_data_t()
        guard mach_timebase_info(&timebase) == KERN_SUCCESS else { return nil }
        let delta = receivedAt - packetTimestamp
        let nanoseconds = delta * UInt64(timebase.numer) / UInt64(timebase.denom)
        return Double(nanoseconds) / 1_000_000
    }
}

enum MIDIStorageKeys {
    static let preferredSourceID = "tempo.midi.preferredSourceID"
}

@Observable
final class MIDIService {
    private(set) var availableSources: [MIDISource] = []
    private(set) var selectedSourceID: Int32?
    private(set) var connectionState: MIDIConnectionState = .disconnected
    private(set) var lastEvent: MIDINoteEvent?
    private(set) var recentLatencyMs: Double?

    var onNote: (@MainActor (Int, Int) -> Void)?
    var onNoteOff: (@MainActor (Int) -> Void)?

    var activeSourceName: String? {
        guard let selectedSourceID else { return nil }
        return availableSources.first(where: { $0.uniqueID == selectedSourceID })?.name
    }

    var isConnected: Bool {
        connectionState == .connected
    }

    var physicalSources: [MIDISource] {
        availableSources.filter { !$0.isVirtual }
    }

    var virtualSources: [MIDISource] {
        availableSources.filter(\.isVirtual)
    }

    @ObservationIgnored private let handles = MIDIHandles()
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var connectedEndpoint: MIDIEndpointRef = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedSourceID = MIDIParser.preferredSourceID(from: defaults)
        configure()
    }

    func refreshSources() {
        performOnMain { [self] in
            enumerateSources(reconnectPreferred: true)
        }
    }

    func selectSource(uniqueID: Int32?) {
        performOnMain { [self] in
            selectedSourceID = uniqueID
            MIDIParser.savePreferredSourceID(uniqueID, to: defaults)
            reconnectSelectedSource()
        }
    }

    private func configure() {
        MIDIClientCreateWithBlock(
            "Tempo MIDI Client" as CFString,
            &handles.client
        ) { [weak self] _ in
            self?.performOnMain {
                self?.enumerateSources(reconnectPreferred: true)
            }
        }

        MIDIInputPortCreateWithProtocol(
            handles.client,
            "Tempo MIDI Input" as CFString,
            ._1_0,
            &handles.inputPort
        ) { [weak self] eventList, _ in
            let receivedAt = mach_absolute_time()
            let events = MIDIParser.noteEvents(from: eventList, receivedAt: receivedAt)
            guard !events.isEmpty else { return }
            self?.enqueueDelivery(events)
        }

        performOnMain { [self] in
            enumerateSources(reconnectPreferred: true)
        }
    }

    private func enqueueDelivery(_ events: [MIDINoteEvent]) {
        DispatchQueue.main.async { [weak self] in
            self?.handleEvents(events)
        }
    }

    @MainActor
    private func handleEvents(_ events: [MIDINoteEvent]) {
        for event in events {
            lastEvent = event
            recentLatencyMs = event.latencyMs

            switch event.kind {
            case .noteOn:
                onNote?(event.note, event.velocity)
            case .noteOff:
                onNoteOff?(event.note)
            }
        }
    }

    @MainActor
    private func enumerateSources(reconnectPreferred: Bool) {
        disconnectCurrentSource()
        availableSources = Self.loadSources()

        if reconnectPreferred,
           let selectedSourceID,
           availableSources.contains(where: { $0.uniqueID == selectedSourceID }) {
            reconnectSelectedSource()
        } else if let selectedSourceID,
                  !availableSources.contains(where: { $0.uniqueID == selectedSourceID }) {
            connectionState = .error("Previously selected piano is not available.")
            self.selectedSourceID = nil
            MIDIParser.savePreferredSourceID(nil, to: defaults)
        } else if selectedSourceID == nil {
            connectionState = .disconnected
        }
    }

    @MainActor
    private func reconnectSelectedSource() {
        disconnectCurrentSource()

        guard let selectedSourceID else {
            connectionState = .disconnected
            return
        }

        guard let endpoint = endpoint(for: selectedSourceID) else {
            connectionState = .error("Selected piano is not available.")
            return
        }

        connectionState = .connecting
        let status = MIDIPortConnectSource(handles.inputPort, endpoint, nil)
        guard status == noErr else {
            connectionState = .error("Could not connect to the selected piano.")
            return
        }

        connectedEndpoint = endpoint
        connectionState = .connected
    }

    @MainActor
    private func disconnectCurrentSource() {
        guard connectedEndpoint != 0 else { return }
        MIDIPortDisconnectSource(handles.inputPort, connectedEndpoint)
        connectedEndpoint = 0
        if connectionState == .connected || connectionState == .connecting {
            connectionState = .disconnected
        }
    }

    private func performOnMain(_ work: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated { work() }
        } else {
            DispatchQueue.main.async { work() }
        }
    }

    private func endpoint(for uniqueID: Int32) -> MIDIEndpointRef? {
        let sourceCount = MIDIGetNumberOfSources()
        for index in 0..<sourceCount {
            let source = MIDIGetSource(index)
            guard source != 0 else { continue }
            guard Self.uniqueID(for: source) == uniqueID else { continue }
            return source
        }
        return nil
    }

    private static func loadSources() -> [MIDISource] {
        let sourceCount = MIDIGetNumberOfSources()
        var sources: [MIDISource] = []

        for index in 0..<sourceCount {
            let endpoint = MIDIGetSource(index)
            guard endpoint != 0 else { continue }
            guard let uniqueID = uniqueID(for: endpoint) else { continue }

            let name = displayName(for: endpoint)
            sources.append(
                MIDISource(
                    uniqueID: uniqueID,
                    name: name,
                    isVirtual: MIDIParser.isVirtualSource(name: name)
                )
            )
        }

        return sources.sorted { lhs, rhs in
            if lhs.isVirtual != rhs.isVirtual {
                return !lhs.isVirtual
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private static func uniqueID(for endpoint: MIDIEndpointRef) -> Int32? {
        var uniqueID = Int32(0)
        let result = MIDIObjectGetIntegerProperty(
            endpoint,
            kMIDIPropertyUniqueID,
            &uniqueID
        )
        return result == noErr ? uniqueID : nil
    }

    private static func displayName(for endpoint: MIDIEndpointRef) -> String {
        var unmanagedName: Unmanaged<CFString>?
        let result = MIDIObjectGetStringProperty(
            endpoint,
            kMIDIPropertyDisplayName,
            &unmanagedName
        )

        guard result == noErr, let unmanagedName else {
            return "MIDI Device"
        }
        return unmanagedName.takeRetainedValue() as String
    }
}

private final class MIDIHandles {
    var client = MIDIClientRef()
    var inputPort = MIDIPortRef()

    deinit {
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }
}
