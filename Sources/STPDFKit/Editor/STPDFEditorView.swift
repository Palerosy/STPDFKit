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
                // Property inspector (shown above PDF when active)
                if viewModel.annotationManager.isPropertyInspectorVisible {
                    STPropertyInspector(annotationManager: viewModel.annotationManager)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // PDF Viewer
                STPDFViewerView(
                    viewModel: viewModel.viewerViewModel,
                    configuration: configuration,
                    annotationManager: viewModel.viewMode == .annotations ? viewModel.annotationManager : nil
                )

                // Annotation toolbar (replaces bottom bar in annotation mode)
                if viewModel.isAnnotationToolbarVisible {
                    STAnnotationToolbar(annotationManager: viewModel.annotationManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    STBottomBar(
                        viewModel: viewModel,
                        bookmarkManager: bookmarkManager
                    )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.isAnnotationToolbarVisible)
            .animation(.easeInOut(duration: 0.25), value: viewModel.annotationManager.isPropertyInspectorVisible)
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
            .onChange(of: viewModel.annotationManager.activeTool) { newTool in
                if newTool == nil && viewModel.viewMode == .annotations {
                    // Tool deactivated but still in annotation mode — keep toolbar
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
