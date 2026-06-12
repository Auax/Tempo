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
            Button {
                store.selectPiece(piece, startPractice: true)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    scorePreview

                    VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
                        VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                            Text(piece.title.isEmpty ? "Untitled Score" : piece.title)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Text(piece.composer.isEmpty ? "Unknown composer" : piece.composer)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        VStack(alignment: .leading, spacing: TempoTheme.Spacing.small) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                    Capsule()
                                        .fill(Color.tempoBlue)
                                        .frame(
                                            width: max(
                                                geometry.size.width * piece.progress,
                                                6
                                            )
                                        )
                                }
                            }
                            .frame(height: 5)

                            HStack(spacing: TempoTheme.Spacing.xSmall) {
                                Text(
                                    piece.progress,
                                    format: .percent.precision(.fractionLength(0))
                                )
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.tempoBlue)

                                Text("•")
                                    .foregroundStyle(.tertiary)

                                Text(practicedText)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(TempoTheme.Spacing.large)
                }
                .background(Color.tempoControlSurface)
                .clipShape(RoundedRectangle(cornerRadius: TempoTheme.Radius.medium))
                .overlay {
                    RoundedRectangle(cornerRadius: TempoTheme.Radius.medium)
                        .stroke(Color.tempoControlBorder, lineWidth: 1)
                }
                // .shadow(
                //     color: .black.opacity(isHovered ? 0.15 : 0.09),
                //     radius: isHovered ? 14 : 8,
                //     y: isHovered ? 6 : 3
                // )
                .contentShape(RoundedRectangle(cornerRadius: TempoTheme.Radius.medium))
            }
            .buttonStyle(.plain)

            if showsActions {
                cardActions
                    .padding(TempoTheme.Spacing.small)
            }
        }
        .scaleEffect(isHovered ? 1.012 : 1)
        .animation(TempoTheme.Motion.quick, value: isHovered)
        .onHover { isHovered = $0 }
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
                    .padding(.horizontal, TempoTheme.Spacing.small)
                    .padding(.bottom, TempoTheme.Spacing.xSmall)
                    .padding(.top, TempoTheme.Spacing.small)
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.16))
            }
        }
        .aspectRatio(1.8, contentMode: .fit)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(height: 1)
        }
    }

    private var cardActions: some View {
        HStack {
            Button {
                store.toggleFavorite(piece.id)
            } label: {
                Image(systemName: piece.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.tempoBlue)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(piece.isFavorite ? "Remove from Favorites" : "Add to Favorites")
            .opacity(piece.isFavorite || isHovered ? 1 : 0)
            .allowsHitTesting(piece.isFavorite || isHovered)

            Spacer()

            LibraryPieceMenu(piece: piece, store: store)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
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
    .frame(width: 290)
}
#endif
