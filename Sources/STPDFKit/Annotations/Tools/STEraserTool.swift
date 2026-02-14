import UIKit
import PDFKit

/// Transparent overlay that handles eraser touches — taps or drags over annotations to remove them.
final class STEraserOverlayView: UIView {

    /// Called when an annotation is erased (for undo recording).
    var onAnnotationErased: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?

    /// Reference to the hosting PDFView.
    weak var pdfView: PDFView?

    /// Annotations that are built-in and should not be erased (e.g. links, widgets)
    private static let protectedSubtypes: Set<String> = ["Link", "Widget"]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        eraseAt(touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        eraseAt(touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        eraseAt(touch.location(in: self))
    }

    // MARK: - Private

    private func eraseAt(_ point: CGPoint) {
        guard let pdfView = pdfView else { return }

        let pointInPDFView = convert(point, to: pdfView)
        guard let page = pdfView.page(for: pointInPDFView, nearest: false) else { return }

        let pointInPage = pdfView.convert(pointInPDFView, to: page)

        // Hit test: find annotation at this point
        let hitRadius: CGFloat = 10
        let hitRect = CGRect(
            x: pointInPage.x - hitRadius,
            y: pointInPage.y - hitRadius,
            width: hitRadius * 2,
            height: hitRadius * 2
        )

        for annotation in page.annotations.reversed() {
            // Skip protected annotations (links, widgets)
            if let subtype = annotation.type,
               Self.protectedSubtypes.contains(subtype) {
                continue
            }

            if annotation.bounds.intersects(hitRect) {
                let isImage = annotation is STImageAnnotation || annotation is STStampAnnotation
                page.removeAnnotation(annotation)
                onAnnotationErased?(annotation, page)

                // Nuclear redraw for custom-drawn annotations (CATiledLayer cache)
                if isImage {
                    nuclearPDFViewRedraw(pdfView)
                } else {
                    forcePDFViewRedraw(pdfView)
                }

                // Haptic feedback
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                return
            }
        }
    }

    private func forcePDFViewRedraw(_ pdfView: PDFView) {
        pdfView.layoutDocumentView()
        func invalidate(_ view: UIView) {
            view.setNeedsDisplay()
            view.layer.setNeedsDisplay()
            for sublayer in view.layer.sublayers ?? [] {
                sublayer.setNeedsDisplay()
            }
            for child in view.subviews {
                invalidate(child)
            }
        }
        invalidate(pdfView)
    }

    private func nuclearPDFViewRedraw(_ pdfView: PDFView) {
        let doc = pdfView.document
        let currentPage = pdfView.currentPage
        pdfView.document = nil
        pdfView.document = doc
        if let page = currentPage {
            pdfView.go(to: page)
        }
    }
}
