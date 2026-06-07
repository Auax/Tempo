import AppKit
import SwiftUI

struct PracticeToolbar: View {
    @Bindable var store: TempoStore

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(store.selectedPiece?.title ?? "Choose a score")
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(store.selectedPiece?.composer ?? "Tempo Library")
                    Text("•")
                    Text("Measure \(store.currentMeasure)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Practice Mode", selection: $store.practiceMode) {
                ForEach(PracticeMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.symbol)
                        .tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 128)

            HStack(spacing: 5) {
                Image(systemName: "metronome")
                    .foregroundStyle(store.isMetronomeEnabled ? Color.tempoPurple : .secondary)
                Text("\(store.tempo)")
                    .font(.system(.body, design: .rounded).monospacedDigit())
                Stepper("", value: $store.tempo, in: 30...220, step: 2)
                    .labelsHidden()
                    .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9))

            Button {
                store.isMetronomeEnabled.toggle()
            } label: {
                Image(systemName: store.isMetronomeEnabled ? "metronome.fill" : "metronome")
            }
            .help("Toggle Metronome")

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
            }
            .menuStyle(.button)
            .frame(width: 82)
            .help("Score Zoom")

            Button {
                withAnimation(TempoTheme.Motion.standard) {
                    store.focusMode.toggle()
                }
            } label: {
                Image(systemName: store.focusMode ? "arrow.down.right.and.arrow.up.left" : "viewfinder")
            }
            .help(store.focusMode ? "Exit Focus Mode" : "Focus Mode")

            Button {
                store.focusMode = true
                NSApp.keyWindow?.toggleFullScreen(nil)
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .help("Fullscreen Practice")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 20)
        .frame(height: TempoTheme.Layout.topBarHeight)
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
