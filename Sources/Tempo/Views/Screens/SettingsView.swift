import SwiftUI

struct TempoSettingsView: View {
    var embedded = false

    @AppStorage("tempo.countIn") private var countIn = true
    @AppStorage("tempo.visualKeyboard") private var visualKeyboard = true
    @AppStorage("tempo.feedbackSounds") private var feedbackSounds = false
    @AppStorage("tempo.appearance") private var appearance = TempoAppearance.system

    var body: some View {
        if embedded {
            embeddedSettings
        } else {
            settingsForm
        }
    }

    private var settingsForm: some View {
        Form {
            Section("Practice") {
                practiceControls
            }

            Section("Appearance") {
                appearanceControls
            }

            Section("Supported Scores") {
                supportedScoresDescription
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 470, height: 350)
    }

    private var embeddedSettings: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TempoTheme.Spacing.xLarge) {
                VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                    Text("Settings")
                        .font(.largeTitle.weight(.semibold))
                    Text("Customize your practice experience and Tempo's appearance.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                SettingsSection(
                    title: "Practice",
                    subtitle: "Choose the guidance Tempo provides while you play.",
                    symbol: "pianokeys"
                ) {
                    practiceControls
                }

                Divider()

                SettingsSection(
                    title: "Appearance",
                    subtitle: "Select how Tempo looks across the app.",
                    symbol: "circle.lefthalf.filled"
                ) {
                    appearanceControls
                }

                Divider()

                SettingsSection(
                    title: "Supported Scores",
                    subtitle: "Formats available for score import and engraving.",
                    symbol: "doc.badge.gearshape"
                ) {
                    supportedScoresDescription
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(TempoTheme.Spacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var practiceControls: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            Toggle("Two-bar count-in", isOn: $countIn)
            Toggle("Show visual keyboard", isOn: $visualKeyboard)
            Toggle("Feedback sounds", isOn: $feedbackSounds)
        }
    }

    private var appearanceControls: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
            Picker("Theme", selection: $appearance) {
                ForEach(TempoAppearance.allCases) { option in
                    Label(option.title, systemImage: option.symbol)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)

            Text(appearanceDescription)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var supportedScoresDescription: some View {
        Text("MusicXML and compressed MXL scores are engraved with Verovio.")
            .foregroundStyle(.secondary)
    }

    private var appearanceDescription: String {
        switch appearance {
        case .system:
            "Tempo follows your macOS appearance."
        case .light:
            "Tempo always uses its light appearance."
        case .dark:
            "Tempo always uses its dark appearance."
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.tempoBlue)
                .frame(width: 24, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#if DEBUG
#Preview("Settings") {
    TempoSettingsView(embedded: true)
        .frame(width: 1_000, height: 720)
}
#endif
