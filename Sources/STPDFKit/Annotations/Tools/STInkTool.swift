import UIKit
import PDFKit

/// A transparent overlay view that captures touch events for ink/highlighter drawing.
/// Uses CAShapeLayer for GPU-accelerated 60fps rendering during active strokes.
/// When a stroke completes, it converts to a PDFAnnotation and clears the overlay.
class STInkDrawingView: UIView {
    
    /// Callback when a stroke is completed with PDF-space points
    var onStrokeCompleted: ((_ pdfPoints: [CGPoint], _ page: PDFPage) -> Void)?
    
    /// Reference to the PDFView for coordinate conversion
    weak var pdfView: PDFView?
    
    /// Current stroke style
    var strokeColor: UIColor = .systemBlue
    var strokeWidth: CGFloat = 3.0
    var strokeOpacity: CGFloat = 1.0
    
    /// Active stroke data
    private var currentPoints: [CGPoint] = []
    private var currentLayer: CAShapeLayer?
    private var currentPath: UIBezierPath?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        currentPoints = [point]
        
        // Create a new shape layer for this stroke
        let layer = CAShapeLayer()
        layer.strokeColor = strokeColor.withAlphaComponent(strokeOpacity).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = strokeWidth
        layer.lineCap = .round
        layer.lineJoin = .round
        self.layer.addSublayer(layer)
        currentLayer = layer
        
        // Start the path
        let path = UIBezierPath()
        path.move(to: point)
        currentPath = path
        layer.path = path.cgPath
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let path = currentPath,
              let layer = currentLayer else { return }
        
        let point = touch.location(in: self)
        currentPoints.append(point)
        
        // Add line to path and update layer
        path.addLine(to: point)
        layer.path = path.cgPath
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishStroke()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Clear without committing
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        currentPath = nil
        currentPoints = []
    }
    
    private func finishStroke() {
        defer {
            // Clear the visual overlay
            currentLayer?.removeFromSuperlayer()
            currentLayer = nil
            currentPath = nil
            currentPoints = []
        }
        
        guard let pdfView = pdfView,
              currentPoints.count >= 2 else { return }
        
        // Find which page the stroke is on (use the midpoint of the stroke)
        let midIndex = currentPoints.count / 2
        let midScreenPoint = currentPoints[midIndex]
        
        // Convert screen point to PDFView's coordinate space
        let pdfViewPoint = convert(midScreenPoint, to: pdfView)
        guard let page = pdfView.page(for: pdfViewPoint, nearest: true) else { return }
        
        // Convert all screen points to PDF page coordinates
        let pdfPoints = currentPoints.map { screenPoint -> CGPoint in
            let viewPoint = convert(screenPoint, to: pdfView)
            return pdfView.convert(viewPoint, to: page)
        }
        
        onStrokeCompleted?(pdfPoints, page)
    }
}
