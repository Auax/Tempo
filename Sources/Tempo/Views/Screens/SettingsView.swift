import SwiftUI

struct TempoSettingsView: View {
    @AppStorage("tempo.countIn") private var countIn = true
    @AppStorage("tempo.visualKeyboard") private var visualKeyboard = true
    @AppStorage("tempo.feedbackSounds") private var feedbackSounds = false

    var body: some View {
        Form {
            Section("Practice") {
                Toggle("Two-bar count-in", isOn: $countIn)
                Toggle("Show visual keyboard", isOn: $visualKeyboard)
                Toggle("Feedback sounds", isOn: $feedbackSounds)
            }

            Section("Appearance") {
                Text("Tempo follows your macOS light or dark appearance.")
                    .foregroundStyle(.secondary)
            }

            Section("Supported Scores") {
                Text("MusicXML and compressed MXL scores are engraved with Verovio.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 470, height: 350)
    }
}
