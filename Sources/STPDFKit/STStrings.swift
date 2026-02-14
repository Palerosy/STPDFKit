import Foundation

/// Type-safe localized strings for STPDFKit
enum STStrings {
    // MARK: - Navigation & Controls
    static var done: String { loc("stpdfkit.done") }
    static var pages: String { loc("stpdfkit.pages") }
    static var bookmark: String { loc("stpdfkit.bookmark") }
    static var search: String { loc("stpdfkit.search") }
    static var settings: String { loc("stpdfkit.settings") }
    static var outline: String { loc("stpdfkit.outline") }
    static var editPages: String { loc("stpdfkit.editPages") }
    static var share: String { loc("stpdfkit.share") }
    static var print: String { loc("stpdfkit.print") }
    static var saveAsText: String { loc("stpdfkit.saveAsText") }
    static var untitled: String { loc("stpdfkit.untitled") }

    // MARK: - Search
    static var searchInDocument: String { loc("stpdfkit.searchInDocument") }
    static var searching: String { loc("stpdfkit.searching") }
    static var noResultsFound: String { loc("stpdfkit.noResultsFound") }
    static func page(_ number: Int) -> String {
        String(format: loc("stpdfkit.page"), number)
    }

    // MARK: - Outline
    static var noOutlineAvailable: String { loc("stpdfkit.noOutlineAvailable") }

    // MARK: - Settings
    static var display: String { loc("stpdfkit.display") }
    static var scrollDirection: String { loc("stpdfkit.scrollDirection") }
    static var pageMode: String { loc("stpdfkit.pageMode") }
    static var view: String { loc("stpdfkit.view") }
    static var pageShadows: String { loc("stpdfkit.pageShadows") }
    static var backgroundColor: String { loc("stpdfkit.backgroundColor") }

    // MARK: - Property Inspector
    static var color: String { loc("stpdfkit.color") }
    static var width: String { loc("stpdfkit.width") }
    static var fontSize: String { loc("stpdfkit.fontSize") }
    static var opacity: String { loc("stpdfkit.opacity") }
    static var font: String { loc("stpdfkit.font") }

    // MARK: - Annotation Tools
    static var toolPen: String { loc("stpdfkit.tool.pen") }
    static var toolHighlighter: String { loc("stpdfkit.tool.highlighter") }
    static var toolText: String { loc("stpdfkit.tool.text") }
    static var toolHighlight: String { loc("stpdfkit.tool.highlight") }
    static var toolUnderline: String { loc("stpdfkit.tool.underline") }
    static var toolStrikethrough: String { loc("stpdfkit.tool.strikethrough") }
    static var toolRectangle: String { loc("stpdfkit.tool.rectangle") }
    static var toolCircle: String { loc("stpdfkit.tool.circle") }
    static var toolLine: String { loc("stpdfkit.tool.line") }
    static var toolArrow: String { loc("stpdfkit.tool.arrow") }
    static var toolSignature: String { loc("stpdfkit.tool.signature") }
    static var toolStamp: String { loc("stpdfkit.tool.stamp") }
    static var toolNote: String { loc("stpdfkit.tool.note") }
    static var toolEraser: String { loc("stpdfkit.tool.eraser") }
    static var toolPhoto: String { loc("stpdfkit.tool.photo") }
    static var toolTextEdit: String { loc("stpdfkit.tool.textEdit") }
    static var tapOnTextToEdit: String { loc("stpdfkit.tapOnTextToEdit") }
    static var selectionWord: String { loc("stpdfkit.selection.word") }
    static var selectionLine: String { loc("stpdfkit.selection.line") }

    // MARK: - Toolbar Labels
    static var hand: String { loc("stpdfkit.hand") }
    static var undo: String { loc("stpdfkit.undo") }
    static var redo: String { loc("stpdfkit.redo") }
    static var select: String { loc("stpdfkit.select") }
    static var style: String { loc("stpdfkit.style") }
    static var close: String { loc("stpdfkit.close") }
    static var zoomIn: String { loc("stpdfkit.zoomIn") }
    static var zoomOut: String { loc("stpdfkit.zoomOut") }
    static var addText: String { loc("stpdfkit.addText") }
    static var removeText: String { loc("stpdfkit.removeText") }

    // MARK: - Annotation Groups
    static var groupDraw: String { loc("stpdfkit.group.draw") }
    static var groupShapes: String { loc("stpdfkit.group.shapes") }
    static var groupText: String { loc("stpdfkit.group.text") }
    static var groupMarkup: String { loc("stpdfkit.group.markup") }
    static var groupExtras: String { loc("stpdfkit.group.extras") }

    // MARK: - Text Input
    static var enterText: String { loc("stpdfkit.enterText") }
    static var cancel: String { loc("stpdfkit.cancel") }
    static var add: String { loc("stpdfkit.add") }

    // MARK: - Markup
    static func applyTool(_ toolName: String) -> String {
        String(format: loc("stpdfkit.applyTool"), toolName)
    }

    // MARK: - Signature
    static var signatureClear: String { loc("stpdfkit.signature.clear") }
    static var signatureDrawNew: String { loc("stpdfkit.signature.drawNew") }
    static var signatureSaved: String { loc("stpdfkit.signature.saved") }

    // MARK: - Stamp Types
    static var stampApproved: String { loc("stpdfkit.stamp.approved") }
    static var stampRejected: String { loc("stpdfkit.stamp.rejected") }
    static var stampDraft: String { loc("stpdfkit.stamp.draft") }
    static var stampConfidential: String { loc("stpdfkit.stamp.confidential") }
    static var stampForComment: String { loc("stpdfkit.stamp.forComment") }
    static var stampAsIs: String { loc("stpdfkit.stamp.asIs") }
    static var stampFinal: String { loc("stpdfkit.stamp.final") }

    // MARK: - Placement
    static var tapToPlace: String { loc("stpdfkit.tapToPlace") }

    // MARK: - Selection Menu
    static var selectionCopy: String { loc("stpdfkit.selection.copy") }
    static var selectionPaste: String { loc("stpdfkit.selection.paste") }
    static var selectionDelete: String { loc("stpdfkit.selection.delete") }
    static var selectionInspector: String { loc("stpdfkit.selection.inspector") }
    static var selectionNote: String { loc("stpdfkit.selection.note") }

    // MARK: - Tool Hints
    static var hintDraw: String { loc("stpdfkit.hint.draw") }
    static var hintShape: String { loc("stpdfkit.hint.shape") }
    static var hintTapToAddText: String { loc("stpdfkit.hint.tapToAddText") }
    static var hintErase: String { loc("stpdfkit.hint.erase") }

    // MARK: - Order (Layer)
    static var orderTitle: String { loc("stpdfkit.order") }
    static var orderFront: String { loc("stpdfkit.order.front") }
    static var orderForward: String { loc("stpdfkit.order.forward") }
    static var orderBackward: String { loc("stpdfkit.order.backward") }
    static var orderBack: String { loc("stpdfkit.order.back") }

    // MARK: - License
    static var unlicensed: String { loc("stpdfkit.unlicensed") }

    // MARK: - Helper
    private static func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }
}
