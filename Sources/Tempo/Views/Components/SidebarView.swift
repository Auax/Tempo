import SwiftUI

struct SidebarView: View {
    @Bindable var store: TempoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 6) {
                ForEach(AppDestination.allCases) { destination in
                    SidebarItem(
                        destination: destination,
                        selected: store.destination == destination
                    ) {
                        withAnimation(TempoTheme.Motion.quick) {
                            store.openDestination(destination)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)

            if store.isPracticeWorkspacePresented {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)

                expandedPracticeControls
            }

            Spacer(minLength: 12)

            connectionStatus
                .padding(14)
        }
        .frame(width: TempoTheme.Layout.sidebarExpanded)
        .frame(maxHeight: .infinity, alignment: .top)
        .tempoGlassPanel()
        .safeAreaPadding(.top, 18)
    }

    private var expandedPracticeControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            if store.isPracticeWorkspacePresented,
               let sections = store.selectedPiece?.sections {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Practice Sections")
                    ForEach(sections) { section in
                        Button {
                            store.selectedSectionID = section.id
                            store.restartSection()
                        } label: {
                            HStack(spacing: 9) {
                                Text(section.name.prefix(1))
                                    .font(.caption.weight(.bold))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        .primary.opacity(0.07),
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(section.name)
                                        .font(.caption.weight(.medium))
                                        .lineLimit(1)
                                    Text(section.measureLabel)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 42)
                            .background(
                                store.selectedSectionID == section.id
                                    ? Color.tempoBlue.opacity(0.14)
                                    : .clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if store.isPracticeWorkspacePresented {
                HStack {
                    Label("Loop section", systemImage: "repeat")
                        .font(.caption)
                    Spacer()
                    Toggle("", isOn: $store.isLoopEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .tint(.tempoBlue)
                }
            }
        }
        .padding(.horizontal, 14)
    }

    private var connectionStatus: some View {
        Button {
            store.midiService.refreshSources()
            store.showingMIDIConnection = true
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(store.midiService.isConnected ? Color.tempoGreen : .secondary)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.midiService.isConnected ? "Piano Connected" : "Connect Piano")
                        .font(.caption.weight(.medium))
                    Text(store.midiService.activeSourceName ?? "No MIDI input detected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(store.midiService.activeSourceName ?? "Connect a MIDI piano")
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}

private struct SidebarItem: View {
    let destination: AppDestination
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: destination.symbol)
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: 24)
                Text(destination.title)
                    .font(.system(size: 16, weight: selected ? .medium : .regular))
                Spacer(minLength: 0)
            }
            .foregroundStyle(selected ? .primary : .secondary)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                selected ? Color.primary.opacity(0.09) : .clear,
                in: RoundedRectangle(cornerRadius: 10)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(destination.title)
    }
}

struct PieceArtwork: View {
    let title: String
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.tempoBlue.opacity(0.82),
                            Color(red: 0.16, green: 0.26, blue: 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.34, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
        .accessibilityLabel("\(title) artwork")
    }
}
