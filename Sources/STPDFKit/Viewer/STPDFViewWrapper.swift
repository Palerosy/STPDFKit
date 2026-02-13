import SwiftUI
import PDFKit

/// UIViewRepresentable wrapper for Apple's PDFView with optional ink drawing overlay
struct STPDFViewWrapper: UIViewRepresentable {

    let document: PDFDocument
    @Binding var currentPageIndex: Int
    let configuration: STPDFConfiguration
    var annotationManager: STAnnotationManager?

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = configuration.scrollDirection == .vertical ? .vertical : .horizontal
        pdfView.usePageViewController(false)
        pdfView.pageShadowsEnabled = true
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Store reference
        context.coordinator.pdfView = pdfView

        // Pass PDFView reference to annotation manager
        annotationManager?.pdfView = pdfView

        // Create ink drawing overlay (initially hidden)
        let drawingView = STInkDrawingView()
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.isHidden = true
        drawingView.isUserInteractionEnabled = false
        drawingView.pdfView = pdfView
        container.addSubview(drawingView)
        NSLayoutConstraint.activate([
            drawingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            drawingView.topAnchor.constraint(equalTo: container.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.drawingView = drawingView

        // Set up stroke completion callback
        drawingView.onStrokeCompleted = { [weak annotationManager] pdfPoints, page in
            Task { @MainActor in
                annotationManager?.addInkAnnotation(points: [pdfPoints], on: page)
            }
        }

        // Register for page change notifications
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let drawingView = context.coordinator.drawingView else { return }

        // Navigate to page if binding changed externally
        if let targetPage = document.page(at: currentPageIndex),
           pdfView.currentPage != targetPage {
            pdfView.go(to: targetPage)
        }

        // Update annotation manager reference
        annotationManager?.pdfView = pdfView

        // Show/hide drawing overlay based on active tool
        let isDrawing = annotationManager?.activeTool?.isDrawingTool == true
        drawingView.isHidden = !isDrawing
        drawingView.isUserInteractionEnabled = isDrawing

        // Update drawing style
        if let style = annotationManager?.activeStyle {
            drawingView.strokeColor = style.color
            drawingView.strokeWidth = style.lineWidth
            drawingView.strokeOpacity = style.opacity
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject {
        let parent: STPDFViewWrapper
        weak var pdfView: PDFView?
        weak var drawingView: STInkDrawingView?

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
