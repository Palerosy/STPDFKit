import Foundation

/// Groups of annotation tools shown in the toolbar
public enum STAnnotationGroup: String, CaseIterable, Identifiable {
    case drawing
    case text
    case markup
    
    public var id: String { rawValue }
    
    /// Display name for the group
    public var displayName: String {
        switch self {
        case .drawing: return "Draw"
        case .text: return "Text"
        case .markup: return "Markup"
        }
    }
    
    /// Default icon for the group (shows first tool's icon)
    public var iconName: String {
        switch self {
        case .drawing: return "pencil.tip"
        case .text: return "textformat"
        case .markup: return "highlighter"
        }
    }
    
    /// The annotation types in this group
    public var tools: [STAnnotationType] {
        switch self {
        case .drawing: return [.ink, .highlighter]
        case .text: return [.freeText]
        case .markup: return [.textHighlight, .textUnderline, .textStrikeOut]
        }
    }
    
    /// The default (first) tool in this group
    public var defaultTool: STAnnotationType {
        tools.first!
    }
}
