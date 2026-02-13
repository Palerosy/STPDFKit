import SwiftUI
import PDFKit

/// Central manager for annotation state and operations
@MainActor
final class STAnnotationManager: ObservableObject {
    
    /// Currently active annotation tool (nil = viewer mode)
    @Published var activeTool: STAnnotationType? = nil
    
    /// Current style for the active tool
    @Published var activeStyle: STAnnotationStyle = .defaultStyle(for: .ink)
    
    /// Selected tool within each group (remembers last used variant)
    @Published var selectedToolPerGroup: [STAnnotationGroup: STAnnotationType] = [
        .drawing: .ink,
        .text: .freeText,
        .markup: .textHighlight
    ]
    
    /// Whether the property inspector is showing
    @Published var isPropertyInspectorVisible = false
    
    /// Reference to the PDF view (set by STPDFViewWrapper)
    weak var pdfView: PDFView?
    
    /// The undo manager
    let undoManager = STUndoManager()
    
    /// The document being annotated
    let document: STPDFDocument
    
    init(document: STPDFDocument) {
        self.document = document
    }
    
    /// Set the active tool and update style to match
    func setTool(_ type: STAnnotationType?) {
        activeTool = type
        if let type = type {
            activeStyle = STAnnotationStyle.defaultStyle(for: type)
        }
    }
    
    /// Toggle a tool on/off
    func toggleTool(_ type: STAnnotationType) {
        if activeTool == type {
            activeTool = nil
        } else {
            setTool(type)
            // Remember selected variant in group
            for group in STAnnotationGroup.allCases where group.tools.contains(type) {
                selectedToolPerGroup[group] = type
            }
        }
    }
    
    /// Add an ink annotation from collected points
    func addInkAnnotation(points: [[CGPoint]], on page: PDFPage) {
        guard !points.isEmpty else { return }
        
        // Calculate bounds from all points
        let allPoints = points.flatMap { $0 }
        guard !allPoints.isEmpty else { return }
        
        let padding = activeStyle.lineWidth * 2
        let minX = allPoints.map(\.x).min()! - padding
        let minY = allPoints.map(\.y).min()! - padding
        let maxX = allPoints.map(\.x).max()! + padding
        let maxY = allPoints.map(\.y).max()! + padding
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)
        
        // Create bezier paths for each stroke
        for stroke in points {
            guard stroke.count >= 2 else { continue }
            let path = UIBezierPath()
            path.move(to: stroke[0])
            for i in 1..<stroke.count {
                path.addLine(to: stroke[i])
            }
            annotation.add(path)
        }
        
        // Apply style
        annotation.color = activeStyle.color.withAlphaComponent(activeStyle.opacity)
        annotation.border = PDFBorder()
        annotation.border?.lineWidth = activeStyle.lineWidth
        
        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))
    }
    
    /// Add a free text annotation
    func addTextAnnotation(text: String, at pdfPoint: CGPoint, on page: PDFPage) {
        guard !text.isEmpty else { return }
        
        let font = UIFont(name: activeStyle.fontName, size: activeStyle.fontSize) ?? .systemFont(ofSize: activeStyle.fontSize)
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 8
        
        let bounds = CGRect(
            x: pdfPoint.x,
            y: pdfPoint.y - textSize.height - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.font = font
        annotation.fontColor = activeStyle.color
        annotation.color = .clear // Background color
        annotation.alignment = .left
        
        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))
    }
    
    /// Add a text markup annotation (highlight, underline, strikethrough)
    func addMarkupAnnotation(type: STAnnotationType, selections: [PDFSelection], on page: PDFPage) {
        guard let subtype = type.pdfSubtype else { return }
        
        for selection in selections {
            let bounds = selection.bounds(for: page)
            guard bounds.width > 0 && bounds.height > 0 else { continue }
            
            let annotation = PDFAnnotation(bounds: bounds, forType: subtype, withProperties: nil)
            annotation.color = activeStyle.color.withAlphaComponent(activeStyle.opacity)
            
            page.addAnnotation(annotation)
            undoManager.record(.add(annotation: annotation, page: page))
        }
    }
    
    /// Remove an annotation (eraser)
    func removeAnnotation(_ annotation: PDFAnnotation, from page: PDFPage) {
        page.removeAnnotation(annotation)
        undoManager.record(.remove(annotation: annotation, page: page))
    }
    
    /// Exit annotation mode
    func deactivate() {
        activeTool = nil
        isPropertyInspectorVisible = false
    }
}
