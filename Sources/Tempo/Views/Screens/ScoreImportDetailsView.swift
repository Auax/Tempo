import SwiftUI

struct ScoreImportDetailsView: View {
    @Bindable var store: TempoStore
    let pendingImport: PendingScoreImport

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var composer: String
    @State private var difficulty = PieceDifficulty.easy
    @State private var genre = PieceGenre.classical
    @State private var folderID: ScoreFolder.ID?

    init(store: TempoStore, pendingImport: PendingScoreImport) {
        self.store = store
        self.pendingImport = pendingImport
        _title = State(
            initialValue: pendingImport.parsedScore.title
                ?? URL(fileURLWithPath: pendingImport.originalFileName)
                    .deletingPathExtension()
                    .lastPathComponent
        )
        _composer = State(initialValue: pendingImport.parsedScore.composer ?? "")
    }

    private var suggestions: [String] {
        store.composerSuggestions(for: composer).filter {
            $0.localizedCaseInsensitiveCompare(composer) != .orderedSame
        }
    }

    private var canImport: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Import Score")
                    .font(.title2.weight(.semibold))
                Text("Review the details before adding this score to your library.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                field("Name") {
                    TextField("Score name", text: $title)
                        .textFieldStyle(.roundedBorder)
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

                HStack(alignment: .top, spacing: 18) {
                    field("Difficulty") {
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(PieceDifficulty.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }

                    field("Genre") {
                        Picker("Genre", selection: $genre) {
                            ForEach(PieceGenre.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                    }
                }

                field("Folder") {
                    Picker("Folder", selection: $folderID) {
                        Text("No Folder").tag(ScoreFolder.ID?.none)
                        ForEach(store.folders) { folder in
                            Text(folder.name).tag(Optional(folder.id))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }

            HStack {
                Text(pendingImport.originalFileName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Cancel") {
                    store.cancelImport()
                    dismiss()
                }
                .tempoBorderedButton()
                Button("Import Score") {
                    store.finishImport(
                        title: title,
                        composer: composer,
                        difficulty: difficulty,
                        genre: genre,
                        folderID: folderID
                    )
                    dismiss()
                }
                .tempoProminentButton()
                .disabled(!canImport)
            }
        }
        .padding(28)
        .frame(width: 520)
        .interactiveDismissDisabled()
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
