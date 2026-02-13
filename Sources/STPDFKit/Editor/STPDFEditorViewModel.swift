import SwiftUI
import PDFKit

/// View mode for the editor
enum STViewMode {
    case viewer
    case annotations
    case documentEditor
}

/// Main ViewModel for the PDF editor
@MainActor
final class STPDFEditorViewModel: ObservableObject {

    let document: STPDFDocument
    let configuration: STPDFConfiguration
    var viewerViewModel: STPDFViewerViewModel
    let annotationManager: STAnnotationManager
    let serializer: STAnnotationSerializer

    @Published var viewMode: STViewMode = .viewer
    @Published var isAnnotationToolbarVisible = false

    init(document: STPDFDocument, configuration: STPDFConfiguration, openInPageEditor: Bool = false) {
        self.document = document
        self.configuration = configuration
        self.viewerViewModel = STPDFViewerViewModel(document: document)
        self.annotationManager = STAnnotationManager(document: document)
        self.serializer = STAnnotationSerializer(document: document)

        if openInPageEditor {
            viewMode = .documentEditor
        }
    }

    /// Toggle annotation mode
    func toggleAnnotationMode() {
        if viewMode == .annotations {
            viewMode = .viewer
            isAnnotationToolbarVisible = false
            annotationManager.deactivate()
        } else {
            viewMode = .annotations
            isAnnotationToolbarVisible = true
            serializer.startAutoSave()
        }
    }
}
