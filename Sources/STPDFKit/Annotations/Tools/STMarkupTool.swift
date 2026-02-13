import SwiftUI
import PDFKit

/// Manages text markup annotations (highlight, underline, strikethrough).
/// When a markup tool is active, the user selects text in the PDF and
/// the selection is converted to the appropriate markup annotation.
@MainActor
final class STMarkupToolHandler: ObservableObject {
    
    private weak var pdfView: PDFView?
    private var selectionObserver: NSObjectProtocol?
    
    /// Callback when markup should be applied
    var onMarkupSelection: ((_ selections: [PDFSelection], _ page: PDFPage) -> Void)?
    
    func activate(pdfView: PDFView) {
        self.pdfView = pdfView
        
        // Observe selection changes in PDFView
        selectionObserver = NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] notification in
            self?.handleSelectionChange()
        }
    }
    
    func deactivate() {
        if let observer = selectionObserver {
            NotificationCenter.default.removeObserver(observer)
            selectionObserver = nil
        }
        pdfView?.clearSelection()
        pdfView = nil
    }
    
    /// Apply markup to current selection
    func applyMarkupToCurrentSelection() {
        guard let pdfView = pdfView,
              let selection = pdfView.currentSelection else { return }
        
        let pages = selection.pages
        for page in pages {
            let selectionForPage = selection.selectionsByLine()
            onMarkupSelection?(selectionForPage, page)
        }
        
        pdfView.clearSelection()
    }
    
    private func handleSelectionChange() {
        // Selection changed — UI can show "Apply" button
    }
}

/// A small floating button shown when text is selected during markup mode
struct STMarkupApplyButton: View {
    
    let onApply: () -> Void
    let toolType: STAnnotationType
    
    var body: some View {
        Button {
            onApply()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: toolType.iconName)
                Text("Apply \(toolType.displayName)")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.tint)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 4)
        }
    }
}
