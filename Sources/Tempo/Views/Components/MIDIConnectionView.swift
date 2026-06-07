import SwiftUI

struct MIDIConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var midiService: MIDIService

    @State private var showVirtualSources = false
    @State private var activityPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            connectionStatusCard
            sourcePicker
            liveTestCard
            troubleshooting
            footer
        }
        .padding(28)
        .frame(width: 520)
        .onChange(of: midiService.lastEvent?.note) { _, _ in
            withAnimation(.easeOut(duration: 0.12)) {
                activityPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                activityPulse = false
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Connect Piano")
                    .font(.title2.weight(.semibold))
                Text("Select your MIDI keyboard for low-latency practice.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") { dismiss() }
                .tempoBorderedButton()
        }
    }

    private var connectionStatusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.subheadline.weight(.semibold))
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Refresh") {
                midiService.refreshSources()
            }
            .tempoBorderedButton()
        }
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    private var sourcePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MIDI Input")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if midiService.physicalSources.isEmpty && midiService.virtualSources.isEmpty {
                Text("No MIDI devices detected. Connect your piano via USB or Bluetooth, then refresh.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                Picker("Piano", selection: selectedSourceBinding) {
                    Text("None").tag(Optional<Int32>.none)
                    if !midiService.physicalSources.isEmpty {
                        Section("Pianos") {
                            ForEach(midiService.physicalSources) { source in
                                Text(source.name).tag(Optional(source.uniqueID))
                            }
                        }
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                if !midiService.virtualSources.isEmpty {
                    DisclosureGroup("Advanced virtual devices", isExpanded: $showVirtualSources) {
                        Picker("Virtual MIDI", selection: selectedSourceBinding) {
                            Text("None").tag(Optional<Int32>.none)
                            ForEach(midiService.virtualSources) { source in
                                Text(source.name).tag(Optional(source.uniqueID))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var liveTestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Input Test")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(activityPulse ? Color.tempoGreen.opacity(0.25) : Color.primary.opacity(0.06))
                        .frame(width: 52, height: 52)
                    Image(systemName: "pianokeys")
                        .font(.title3)
                        .foregroundStyle(midiService.isConnected ? Color.tempoGreen : .secondary)
                        .scaleEffect(activityPulse ? 1.08 : 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let event = midiService.lastEvent {
                        Text(Self.noteName(for: event.note))
                            .font(.title3.weight(.semibold).monospacedDigit())
                        Text("MIDI \(event.note) · velocity \(event.velocity)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let latency = midiService.recentLatencyMs {
                            Text(String(format: "Input latency %.1f ms", latency))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    } else {
                        Text("Press a key on your piano")
                            .font(.subheadline)
                        Text("Note events appear here instantly.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var troubleshooting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Troubleshooting")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Label("Check USB cable or Bluetooth pairing in System Settings.", systemImage: "cable.connector")
            Label("Open Audio MIDI Setup to confirm the device is listed.", systemImage: "slider.horizontal.3")
            Label("Power-cycle the piano if it does not appear after refresh.", systemImage: "power")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .tempoProminentButton()
                .keyboardShortcut(.defaultAction)
        }
    }

    private var selectedSourceBinding: Binding<Int32?> {
        Binding(
            get: { midiService.selectedSourceID },
            set: { midiService.selectSource(uniqueID: $0) }
        )
    }

    private var statusColor: Color {
        switch midiService.connectionState {
        case .connected:
            return .tempoGreen
        case .connecting:
            return .tempoOrange
        case .disconnected:
            return .secondary
        case .error:
            return .tempoRed
        }
    }

    private var statusTitle: String {
        switch midiService.connectionState {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Not Connected"
        case .error:
            return "Connection Problem"
        }
    }

    private var statusDetail: String {
        switch midiService.connectionState {
        case .connected:
            return midiService.activeSourceName ?? "Piano ready"
        case .connecting:
            return midiService.activeSourceName ?? "Connecting to piano"
        case .disconnected:
            return "Choose a MIDI input above"
        case .error(let message):
            return message
        }
    }

    private static func noteName(for midiNote: Int) -> String {
        let names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let pitchClass = names[midiNote % 12]
        let octave = (midiNote / 12) - 1
        return "\(pitchClass)\(octave)"
    }
}
