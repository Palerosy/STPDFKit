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
            title: title ?? STStrings.untitled
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
            ZStack {
                VStack(spacing: 0) {
                    // PDF Viewer
                    STPDFViewerView(
                        viewModel: viewModel.viewerViewModel,
                        configuration: configuration,
                        annotationManager: viewModel.annotationManager,
                        isAnnotationModeActive: viewModel.isAnnotationToolbarVisible
                    )

                    // Bottom bar (hidden during annotation mode)
                    if !viewModel.isAnnotationToolbarVisible {
                        STBottomBar(viewModel: viewModel)
                    }
                }

                // Page thumbnail strip — floating overlay at bottom (edit mode only)
                if viewModel.isAnnotationToolbarVisible {
                    VStack {
                        Spacer()
                        STPageThumbnailStrip(
                            viewModel: viewModel.viewerViewModel,
                            onDismiss: { }
                        )
                        .padding(.bottom, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Floating annotation toolbar overlay
                if viewModel.isAnnotationToolbarVisible {
                    STFloatingToolbar(
                        annotationManager: viewModel.annotationManager,
                        onDone: { viewModel.toggleAnnotationMode() }
                    )
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.isAnnotationToolbarVisible)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.serializer.save()
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
                        // Annotation toggle
                        Button {
                            viewModel.toggleAnnotationMode()
                        } label: {
                            Image(systemName: "pencil.tip.crop.circle")
                                .font(.system(size: 18))
                                .foregroundColor(viewModel.viewMode == .annotations ? .accentColor : .primary)
                        }

                        if !viewModel.isAnnotationToolbarVisible {
                            STMoreMenu(
                                viewModel: viewModel,
                                bookmarkManager: bookmarkManager,
                                configuration: configuration
                            )
                        }
                    }
                }
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .thumbnails:
                    STThumbnailGridView(viewModel: viewModel.viewerViewModel)
                case .search:
                    STSearchView(
                        document: viewModel.document.pdfDocument,
                        onResultSelected: { selection in
                            if let page = selection.pages.first {
                                let index = viewModel.document.pdfDocument.index(for: page)
                                viewModel.viewerViewModel.goToPage(index)
                            }
                            // Highlight found text in yellow, then clear after 1.5s
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                viewModel.highlightSearchResult(selection)
                            }
                        }
                    )
                case .outline:
                    STOutlineView(
                        document: viewModel.document.pdfDocument,
                        onPageSelected: { index in
                            viewModel.viewerViewModel.goToPage(index)
                        }
                    )
                case .settings:
                    STSettingsView()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
