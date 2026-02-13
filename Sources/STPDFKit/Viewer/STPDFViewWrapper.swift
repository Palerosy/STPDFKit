import SwiftUI
import PDFKit

/// UIViewRepresentable wrapper for Apple's PDFView
struct STPDFViewWrapper: UIViewRepresentable {

    let document: PDFDocument
    @Binding var currentPageIndex: Int
    let configuration: STPDFConfiguration

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = configuration.scrollDirection == .vertical ? .vertical : .horizontal
        pdfView.usePageViewController(false)
        pdfView.pageShadowsEnabled = true

        // Register for page change notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Navigate to page if binding changed externally
        if let targetPage = document.page(at: currentPageIndex),
           pdfView.currentPage != targetPage {
            pdfView.go(to: targetPage)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject {
        let parent: STPDFViewWrapper

        init(parent: STPDFViewWrapper) {
            self.parent = parent
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }

            DispatchQueue.main.async {
                if self.parent.currentPageIndex != pageIndex {
                    self.parent.currentPageIndex = pageIndex
                }
            }
        }
    }
}
