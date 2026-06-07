import SwiftUI

struct SidebarView: View {
    @Bindable var store: TempoStore

    private var compact: Bool {
        store.sidebarCollapsed
    }

    var body: some View {
        VStack(alignment: compact ? .center : .leading, spacing: 0) {
            HStack {
                TempoLogo(compact: compact)
                Spacer(minLength: 0)
                if !compact {
                    Button {
                        withAnimation(TempoTheme.Motion.standard) {
                            store.sidebarCollapsed = true
                        }
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Collapse Sidebar")
                }
            }
            .padding(.horizontal, compact ? 22 : 18)
            .frame(height: TempoTheme.Layout.topBarHeight)

            VStack(spacing: 4) {
                ForEach(AppDestination.allCases) { destination in
                    SidebarItem(
                        destination: destination,
                        selected: store.destination == destination,
                        compact: compact
                    ) {
                        withAnimation(TempoTheme.Motion.quick) {
                            store.openDestination(destination)
                        }
                    }
                }
            }
            .padding(.horizontal, compact ? 10 : 12)
            .padding(.top, 8)

            Divider()
                .padding(.vertical, 16)

            if compact {
                compactPracticeControls
            } else {
                expandedPracticeControls
            }

            Spacer(minLength: 12)

            connectionStatus
                .padding(compact ? 10 : 14)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.primary.opacity(0.07))
                .frame(width: 1)
        }
        .frame(
            width: compact
                ? TempoTheme.Layout.sidebarCollapsed
                : TempoTheme.Layout.sidebarExpanded
        )
        .animation(TempoTheme.Motion.standard, value: compact)
    }

    private var expandedPracticeControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            

            if let sections = store.selectedPiece?.sections {
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
        .padding(.horizontal, 14)
    }

    private var compactPracticeControls: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(TempoTheme.Motion.standard) {
                    store.sidebarCollapsed = false
                }
            } label: {
                Image(systemName: "sidebar.right")
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.borderless)
            .help("Expand Sidebar")

            if let piece = store.selectedPiece {
                PieceArtwork(title: piece.title, size: 38)
                    .help(piece.title)
            }

            Button {
                store.isLoopEnabled.toggle()
            } label: {
                Image(systemName: store.isLoopEnabled ? "repeat.circle.fill" : "repeat.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(store.isLoopEnabled ? Color.tempoBlue : .secondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Loop")
        }
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
                if !compact {
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
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: destination.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                if !compact {
                    Text(destination.title)
                        .font(.subheadline.weight(selected ? .semibold : .regular))
                    Spacer(minLength: 0)
                }
            }
            .foregroundStyle(selected ? Color.tempoBlue : .primary)
            .padding(.horizontal, compact ? 8 : 10)
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                selected ? Color.tempoBlue.opacity(0.13) : .clear,
                in: RoundedRectangle(cornerRadius: 9)
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
