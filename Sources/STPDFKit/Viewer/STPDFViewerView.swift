import SwiftUI
import PDFKit

/// SwiftUI PDF viewer that combines the PDFView with overlays
struct STPDFViewerView: View {

    @ObservedObject var viewModel: STPDFViewerViewModel
    let configuration: STPDFConfiguration

    var body: some View {
        ZStack {
            STPDFViewWrapper(
                document: viewModel.document.pdfDocument,
                currentPageIndex: $viewModel.currentPageIndex,
                configuration: configuration
            )

            // License watermark overlay (if unlicensed)
            if !STLicenseManager.shared.isLicensed {
                STLicenseWatermark()
            }
        }
    }
}
