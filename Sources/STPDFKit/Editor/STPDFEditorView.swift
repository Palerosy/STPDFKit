import SwiftUI
import PDFKit

/// The main PDF editor view — drop-in replacement for PSPDFKitEditorView.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STPDFEditorView(url: pdfURL, title: "My Document") {
///         showEditor = false
///     }
///     .ignoresSafeArea()
/// }
/// ```
public struct STPDFEditorView: View {

    private let url: URL
    private let title: String?
    private let openInPageEditor: Bool
    private let configuration: STPDFConfiguration
    private let onDismiss: (() -> Void)?

    @StateObject private var viewModel: STPDFEditorViewModel
    @StateObject private var bookmarkManager: STBookmarkManager

    public init(
        url: URL,
        title: String? = nil,
        openInPageEditor: Bool = false,
        configuration: STPDFConfiguration = .default,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.openInPageEditor = openInPageEditor
        self.configuration = configuration
        self.onDismiss = onDismiss

        let doc = STPDFDocument(url: url, title: title) ?? STPDFDocument(
            document: PDFDocument(),
            url: url,
            title: title ?? "Untitled"
        )

        _viewModel = StateObject(wrappedValue: STPDFEditorViewModel(
            document: doc,
            configuration: configuration,
            openInPageEditor: openInPageEditor
        ))
        _bookmarkManager = StateObject(wrappedValue: STBookmarkManager(documentURL: url))
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // PDF Viewer
                STPDFViewerView(
                    viewModel: viewModel.viewerViewModel,
                    configuration: configuration
                )

                // Bottom bar
                STBottomBar(
                    viewModel: viewModel,
                    bookmarkManager: bookmarkManager
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.document.save()
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(viewModel.document.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Annotation toggle (placeholder for Phase 2)
                        // Button { } label: { Image(systemName: "pencil.tip") }

                        STMoreMenu(
                            viewModel: viewModel,
                            bookmarkManager: bookmarkManager,
                            configuration: configuration
                        )
                    }
                }
            }
            .sheet(isPresented: $viewModel.viewerViewModel.isThumbnailGridVisible) {
                STThumbnailGridView(viewModel: viewModel.viewerViewModel) { index in
                    viewModel.viewerViewModel.goToPage(index)
                    viewModel.viewerViewModel.isThumbnailGridVisible = false
                }
            }
            .sheet(isPresented: $viewModel.viewerViewModel.isSearchVisible) {
                STSearchView(
                    document: viewModel.document.pdfDocument,
                    onResultSelected: { selection in
                        // Navigate to selected search result
                        if let page = selection.pages.first {
                            let index = viewModel.document.pdfDocument.index(for: page)
                            viewModel.viewerViewModel.goToPage(index)
                        }
                    },
                    isPresented: $viewModel.viewerViewModel.isSearchVisible
                )
            }
            .sheet(isPresented: $viewModel.viewerViewModel.isOutlineVisible) {
                STOutlineView(
                    document: viewModel.document.pdfDocument,
                    onPageSelected: { index in
                        viewModel.viewerViewModel.goToPage(index)
                    },
                    isPresented: $viewModel.viewerViewModel.isOutlineVisible
                )
            }
            .sheet(isPresented: $viewModel.viewerViewModel.isSettingsVisible) {
                STSettingsView(isPresented: $viewModel.viewerViewModel.isSettingsVisible)
            }
        }
        .navigationViewStyle(.stack)
    }
}
