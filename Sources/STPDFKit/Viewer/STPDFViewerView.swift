import SwiftUI
import PDFKit

/// SwiftUI PDF viewer that combines the PDFView with overlays
struct STPDFViewerView: View {

    @ObservedObject var viewModel: STPDFViewerViewModel
    let configuration: STPDFConfiguration
    var annotationManager: STAnnotationManager?

    var body: some View {
        ZStack {
            STPDFViewWrapper(
                document: viewModel.document.pdfDocument,
                currentPageIndex: $viewModel.currentPageIndex,
                configuration: configuration,
                annotationManager: annotationManager
            )

            // Text input overlay (when freeText tool is active)
            if annotationManager?.activeTool == .freeText {
                STTextInputOverlay(
                    onSubmit: { text, screenPoint in
                        // Convert screen point to PDF coordinates and add annotation
                        // The annotation manager will handle this via the PDFView reference
                        if let pdfView = annotationManager?.pdfView,
                           let page = pdfView.page(for: screenPoint, nearest: true) {
                            let pdfPoint = pdfView.convert(screenPoint, to: page)
                            annotationManager?.addTextAnnotation(text: text, at: pdfPoint, on: page)
                        }
                    },
                    onCancel: { }
                )
            }

            // License watermark overlay (if unlicensed)
            if !STLicenseManager.shared.isLicensed {
                STLicenseWatermark()
            }
        }
    }
}
