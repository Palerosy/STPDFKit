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

    @Published var viewMode: STViewMode = .viewer
    @Published var isAnnotationToolbarVisible = false

    init(document: STPDFDocument, configuration: STPDFConfiguration, openInPageEditor: Bool = false) {
        self.document = document
        self.configuration = configuration
        self.viewerViewModel = STPDFViewerViewModel(document: document)

        if openInPageEditor {
            viewMode = .documentEditor
        }
    }
}
