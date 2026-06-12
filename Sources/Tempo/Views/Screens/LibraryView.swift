import SwiftUI

struct LibraryView: View {
    @Bindable var store: TempoStore
    @State private var openFolderID: ScoreFolder.ID?
    @State private var openComposer: String?

    private var libraryContentPadding: CGFloat { TempoTheme.Spacing.xLarge }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: TempoTheme.Spacing.xxLarge) {
                libraryHeader
                sectionBar
            }
            .padding(.horizontal, libraryContentPadding)
            .padding(.top, libraryContentPadding)

            Group {
                switch store.librarySection {
                case .allScores:
                    allScoresView
                case .folders:
                    foldersView
                case .composers:
                    composersView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.primary.opacity(0.025))
    }

    private var libraryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                Text("Library")
                    .font(.largeTitle.weight(.semibold))
                // Text("Manage and organize your scores")
                //     .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            headerActions
        }
    }

    private var sectionBar: some View {
        HStack(alignment: .bottom, spacing: TempoTheme.Spacing.xLarge) {
            HStack(alignment: .bottom, spacing: TempoTheme.Spacing.xLarge) {
                ForEach(LibrarySection.allCases) { section in
                    Button {
                        withAnimation(TempoTheme.Motion.quick) {
                            store.librarySection = section
                            openFolderID = nil
                            openComposer = nil
                        }
                    } label: {
                        HStack(spacing: TempoTheme.Spacing.small) {
                            Text(section.rawValue)
                            Text(sectionCount(section), format: .number)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, TempoTheme.Spacing.small)
                                .padding(.vertical, TempoTheme.Spacing.xSmall)
                                .background(.primary.opacity(0.07), in: Capsule())
                        }
                        .font(.subheadline.weight(.semibold))
                        .padding(.bottom, TempoTheme.Spacing.medium + 2)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(
                                    store.librarySection == section
                                        ? Color.tempoBlue
                                        : .clear
                                )
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(
                        store.librarySection == section ? Color.tempoBlue : .primary
                    )
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 0)

            if store.librarySection == .allScores {
                LibraryFilterMenuButton(store: store)
            }
        }
        .padding(.bottom, TempoTheme.Spacing.medium)
    }

    private var headerActions: some View {
        HStack(spacing: TempoTheme.Spacing.medium) {
            if store.librarySection == .allScores {
                TempoSearchField(
                    prompt: "Search a score",
                    text: $store.searchText
                )
                .frame(maxWidth: TempoTheme.Layout.librarySearchMaxWidth)
            }

            if store.librarySection == .folders, openFolderID == nil {
                newFolderButton
            }

            importScoreButton
        }
    }

    private var newFolderButton: some View {
        Button {
            store.showingNewFolder = true
        } label: {
            Label("New Folder", systemImage: "folder.badge.plus")
        }
        .tempoBorderedButton()
    }

    private var importScoreButton: some View {
        Button {
            store.showingImporter = true
        } label: {
            Label("Import Score", systemImage: "square.and.arrow.down")
        }
        .tempoProminentButton()
    }

    private var allScoresView: some View {
        // VStack(spacing: 0) {
            // HStack(spacing: TempoTheme.Spacing.medium) {
            //     LibraryFilterTags(store: store)
            // }
            // .padding(.horizontal, TempoTheme.Spacing.xLarge)
            // .padding(.top, TempoTheme.Spacing.small)

        scoreResults(for: store.filteredPieces)
        // }
        // .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func scoreResults(for pieces: [Piece]) -> some View {
        if pieces.isEmpty {
            ContentUnavailableView {
                Label("No Scores Found", systemImage: "music.note.list")
            } description: {
                Text("Import a MusicXML score or clear the current filters.")
            } actions: {
                Button("Import Score") {
                    store.showingImporter = true
                }
                .tempoProminentButton()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                libraryScoresGrid(pieces)
            }
            .padding(.horizontal, TempoTheme.Spacing.xLarge)
            .padding(.top, TempoTheme.Spacing.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func libraryScoresGrid(_ pieces: [Piece]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(
                        minimum: TempoTheme.Layout.libraryScoreCardMin,
                        maximum: TempoTheme.Layout.libraryScoreCardMin
                    ),
                    spacing: TempoTheme.Spacing.large
                )
            ],
            alignment: .leading,
            spacing: TempoTheme.Spacing.large
        ) {
            ForEach(pieces) { piece in
                SheetMusicCard(piece: piece, store: store)
                    .frame(
                        width: TempoTheme.Layout.libraryScoreCardMin,
                        alignment: .top
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var foldersView: some View {
        if let folderID = openFolderID,
           let folder = store.folders.first(where: { $0.id == folderID }) {
            browseDetail(
                title: folder.name,
                pieces: store.pieces(in: folder),
                emptyTitle: "No Scores in Folder",
                emptyDescription: "Move scores into this folder from the score menu."
            ) {
                withAnimation(TempoTheme.Motion.quick) {
                    openFolderID = nil
                }
            }
        } else if store.folders.isEmpty {
            ContentUnavailableView {
                Label("No Folders Yet", systemImage: "folder")
            } description: {
                Text("Create a folder to organize your scores.")
            }             actions: {
                Button("New Folder") {
                    store.showingNewFolder = true
                }
                .tempoProminentButton()
            }
            .padding(.top, TempoTheme.Spacing.xLarge)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: TempoTheme.Layout.libraryBrowseCardMin),
                            spacing: TempoTheme.Spacing.large
                        )
                    ],
                    spacing: TempoTheme.Spacing.large
                ) {
                    ForEach(filteredFolders) { folder in
                        Button {
                            withAnimation(TempoTheme.Motion.quick) {
                                openFolderID = folder.id
                            }
                        } label: {
                            HStack(spacing: TempoTheme.Spacing.medium) {
                                Image(systemName: "folder.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.tempoBlue)
                                VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                                    Text(folder.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text("\(store.pieceCount(in: folder)) scores")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .tempoCard()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, TempoTheme.Spacing.xLarge)
                .padding(.top, TempoTheme.Spacing.xLarge)
                .padding(.bottom, TempoTheme.Spacing.xLarge)
            }
        }
    }

    @ViewBuilder
    private var composersView: some View {
        if let composer = openComposer {
            browseDetail(
                title: composer,
                pieces: store.pieces(by: composer),
                emptyTitle: "No Scores Found",
                emptyDescription: "This composer has no scores in your library."
            ) {
                withAnimation(TempoTheme.Motion.quick) {
                    openComposer = nil
                }
            }
        } else if filteredComposers.isEmpty {
            ContentUnavailableView(
                "No Composers Found",
                systemImage: "person.2",
                description: Text("Composer names appear here after importing scores.")
            )
            .padding(.top, TempoTheme.Spacing.xLarge)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: TempoTheme.Layout.libraryBrowseCardMin),
                            spacing: TempoTheme.Spacing.large
                        )
                    ],
                    spacing: TempoTheme.Spacing.large
                ) {
                    ForEach(filteredComposers, id: \.self) { composer in
                        Button {
                            withAnimation(TempoTheme.Motion.quick) {
                                openComposer = composer
                            }
                        } label: {
                            HStack(spacing: TempoTheme.Spacing.medium) {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.tempoBlue)
                                VStack(alignment: .leading, spacing: TempoTheme.Spacing.xSmall) {
                                    Text(composer)
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text("\(store.pieceCount(by: composer)) scores")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .tempoCard()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, TempoTheme.Spacing.xLarge)
                .padding(.top, TempoTheme.Spacing.xLarge)
                .padding(.bottom, TempoTheme.Spacing.xLarge)
            }
        }
    }

    private func browseDetail(
        title: String,
        pieces: [Piece],
        emptyTitle: String,
        emptyDescription: String,
        onBack: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: TempoTheme.Spacing.medium) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(
                            width: TempoTheme.Layout.controlHeight,
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
                        .contentShape(
                            RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
                        )
                }
                .buttonStyle(.plain)

                Text(title)
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, TempoTheme.Spacing.xLarge)
            .padding(.top, TempoTheme.Spacing.xLarge)

            if pieces.isEmpty {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: "music.note.list")
                } description: {
                    Text(emptyDescription)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    libraryScoresGrid(pieces)
                }
                .padding(.horizontal, TempoTheme.Spacing.xLarge)
                .padding(.top, TempoTheme.Spacing.large)
                .padding(.bottom, TempoTheme.Spacing.xLarge)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var filteredFolders: [ScoreFolder] {
        guard !store.searchText.isEmpty else { return store.folders }
        return store.folders.filter {
            $0.name.localizedCaseInsensitiveContains(store.searchText)
        }
    }

    private var filteredComposers: [String] {
        guard !store.searchText.isEmpty else { return store.composers }
        return store.composers.filter {
            $0.localizedCaseInsensitiveContains(store.searchText)
        }
    }

    private func sectionCount(_ section: LibrarySection) -> Int {
        switch section {
        case .allScores: store.pieces.count
        case .folders: store.folders.count
        case .composers: store.composers.count
        }
    }
}

#if DEBUG
#Preview("Library") {
    LibraryView(store: PreviewFixtures.store())
        .frame(width: 1_080, height: 760)
}
#endif
