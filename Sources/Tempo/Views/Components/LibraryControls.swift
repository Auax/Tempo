import SwiftUI

struct TempoSearchField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: TempoTheme.Layout.controlHeight)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
                .stroke(.primary.opacity(0.11))
        }
    }
}

struct LibrarySortPicker: View {
    @Binding var selection: LibrarySort

    var body: some View {
        Menu {
            ForEach(LibrarySort.allCases) { option in
                Button {
                    selection = option
                } label: {
                    if selection == option {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: TempoTheme.Spacing.small) {
                Text("Sort by")
                    .foregroundStyle(.secondary)
                Text(selection.rawValue)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.subheadline)
            .padding(.horizontal, TempoTheme.Spacing.medium)
            .frame(
                width: TempoTheme.Layout.librarySortPickerWidth,
                height: TempoTheme.Layout.controlHeight
            )
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
                    .stroke(Color.tempoControlBorder, lineWidth: 1)
            }
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
    }
}

struct ScoreGradientArtwork: View {
    let piece: Piece

    private var palette: [Color] {
        let palettes: [[Color]] = [
            [.tempoBlue.opacity(0.95), Color(red: 0.10, green: 0.20, blue: 0.38)],
            [Color(red: 0.05, green: 0.55, blue: 0.66), Color(red: 0.10, green: 0.22, blue: 0.34)],
            [Color(red: 0.74, green: 0.34, blue: 0.48), Color(red: 0.28, green: 0.13, blue: 0.32)],
            [Color(red: 0.76, green: 0.48, blue: 0.16), Color(red: 0.27, green: 0.19, blue: 0.12)],
            [Color(red: 0.26, green: 0.58, blue: 0.40), Color(red: 0.08, green: 0.24, blue: 0.24)]
        ]
        let value = piece.title.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palettes[value % palettes.count]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: palette,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 150, height: 150)
                .blur(radius: 1)
                .offset(x: 80, y: -70)

            LinearGradient(
                colors: [.clear, .black.opacity(0.28)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                Text(piece.title)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                if !piece.composer.isEmpty {
                    Text(piece.composer)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .padding(18)
        }
        .aspectRatio(0.78, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .topLeading) {
            if piece.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(Color.tempoBlue, in: RoundedRectangle(cornerRadius: 7))
                    .padding(9)
            }
        }
    }
}
