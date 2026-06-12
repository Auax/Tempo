import SwiftUI

struct ScoreImportDetailsView: View {
    @Bindable var store: TempoStore
    private let pendingImport: PendingScoreImport?
    private let editingPiece: Piece?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var composer: String
    @State private var difficulty = PieceDifficulty.easy
    @State private var genre = PieceGenre.classical
    @State private var folderID: ScoreFolder.ID?
    @State private var isSaving = false

    init(store: TempoStore, pendingImport: PendingScoreImport) {
        self.store = store
        self.pendingImport = pendingImport
        editingPiece = nil
        _title = State(
            initialValue: pendingImport.parsedScore.title
                ?? URL(fileURLWithPath: pendingImport.originalFileName)
                    .deletingPathExtension()
                    .lastPathComponent
        )
        _composer = State(initialValue: pendingImport.parsedScore.composer ?? "")
    }

    init(store: TempoStore, piece: Piece) {
        self.store = store
        pendingImport = nil
        editingPiece = piece
        _title = State(initialValue: piece.title)
        _composer = State(initialValue: piece.composer)
        _difficulty = State(
            initialValue: PieceDifficulty(rawValue: piece.difficulty) ?? .easy
        )
        _genre = State(
            initialValue: PieceGenre(rawValue: piece.genre) ?? .classical
        )
        _folderID = State(initialValue: piece.folderID)
    }

    private var isEditing: Bool {
        editingPiece != nil
    }

    private var modalTitle: String {
        isEditing ? "Edit Score" : "Import Score"
    }

    private var primaryActionTitle: String {
        isEditing ? "Save Changes" : "Import Score"
    }

    private var displayedFileName: String {
        pendingImport?.originalFileName
            ?? editingPiece?.fileName
            ?? editingPiece?.scorePath.map { URL(fileURLWithPath: $0).lastPathComponent }
            ?? ""
    }

    private var suggestions: [String] {
        store.composerSuggestions(for: composer).filter {
            $0.localizedCaseInsensitiveCompare(composer) != .orderedSame
        }
    }

    private var canImport: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedFolderName: String {
        guard let folderID,
              let folder = store.folders.first(where: { $0.id == folderID })
        else {
            return "No Folder"
        }
        return folder.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.xLarge) {
            VStack(alignment: .leading, spacing: 5) {
                Text(modalTitle)
                    .font(.title2.weight(.semibold))
                Text(
                    isEditing
                        ? "Update the details for this score."
                        : "Review the details before adding this score to your library."
                )
                .foregroundStyle(.secondary)
            }

            detailsSection

            HStack(spacing: TempoTheme.Spacing.medium) {
                Text(displayedFileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Cancel") {
                    if isEditing {
                        store.editingPiece = nil
                    } else {
                        store.cancelImport()
                    }
                    dismiss()
                }
                .tempoBorderedButton()
                Button(primaryActionTitle) {
                    Task {
                        isSaving = true
                        await save()
                        dismiss()
                    }
                }
                .tempoProminentButton()
                .disabled(!canImport || isSaving)
            }
        }
        .padding(28)
        .frame(width: 480)
        .interactiveDismissDisabled()
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            field("Name") {
                TempoTextField(prompt: "Score name", text: $title)
            }

            field("Composer") {
                VStack(alignment: .leading, spacing: 6) {
                    TempoSearchField(prompt: "Type or create a composer", text: $composer)

                    if !suggestions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    composer = suggestion
                                } label: {
                                    HStack {
                                        Image(systemName: "person")
                                            .foregroundStyle(.secondary)
                                        Text(suggestion)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .frame(height: TempoTheme.Layout.controlHeight)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.primary.opacity(0.1))
                        }
                    }
                }
            }

            HStack(alignment: .top, spacing: TempoTheme.Spacing.large) {
                field("Difficulty") {
                    TempoMenuPicker(
                        selection: $difficulty,
                        options: Array(PieceDifficulty.allCases),
                        label: \.rawValue
                    )
                }

                field("Genre") {
                    TempoMenuPicker(
                        selection: $genre,
                        options: Array(PieceGenre.allCases),
                        label: \.rawValue
                    )
                }
            }

            field("Folder") {
                folderPicker
            }
        }
    }

    private var folderPicker: some View {
        Menu {
            Button {
                folderID = nil
            } label: {
                if folderID == nil {
                    Label("No Folder", systemImage: "checkmark")
                } else {
                    Text("No Folder")
                }
            }
            ForEach(store.folders) { folder in
                Button {
                    folderID = folder.id
                } label: {
                    if folderID == folder.id {
                        Label(folder.name, systemImage: "checkmark")
                    } else {
                        Text(folder.name)
                    }
                }
            }
        } label: {
            HStack(spacing: TempoTheme.Spacing.small) {
                Text(selectedFolderName)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.subheadline)
            .padding(.horizontal, TempoTheme.Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: TempoTheme.Layout.controlHeight, alignment: .leading)
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

    private func save() async {
        if let editingPiece {
            store.finishEditing(
                pieceID: editingPiece.id,
                title: title,
                composer: composer,
                difficulty: difficulty,
                genre: genre,
                folderID: folderID
            )
        } else {
            await store.finishImport(
                title: title,
                composer: composer,
                difficulty: difficulty,
                genre: genre,
                folderID: folderID
            )
        }
    }

    private func field<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NewFolderView: View {
    @Bindable var store: TempoStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("New Folder")
                    .font(.title2.weight(.semibold))
                Text("Create a folder to organize related scores.")
                    .foregroundStyle(.secondary)
            }

            TextField("Folder name", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .tempoBorderedButton()
                Button("Create Folder") {
                    store.createFolder(named: name)
                    dismiss()
                }
                .tempoProminentButton()
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(26)
        .frame(width: 400)
    }
}

#if DEBUG
#Preview("Import Score") {
    ScoreImportDetailsView(
        store: PreviewFixtures.store(),
        pendingImport: PreviewFixtures.pendingImport
    )
}

#Preview("Edit Score") {
    ScoreImportDetailsView(
        store: PreviewFixtures.store(),
        piece: PreviewFixtures.piece
    )
}

#Preview("New Folder") {
    NewFolderView(store: PreviewFixtures.store())
}
#endif
