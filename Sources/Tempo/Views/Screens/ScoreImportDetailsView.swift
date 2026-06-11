import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
    @State private var artwork = ScoreArtwork.default
    @State private var customArtworkData: Data?
    @State private var showingArtworkImporter = false

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
        _artwork = State(initialValue: piece.artwork)
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

    private var previewScoreXML: String? {
        pendingImport?.parsedScore.xml
    }

    private var previewScorePath: String? {
        editingPiece?.scorePath
    }

    private var suggestions: [String] {
        store.composerSuggestions(for: composer).filter {
            $0.localizedCaseInsensitiveCompare(composer) != .orderedSame
        }
    }

    private var canImport: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var customArtworkImage: NSImage? {
        customArtworkData.flatMap(NSImage.init(data:))
    }

    private var isUsingCustomArtwork: Bool {
        customArtworkData != nil || artwork.customImagePath != nil
    }

    private var selectedFolderName: String {
        guard let folderID,
              let folder = store.folders.first(where: { $0.id == folderID })
        else {
            return "No Folder"
        }
        return folder.name
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

    var body: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.xLarge) {
            VStack(alignment: .leading, spacing: 5) {
                Text(modalTitle)
                    .font(.title2.weight(.semibold))
                Text("Review the details and create the artwork shown in your library.")
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: TempoTheme.Spacing.xLarge) {
                ScrollView {
                    VStack(alignment: .leading, spacing: TempoTheme.Spacing.xLarge) {
                        detailsSection
                        artworkSection
                        customizationSection
                    }
                    .padding(.trailing, TempoTheme.Spacing.small)
                }
                .frame(maxWidth: .infinity, maxHeight: 650)

                VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
                    HStack {
                        Text("Preview")
                            .font(.headline)
                        Spacer()
                        Text("Library artwork")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ScoreArtworkView(
                        title: title,
                        composer: composer,
                        artwork: artwork,
                        difficulty: difficulty.rawValue,
                        genre: genre.rawValue,
                        scoreXML: previewScoreXML,
                        scorePath: previewScorePath,
                        overrideImage: customArtworkImage
                    )
                    .frame(width: 330)
                }
                .frame(width: 330)
            }

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
                    save()
                    dismiss()
                }
                .tempoProminentButton()
                .disabled(!canImport)
            }
        }
        .padding(28)
        .frame(width: 940, height: 780)
        .interactiveDismissDisabled()
        .fileImporter(
            isPresented: $showingArtworkImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            loadCustomArtwork(from: url)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            sectionTitle("Score details", subtitle: "Used throughout your library and practice view.")

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
        .tempoCard()
    }

    private var artworkSection: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            sectionTitle("Select artwork", subtitle: "Choose a preset or use your own image.")

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                spacing: 10
            ) {
                ForEach(ScoreArtworkPreset.allCases) { preset in
                    Button {
                        customArtworkData = nil
                        artwork.customImagePath = nil
                        artwork.preset = preset
                        artwork.usesDarkText = preset.prefersDarkText
                        artwork.overlayOpacity = preset.prefersDarkText ? 0.08 : 0.24
                    } label: {
                        presetThumbnail(preset)
                        .aspectRatio(0.78, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    artwork.preset == preset && !isUsingCustomArtwork
                                        ? Color.tempoBlue
                                        : Color.clear,
                                    lineWidth: 3
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(preset.title)
                    .help(preset.title)
                }
            }

            Button {
                showingArtworkImporter = true
            } label: {
                Label(
                    isUsingCustomArtwork ? "Replace Custom Image" : "Upload Custom Image",
                    systemImage: "photo.badge.plus"
                )
                .frame(maxWidth: .infinity)
            }
            .tempoBorderedButton()
        }
        .tempoCard()
    }

    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
            sectionTitle("Customize", subtitle: "Fine-tune typography and image framing.")

            field("Text alignment") {
                Picker("Text alignment", selection: $artwork.textAlignment) {
                    ForEach(ScoreArtworkTextAlignment.allCases) { alignment in
                        Label(alignment.title, systemImage: alignment.systemImage)
                            .tag(alignment)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            HStack(spacing: TempoTheme.Spacing.large) {
                labeledSlider(
                    "Title size",
                    value: $artwork.titleScale,
                    range: 0.78...1.18,
                    valueLabel: "\(Int(artwork.titleScale * 100))%"
                )
                labeledSlider(
                    "Overlay",
                    value: $artwork.overlayOpacity,
                    range: 0...0.55,
                    valueLabel: "\(Int(artwork.overlayOpacity * 100))%"
                )
            }

            field("Text color") {
                HStack(spacing: 8) {
                    colorChoice("Light", dark: false, swatch: .white)
                    colorChoice("Dark", dark: true, swatch: .black)
                }
            }

            HStack(spacing: TempoTheme.Spacing.large) {
                labeledSlider(
                    "Horizontal position",
                    value: $artwork.imageOffsetX,
                    range: -1...1,
                    valueLabel: positionLabel(artwork.imageOffsetX)
                )
                labeledSlider(
                    "Vertical position",
                    value: $artwork.imageOffsetY,
                    range: -1...1,
                    valueLabel: positionLabel(artwork.imageOffsetY)
                )
            }
        }
        .tempoCard()
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func labeledSlider(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        valueLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(valueLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            Slider(value: value, in: range)
        }
        .frame(maxWidth: .infinity)
    }

    private func colorChoice(_ label: String, dark: Bool, swatch: Color) -> some View {
        Button {
            artwork.usesDarkText = dark
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(swatch)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.primary.opacity(0.22)))
                Text(label)
                Spacer()
                if artwork.usesDarkText == dark {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.tempoBlue)
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: TempoTheme.Layout.controlHeight)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        artwork.usesDarkText == dark
                            ? Color.tempoBlue
                            : Color.tempoControlBorder
                    )
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func presetThumbnail(_ preset: ScoreArtworkPreset) -> some View {
        if let image = ScoreArtworkImageLoader.image(for: preset) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.secondary.opacity(0.12)
        }
    }

    private func positionLabel(_ value: Double) -> String {
        if abs(value) < 0.08 {
            return "Center"
        }
        return value < 0 ? "−\(Int(abs(value) * 100))" : "+\(Int(value * 100))"
    }

    private func loadCustomArtwork(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        guard let data = try? Data(contentsOf: url), NSImage(data: data) != nil else { return }
        customArtworkData = data
        artwork.customImagePath = nil
    }

    private func save() {
        if let editingPiece {
            store.finishEditing(
                pieceID: editingPiece.id,
                title: title,
                composer: composer,
                difficulty: difficulty,
                genre: genre,
                folderID: folderID,
                artwork: artwork,
                customArtworkData: customArtworkData
            )
        } else {
            store.finishImport(
                title: title,
                composer: composer,
                difficulty: difficulty,
                genre: genre,
                folderID: folderID,
                artwork: artwork,
                customArtworkData: customArtworkData
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
