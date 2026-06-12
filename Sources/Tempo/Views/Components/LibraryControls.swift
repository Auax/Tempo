import SwiftUI

private struct TempoControlFieldChrome<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 9) {
            content()
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

struct TempoTextField: View {
    let prompt: String
    @Binding var text: String
    var showsClearButton = true

    var body: some View {
        TempoControlFieldChrome {
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
            if showsClearButton, !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TempoSearchField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        TempoControlFieldChrome {
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
    }
}

struct TempoMenuPicker<Selection: Hashable>: View {
    @Binding var selection: Selection
    let options: [Selection]
    let label: (Selection) -> String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    if selection == option {
                        Label(label(option), systemImage: "checkmark")
                    } else {
                        Text(label(option))
                    }
                }
            }
        } label: {
            HStack(spacing: TempoTheme.Spacing.small) {
                Text(label(selection))
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

struct LibraryFilterTags: View {
    @Bindable var store: TempoStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TempoTheme.Spacing.small) {
                ForEach(LibraryQuickFilter.allCases) { filter in
                    filterChip(
                        filter.rawValue,
                        symbol: filter.symbol,
                        isSelected: store.libraryQuickFilter == filter
                    ) {
                        withAnimation(TempoTheme.Motion.quick) {
                            store.toggleLibraryQuickFilter(filter)
                        }
                    }
                }

                ForEach(activeDifficulties) { difficulty in
                    filterChip(
                        difficulty.rawValue,
                        isSelected: true,
                        isRemovable: true
                    ) {
                        withAnimation(TempoTheme.Motion.quick) {
                            _ = store.selectedDifficulties.remove(difficulty.rawValue)
                        }
                    }
                }

                ForEach(activeGenres) { genre in
                    filterChip(
                        genre.rawValue,
                        isSelected: true,
                        isRemovable: true
                    ) {
                        withAnimation(TempoTheme.Motion.quick) {
                            _ = store.selectedGenres.remove(genre.rawValue)
                        }
                    }
                }
            }
        }
    }

    private var activeDifficulties: [PieceDifficulty] {
        Array(PieceDifficulty.allCases).filter {
            store.selectedDifficulties.contains($0.rawValue)
        }
    }

    private var activeGenres: [PieceGenre] {
        Array(PieceGenre.allCases).filter {
            store.selectedGenres.contains($0.rawValue)
        }
    }

    private func filterChip(
        _ title: String,
        symbol: String? = nil,
        isSelected: Bool,
        isRemovable: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: TempoTheme.Spacing.small) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
                if isRemovable {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.bold))
                }
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isSelected ? Color.tempoBlue : .primary)
            .padding(.horizontal, TempoTheme.Spacing.medium)
            .frame(height: TempoTheme.Layout.controlHeight)
            .background(
                isSelected ? Color.tempoBlue.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
            )
            .overlay {
                RoundedRectangle(cornerRadius: TempoTheme.Radius.control)
                    .stroke(
                        isSelected ? Color.tempoBlue.opacity(0.65) : Color.tempoControlBorder,
                        lineWidth: 1
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: TempoTheme.Radius.control))
        }
        .buttonStyle(.plain)
        .help(isRemovable ? "Remove \(title) filter" : "Show \(title.lowercased()) scores")
    }
}

struct LibraryFilterMenuButton: View {
    @Bindable var store: TempoStore
    @State private var isFilterPopoverPresented = false
    @State private var draftQuickFilter: LibraryQuickFilter = .all
    @State private var draftDifficulties: Set<String> = []
    @State private var draftGenres: Set<String> = []

    var body: some View {
        Button {
            loadDraftFilters()
            isFilterPopoverPresented.toggle()
        } label: {
            HStack(spacing: TempoTheme.Spacing.small) {
                Image(systemName: "slider.horizontal.3")
                Text("Filters")
                if activeFilterCount > 0 {
                    Text(activeFilterCount, format: .number)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color.tempoBlue, in: Circle())
                }
            }
        }
        .tempoBorderedButton()
        .popover(
            isPresented: $isFilterPopoverPresented,
            arrowEdge: .top
        ) {
            filterPopover
        }
    }

    private var filterPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: TempoTheme.Spacing.large) {
                    filterSection("Library") {
                        ForEach(LibraryQuickFilter.allCases) { filter in
                            filterRow(
                                filter.rawValue,
                                symbol: filter.symbol,
                                count: quickFilterCount(filter),
                                isSelected: draftQuickFilter == filter
                            ) {
                                draftQuickFilter = filter
                            }
                        }
                    }

                    Divider()

                    filterSection("Difficulty") {
                        ForEach(PieceDifficulty.allCases) { difficulty in
                            filterRow(
                                difficulty.rawValue,
                                count: store.pieces.filter {
                                    $0.difficulty == difficulty.rawValue
                                }.count,
                                isSelected: draftDifficulties.contains(difficulty.rawValue)
                            ) {
                                toggle(difficulty.rawValue, in: &draftDifficulties)
                            }
                        }
                    }

                    Divider()

                    filterSection("Genres") {
                        ForEach(PieceGenre.allCases) { genre in
                            filterRow(
                                genre.rawValue,
                                count: store.pieces.filter {
                                    $0.genre == genre.rawValue
                                }.count,
                                isSelected: draftGenres.contains(genre.rawValue)
                            ) {
                                toggle(genre.rawValue, in: &draftGenres)
                            }
                        }
                    }
                }
                .padding(TempoTheme.Spacing.xLarge)
            }
            .frame(maxHeight: 360)

            Divider()

            HStack(spacing: TempoTheme.Spacing.medium) {
                Button {
                    draftQuickFilter = .all
                    draftDifficulties.removeAll()
                    draftGenres.removeAll()
                } label: {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                }
                .tempoBorderedButton()
                .frame(maxWidth: .infinity)

                Button {
                    withAnimation(TempoTheme.Motion.quick) {
                        store.libraryQuickFilter = draftQuickFilter
                        store.selectedDifficulties = draftDifficulties
                        store.selectedGenres = draftGenres
                    }
                    isFilterPopoverPresented = false
                } label: {
                    Text(applyButtonTitle)
                        .frame(maxWidth: .infinity)
                }
                .tempoProminentButton()
                .frame(maxWidth: .infinity)
            }
            .padding(TempoTheme.Spacing.large)
        }
        .frame(width: 300)
    }

    private var activeFilterCount: Int {
        (store.libraryQuickFilter == .all ? 0 : 1)
            + store.selectedDifficulties.count
            + store.selectedGenres.count
    }

    private var draftFilterCount: Int {
        (draftQuickFilter == .all ? 0 : 1)
            + draftDifficulties.count
            + draftGenres.count
    }

    private var applyButtonTitle: String {
        draftFilterCount == 0 ? "Apply" : "Apply (\(draftFilterCount))"
    }

    private func filterSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: TempoTheme.Spacing.medium) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    private func filterRow(
        _ title: String,
        symbol: String? = nil,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: TempoTheme.Spacing.medium) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.tempoBlue : .secondary)
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(.secondary)
                        .frame(width: TempoTheme.Spacing.large)
                }
                Text(title)
                Spacer()
                Text(count, format: .number)
                    .foregroundStyle(.secondary)
            }
            .font(.body)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadDraftFilters() {
        draftQuickFilter = store.libraryQuickFilter
        draftDifficulties = store.selectedDifficulties
        draftGenres = store.selectedGenres
    }

    private func quickFilterCount(_ filter: LibraryQuickFilter) -> Int {
        switch filter {
        case .all:
            store.pieces.count
        case .recent:
            store.pieces.filter {
                Calendar.current.dateComponents(
                    [.day],
                    from: $0.lastPracticed,
                    to: .now
                ).day ?? 0 <= 30
            }.count
        case .favorites:
            store.pieces.filter(\.isFavorite).count
        }
    }

    private func toggle(_ value: String, in set: inout Set<String>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}

#if DEBUG
private struct LibraryControlsPreview: View {
    @State private var text = "Debussy"
    @State private var sort = LibrarySort.lastOpened

    var body: some View {
        VStack(spacing: 16) {
            TempoTextField(prompt: "Composer", text: $text)
            TempoSearchField(prompt: "Search scores", text: $text)
            TempoMenuPicker(
                selection: $sort,
                options: LibrarySort.allCases,
                label: \.rawValue
            )
            LibrarySortPicker(selection: $sort)
            HStack(spacing: TempoTheme.Spacing.medium) {
                LibraryFilterTags(store: PreviewFixtures.store())
                LibraryFilterMenuButton(store: PreviewFixtures.store())
            }
        }
        .padding()
        .frame(width: 360)
    }
}

#Preview("Library Controls") {
    LibraryControlsPreview()
}
#endif
