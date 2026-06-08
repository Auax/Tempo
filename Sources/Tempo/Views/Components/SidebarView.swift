import SwiftUI

struct SidebarView: View {
    @Bindable var store: TempoStore
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: TempoTheme.Layout.sidebarItemSpacing) {
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
            .padding(.horizontal, TempoTheme.Layout.sidebarHorizontalPadding)
            .padding(.top, TempoTheme.Layout.sidebarTopPadding)

            if !compact, store.isPracticeWorkspacePresented {
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)

                expandedPracticeControls
            }

            Spacer(minLength: 12)

            connectionStatus
                .padding(.horizontal, TempoTheme.Layout.sidebarHorizontalPadding)
                .padding(.bottom, 14)
        }
        .frame(
            width: compact
                ? TempoTheme.Layout.sidebarCollapsed
                : TempoTheme.Layout.sidebarExpanded
        )
        .frame(maxHeight: .infinity, alignment: .top)
        .tempoGlassPanel()
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
            HStack(spacing: 11) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "pianokeys")
                        .font(.system(size: 17, weight: .regular))
                        .frame(width: TempoTheme.Layout.sidebarItemIconWidth)

                    Circle()
                        .fill(store.midiService.isConnected ? Color.tempoGreen : .secondary)
                        .frame(width: 7, height: 7)
                        .offset(x: 3, y: -3)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.midiService.isConnected ? "Piano Connected" : "Connect Piano")
                        .font(.caption.weight(.medium))
                    Text(store.midiService.activeSourceName ?? "No MIDI input detected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: compact ? 0 : .infinity, alignment: .leading)
                .opacity(compact ? 0 : 1)
                .clipped()

                if !compact {
                    Spacer(minLength: 0)
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: TempoTheme.Layout.sidebarItemHeight,
                alignment: .leading
            )
            .padding(.horizontal, TempoTheme.Layout.sidebarItemInnerPadding)
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
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: destination.symbol)
                    .font(.system(size: 17, weight: .regular))
                    .frame(width: TempoTheme.Layout.sidebarItemIconWidth)

                Text(destination.title)
                    .font(.system(size: 16, weight: selected ? .medium : .regular))
                    .lineLimit(1)
                    .frame(maxWidth: compact ? 0 : .infinity, alignment: .leading)
                    .opacity(compact ? 0 : 1)
                    .clipped()

                if !compact {
                    Spacer(minLength: 0)
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: TempoTheme.Layout.sidebarItemHeight,
                alignment: .leading
            )
            .padding(.horizontal, TempoTheme.Layout.sidebarItemInnerPadding)
            .foregroundStyle(selected ? .primary : .secondary)
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
