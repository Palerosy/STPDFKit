import PDFKit

/// All annotation tool types supported by STPDFKit
public enum STAnnotationType: String, CaseIterable, Identifiable, Sendable {
    // Phase 2 — Drawing
    case ink
    case highlighter
    
    // Phase 2 — Text
    case freeText
    
    // Phase 2 — Markup
    case textHighlight
    case textUnderline
    case textStrikeOut
    
    // Phase 3 — Shapes
    case rectangle
    case circle
    case line
    case arrow
    
    // Phase 3 — Other
    case signature
    case stamp
    case note
    case eraser
    
    public var id: String { rawValue }
    
    /// The PDFAnnotation subtype for this tool
    var pdfSubtype: PDFAnnotationSubtype? {
        switch self {
        case .ink, .highlighter, .signature: return .ink
        case .freeText: return .freeText
        case .textHighlight: return .highlight
        case .textUnderline: return .underline
        case .textStrikeOut: return .strikeOut
        case .rectangle: return .square
        case .circle: return .circle
        case .line, .arrow: return .line
        case .stamp: return .stamp
        case .note: return .text
        case .eraser: return nil
        }
    }
    
    /// Human readable display name
    public var displayName: String {
        switch self {
        case .ink: return "Pen"
        case .highlighter: return "Highlighter"
        case .freeText: return "Text"
        case .textHighlight: return "Highlight"
        case .textUnderline: return "Underline"
        case .textStrikeOut: return "Strikethrough"
        case .rectangle: return "Rectangle"
        case .circle: return "Circle"
        case .line: return "Line"
        case .arrow: return "Arrow"
        case .signature: return "Signature"
        case .stamp: return "Stamp"
        case .note: return "Note"
        case .eraser: return "Eraser"
        }
    }
    
    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .ink: return "pencil.tip"
        case .highlighter: return "highlighter"
        case .freeText: return "textformat"
        case .textHighlight: return "text.badge.star"
        case .textUnderline: return "underline"
        case .textStrikeOut: return "strikethrough"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.up.right"
        case .signature: return "signature"
        case .stamp: return "stamp"
        case .note: return "note.text"
        case .eraser: return "eraser"
        }
    }
    
    /// Whether this tool requires text selection (markup tools)
    var requiresTextSelection: Bool {
        switch self {
        case .textHighlight, .textUnderline, .textStrikeOut: return true
        default: return false
        }
    }
    
    /// Whether this tool uses freeform drawing
    var isDrawingTool: Bool {
        switch self {
        case .ink, .highlighter: return true
        default: return false
        }
    }
    
    /// Tools available in Phase 2
    public static var phase2Tools: [STAnnotationType] {
        [.ink, .highlighter, .freeText, .textHighlight, .textUnderline, .textStrikeOut]
    }
}
