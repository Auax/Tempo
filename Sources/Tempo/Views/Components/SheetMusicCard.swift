import AppKit
import SwiftUI

struct SheetMusicCard: View {
    let piece: Piece
    @Bindable var store: TempoStore
    var showsActions = true

    @State private var previewImage: NSImage?
    @State private var isHovered = false

    private var previewKey: String {
        "\(piece.id)-\(piece.previewImagePath ?? "missing")"
    }

    private var practicedText: String {
        let relativeDate = TempoFormatters.relativeDate.localizedString(
            for: piece.lastPracticed,
            relativeTo: .now
        )
        return "Last practiced \(relativeDate)"
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
                scorePreview

                VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                    Text(piece.title.isEmpty ? "Untitled Score" : piece.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(piece.composer.isEmpty ? "Unknown composer" : piece.composer)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(practicedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.82)
                        .lineLimit(1)
                        .padding(.top, TempoTheme.Spacing.xSmall)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                store.selectPiece(piece, startPractice: true)
            }

            if showsActions {
                cardActions
                    .padding(TempoTheme.Spacing.small)
            }
        }
        .contentShape(Rectangle())
        // .scaleEffect(isHovered ? 1.008 : 1)
        .animation(TempoTheme.Motion.quick, value: isHovered)
        .onHover { hovering in
            withAnimation(TempoTheme.Motion.quick) {
                isHovered = hovering
            }
        }
        .task(id: previewKey) {
            previewImage = await store.scorePreviewImage(for: piece.id)
        }
    }

    private var scorePreview: some View {
        ZStack {
            Color.tempoScorePaper

            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, TempoTheme.Spacing.large)
                    .padding(.vertical, TempoTheme.Spacing.medium)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.16))
            }

            hoverOverlay
                .opacity(isHovered ? 1 : 0)
        }
        .animation(TempoTheme.Motion.quick, value: isHovered)
        .aspectRatio(0.75, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: TempoTheme.Radius.medium))
        .overlay {
            RoundedRectangle(cornerRadius: TempoTheme.Radius.medium)
                .stroke(Color.primary.opacity(0.14), lineWidth: 1)
        }
        .shadow(
            color: .black.opacity(isHovered ? 0.16 : 0.09),
            radius: isHovered ? 12 : 7,
            y: isHovered ? 5 : 3
        )
    }

    private var hoverOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)

            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 7)

                Circle()
                    .trim(from: 0, to: max(clampedProgress, 0.01))
                    .stroke(
                        Color.tempoBlue,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(
                    clampedProgress,
                    format: .percent.precision(.fractionLength(0))
                )
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.white)
                .monospacedDigit()
            }
            .frame(width: 76, height: 76)
            .shadow(color: .white.opacity(0.18), radius: 10, y: 0)
        }
        .allowsHitTesting(false)
    }

    private var clampedProgress: Double {
        min(max(piece.progress, 0), 1)
    }

    private var cardActions: some View {
        HStack {
            Button {
                store.toggleFavorite(piece.id)
            } label: {
                Image(systemName: piece.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(piece.isFavorite ? Color.tempoBlue : Color.white)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(piece.isFavorite ? "Remove from Favorites" : "Add to Favorites")
            .opacity(piece.isFavorite || isHovered ? 1 : 0)
            .allowsHitTesting(piece.isFavorite || isHovered)

            Spacer()

            LibraryPieceMenu(piece: piece, store: store)
                .frame(width: 28, height: 28)
                .opacity(isHovered ? 1 : 0)
                .allowsHitTesting(isHovered)
        }
    }
}

#if DEBUG
#Preview("Sheet Music Card") {
    SheetMusicCard(
        piece: PreviewFixtures.piece,
        store: PreviewFixtures.store()
    )
    .padding()
    .frame(width: 240)
}
#endif
