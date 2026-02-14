import UIKit
import PDFKit

// MARK: - STLineAnnotation

/// Custom PDFAnnotation subclass for line and arrow annotations.
///
/// Apple's PDFKit CATiledLayer does NOT reliably render dynamically-added
/// `.line` annotations (same problem as `.ink`). This subclass draws the
/// line (and optional arrowhead) directly in the page graphics context.
///
/// Supports move, proportional scale, and live style changes.
final class STLineAnnotation: PDFAnnotation {

    private(set) var lineStart: CGPoint
    private(set) var lineEnd: CGPoint
    private(set) var lineStrokeWidth: CGFloat
    private(set) var lineColor: UIColor
    private(set) var hasArrowHead: Bool

    /// Bounds at last bake — used to calculate transform deltas in draw(with:in:).
    private var originalBounds: CGRect

    init(bounds: CGRect, start: CGPoint, end: CGPoint, strokeWidth: CGFloat, color: UIColor, arrowHead: Bool) {
        self.lineStart = start
        self.lineEnd = end
        self.lineStrokeWidth = strokeWidth
        self.lineColor = color
        self.hasArrowHead = arrowHead
        self.originalBounds = bounds
        super.init(bounds: bounds, forType: .line, withProperties: nil)

        // Standard properties for PDF serialization
        self.startPoint = start
        self.endPoint = end
        self.color = color
        let border = PDFBorder()
        border.lineWidth = strokeWidth
        self.border = border
        if arrowHead {
            self.endLineStyle = .closedArrow
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Accessors

    func getStartPoint() -> CGPoint { lineStart }
    func getEndPoint() -> CGPoint { lineEnd }

    // MARK: - Style

    func applyStyle(color: UIColor, strokeWidth: CGFloat) {
        lineColor = color
        lineStrokeWidth = strokeWidth
        self.color = color
        let border = PDFBorder()
        border.lineWidth = strokeWidth
        self.border = border
    }

    // MARK: - Transform (move + scale)

    /// Bake current bounds offset + scale into line endpoints permanently.
    func applyBoundsOffset() {
        let dx = bounds.origin.x - originalBounds.origin.x
        let dy = bounds.origin.y - originalBounds.origin.y
        let sx = originalBounds.width > 0 ? bounds.width / originalBounds.width : 1.0
        let sy = originalBounds.height > 0 ? bounds.height / originalBounds.height : 1.0

        let needsTranslation = dx != 0 || dy != 0
        let needsScale = abs(sx - 1.0) > 0.001 || abs(sy - 1.0) > 0.001
        guard needsTranslation || needsScale else { return }

        func transform(_ pt: CGPoint) -> CGPoint {
            CGPoint(
                x: originalBounds.origin.x + (pt.x - originalBounds.origin.x) * sx + dx,
                y: originalBounds.origin.y + (pt.y - originalBounds.origin.y) * sy + dy
            )
        }

        lineStart = transform(lineStart)
        lineEnd = transform(lineEnd)

        if needsScale {
            lineStrokeWidth *= min(sx, sy)
            let border = PDFBorder()
            border.lineWidth = lineStrokeWidth
            self.border = border
        }

        // Sync standard properties for serialization
        self.startPoint = lineStart
        self.endPoint = lineEnd
        originalBounds = bounds
    }

    // MARK: - Rendering

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let dx = bounds.origin.x - originalBounds.origin.x
        let dy = bounds.origin.y - originalBounds.origin.y
        let sx = originalBounds.width > 0 ? bounds.width / originalBounds.width : 1.0
        let sy = originalBounds.height > 0 ? bounds.height / originalBounds.height : 1.0

        func transform(_ pt: CGPoint) -> CGPoint {
            CGPoint(
                x: originalBounds.origin.x + (pt.x - originalBounds.origin.x) * sx + dx,
                y: originalBounds.origin.y + (pt.y - originalBounds.origin.y) * sy + dy
            )
        }

        let start = transform(lineStart)
        let end = transform(lineEnd)
        let effectiveWidth = lineStrokeWidth * min(sx, sy)

        context.saveGState()
        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(effectiveWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        // Main line
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        // Arrowhead
        if hasArrowHead {
            let headLength = max(10, effectiveWidth * 4)
            let headAngle: CGFloat = .pi / 6
            let angle = atan2(end.y - start.y, end.x - start.x)

            let p1 = CGPoint(
                x: end.x - headLength * cos(angle - headAngle),
                y: end.y - headLength * sin(angle - headAngle)
            )
            let p2 = CGPoint(
                x: end.x - headLength * cos(angle + headAngle),
                y: end.y - headLength * sin(angle + headAngle)
            )

            context.move(to: p1)
            context.addLine(to: end)
            context.addLine(to: p2)
            context.strokePath()
        }

        context.restoreGState()
    }
}

// MARK: - STShapeDrawingView

/// GPU-accelerated shape drawing overlay for PDFKit.
///
/// Strategy — immediate commit, no persistent overlays:
/// - During drawing: CAShapeLayer provides real-time shape preview.
/// - On touchesEnded: annotation is committed to the page, overlay removed immediately.
/// - PDFView renders the annotation natively — no overlay accumulation.
/// - Tool switch / long-press never loses annotations (they're already in the PDF).
final class STShapeDrawingView: UIView {

    /// Called each time a shape is committed as an annotation (for undo recording).
    var onShapeCommitted: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?

    /// Reference to the hosting PDFView (set by STPDFViewWrapper).
    weak var pdfView: PDFView?

    /// Active shape type
    var shapeType: STAnnotationType = .rectangle

    /// Shape appearance — kept in sync by STPDFViewWrapper.updateUIView().
    var strokeColor: UIColor = .systemBlue
    var strokeWidth: CGFloat = 2.0
    var strokeOpacity: CGFloat = 1.0

    // MARK: - Private state

    private var startPoint: CGPoint?
    private var currentLayer: CAShapeLayer?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        clipsToBounds = false
    }

    // MARK: - Public

    /// Cancel any in-progress shape (e.g. when tool switches mid-draw).
    func clearCurrentShape() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        startPoint = touch.location(in: self)

        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.withAlphaComponent(strokeOpacity).cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        layer.addSublayer(shapeLayer)
        currentLayer = shapeLayer
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let start = startPoint,
              let shapeLayer = currentLayer else { return }

        let current = touch.location(in: self)
        shapeLayer.path = shapePath(from: start, to: current).cgPath
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let start = startPoint else {
            cancelShape()
            return
        }

        let end = touch.location(in: self)

        // Minimum size check
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        let minDist: CGFloat = (shapeType == .line || shapeType == .arrow) ? 10 : 15
        guard max(dx, dy) >= minDist else {
            cancelShape()
            return
        }

        currentLayer?.path = shapePath(from: start, to: end).cgPath
        commitShape(start: start, end: end)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelShape()
    }

    // MARK: - Private

    private func cancelShape() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
    }

    private func shapePath(from start: CGPoint, to end: CGPoint) -> UIBezierPath {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        switch shapeType {
        case .rectangle:
            return UIBezierPath(rect: rect)
        case .circle:
            return UIBezierPath(ovalIn: rect)
        case .line:
            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            return path
        case .arrow:
            return arrowPath(from: start, to: end)
        default:
            return UIBezierPath(rect: rect)
        }
    }

    private func arrowPath(from start: CGPoint, to end: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)

        // Arrowhead
        let headLength: CGFloat = max(15, strokeWidth * 4)
        let headAngle: CGFloat = .pi / 6

        let angle = atan2(end.y - start.y, end.x - start.x)

        let arrowPoint1 = CGPoint(
            x: end.x - headLength * cos(angle - headAngle),
            y: end.y - headLength * sin(angle - headAngle)
        )
        let arrowPoint2 = CGPoint(
            x: end.x - headLength * cos(angle + headAngle),
            y: end.y - headLength * sin(angle + headAngle)
        )

        path.move(to: arrowPoint1)
        path.addLine(to: end)
        path.addLine(to: arrowPoint2)

        return path
    }

    /// Commit the shape as a PDFAnnotation and remove the overlay immediately.
    private func commitShape(start: CGPoint, end: CGPoint) {
        guard let pdfView = pdfView else {
            cancelShape()
            return
        }

        // Find the PDF page under the shape center
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let centerInPDFView = convert(center, to: pdfView)
        guard let page = pdfView.page(for: centerInPDFView, nearest: true) else {
            cancelShape()
            return
        }

        // Convert screen → page coordinates
        let startInPDF = convert(start, to: pdfView)
        let endInPDF = convert(end, to: pdfView)
        let pageStart = pdfView.convert(startInPDF, to: page)
        let pageEnd = pdfView.convert(endInPDF, to: page)

        // Build and add annotation
        let annotation = buildAnnotation(pageStart: pageStart, pageEnd: pageEnd, page: page)
        page.addAnnotation(annotation)

        // Notify for undo recording
        onShapeCommitted?(annotation, page)

        // Remove overlay immediately — PDF annotation takes over rendering
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil

        // Force PDFView to re-render the annotation area
        if annotation is STLineAnnotation {
            // Custom-drawn annotations need full subtree invalidation
            pdfView.layoutDocumentView()
            func invalidate(_ view: UIView) {
                view.setNeedsDisplay()
                view.layer.setNeedsDisplay()
                for sublayer in view.layer.sublayers ?? [] {
                    sublayer.setNeedsDisplay()
                }
                for child in view.subviews { invalidate(child) }
            }
            invalidate(pdfView)
        } else {
            pdfView.setNeedsDisplay()
        }
    }

    private func buildAnnotation(pageStart: CGPoint, pageEnd: CGPoint, page: PDFPage) -> PDFAnnotation {
        let pad = max(strokeWidth, 2) * 2

        switch shapeType {
        case .line, .arrow:
            return buildLineAnnotation(start: pageStart, end: pageEnd, padding: pad)
        case .circle:
            return buildCircleAnnotation(start: pageStart, end: pageEnd)
        default:
            return buildRectAnnotation(start: pageStart, end: pageEnd)
        }
    }

    private func buildLineAnnotation(start: CGPoint, end: CGPoint, padding: CGFloat) -> PDFAnnotation {
        let minX = min(start.x, end.x) - padding
        let minY = min(start.y, end.y) - padding
        let maxX = max(start.x, end.x) + padding
        let maxY = max(start.y, end.y) + padding
        let bounds = CGRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))

        return STLineAnnotation(
            bounds: bounds,
            start: start,
            end: end,
            strokeWidth: strokeWidth,
            color: strokeColor.withAlphaComponent(strokeOpacity),
            arrowHead: shapeType == .arrow
        )
    }

    private func buildRectAnnotation(start: CGPoint, end: CGPoint) -> PDFAnnotation {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        let bounds = CGRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))

        let annotation = PDFAnnotation(bounds: bounds, forType: .square, withProperties: nil)
        annotation.color = strokeColor.withAlphaComponent(strokeOpacity)

        let border = PDFBorder()
        border.lineWidth = strokeWidth
        annotation.border = border

        return annotation
    }

    private func buildCircleAnnotation(start: CGPoint, end: CGPoint) -> PDFAnnotation {
        let minX = min(start.x, end.x)
        let minY = min(start.y, end.y)
        let maxX = max(start.x, end.x)
        let maxY = max(start.y, end.y)
        let bounds = CGRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))

        let annotation = PDFAnnotation(bounds: bounds, forType: .circle, withProperties: nil)
        annotation.color = strokeColor.withAlphaComponent(strokeOpacity)

        let border = PDFBorder()
        border.lineWidth = strokeWidth
        annotation.border = border

        return annotation
    }
}
