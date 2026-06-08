import AppKit
import SwiftUI

struct PracticeContentToolbar: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 16) {
            PracticeToolbarTitle(store: store)

            Spacer(minLength: 0)
                .allowsHitTesting(false)

            PracticeToolbarActions(store: store)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PracticeToolbarTitle: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 6) {
            Text(store.selectedPiece?.title ?? "Choose a score")
                .font(.headline)
                .lineLimit(1)

            Text("·")
                .foregroundStyle(.tertiary)

            Text(store.selectedPiece?.composer ?? "Tempo Library")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("·")
                .foregroundStyle(.tertiary)

            Text("Measure \(store.currentMeasure)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .allowsHitTesting(false)
    }
}

struct PracticeToolbarActions: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 12) {
            PracticeTempoControl(store: store)

            Menu {
                Button("Zoom In") {
                    store.scoreZoom = min(1.5, store.scoreZoom + 0.1)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    store.scoreZoom = max(0.7, store.scoreZoom - 0.1)
                }
                .keyboardShortcut("-", modifiers: .command)

                Divider()

                Button("Actual Size") {
                    store.scoreZoom = 1
                }
                .keyboardShortcut("0", modifiers: .command)
            } label: {
                Label(
                    "\(Int(store.scoreZoom * 100))%",
                    systemImage: "text.magnifyingglass"
                )
                .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 76)
            .help("Score Zoom")

            Button {
                withAnimation(TempoTheme.Motion.standard) {
                    store.focusMode.toggle()
                }
            } label: {
                Image(systemName: store.focusMode ? "arrow.down.right.and.arrow.up.left" : "viewfinder")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help(store.focusMode ? "Exit Focus Mode" : "Focus Mode")

            Button {
                store.focusMode = true
                NSApp.keyWindow?.toggleFullScreen(nil)
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Fullscreen Practice")
        }
        .labelStyle(.titleAndIcon)
    }
}

private struct PracticeTempoControl: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 5) {
            Button {
                store.isMetronomeEnabled.toggle()
            } label: {
                Image(systemName: store.isMetronomeEnabled ? "metronome.fill" : "metronome")
                    .foregroundStyle(store.isMetronomeEnabled ? Color.tempoBlue : .secondary)
            }
            .buttonStyle(.borderless)
            .help(store.isMetronomeEnabled ? "Disable Metronome" : "Enable Metronome")

            Text("\(store.tempo)")
                .font(.system(.subheadline, design: .rounded).monospacedDigit())
            Stepper("", value: $store.tempo, in: 30...220, step: 2)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .frame(height: TempoTheme.Layout.controlHeight)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: TempoTheme.Radius.control))
    }
}
