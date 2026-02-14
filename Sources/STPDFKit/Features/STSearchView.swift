import SwiftUI
import PDFKit

/// In-document text search view
struct STSearchView: View {

    let document: PDFDocument
    let onResultSelected: (PDFSelection) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [PDFSelection] = []
    @State private var isSearching = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(STStrings.searchInDocument, text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                Divider()

                // Results
                if isSearching {
                    Spacer()
                    ProgressView(STStrings.searching)
                    Spacer()
                } else if results.isEmpty && !searchText.isEmpty {
                    Spacer()
                    Text(STStrings.noResultsFound)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(Array(results.enumerated()), id: \.offset) { index, selection in
                        Button {
                            onResultSelected(selection)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                if let page = selection.pages.first {
                                    let pageIndex = document.index(for: page)
                                    Text(STStrings.page(pageIndex + 1))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(contextString(for: selection))
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(STStrings.search)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(STStrings.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        results = []

        DispatchQueue.global(qos: .userInitiated).async {
            let found = document.findString(searchText, withOptions: .caseInsensitive)
            DispatchQueue.main.async {
                results = found
                isSearching = false
            }
        }
    }

    private func contextString(for selection: PDFSelection) -> String {
        selection.string ?? searchText
    }
}
