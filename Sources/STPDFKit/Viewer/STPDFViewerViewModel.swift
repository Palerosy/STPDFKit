import SwiftUI
import PDFKit

/// ViewModel for the PDF viewer
@MainActor
final class STPDFViewerViewModel: ObservableObject {

    let document: STPDFDocument

    @Published var currentPageIndex: Int = 0
    @Published var isThumbnailGridVisible = false
    @Published var isSearchVisible = false
    @Published var isOutlineVisible = false
    @Published var isBookmarkListVisible = false
    @Published var isSettingsVisible = false

    var totalPages: Int {
        document.pageCount
    }

    /// Current page label (e.g., "3 / 15")
    var pageLabel: String {
        "\(currentPageIndex + 1) / \(totalPages)"
    }

    init(document: STPDFDocument) {
        self.document = document
    }

    func goToPage(_ index: Int) {
        guard index >= 0 && index < totalPages else { return }
        currentPageIndex = index
    }

    func nextPage() {
        goToPage(currentPageIndex + 1)
    }

    func previousPage() {
        goToPage(currentPageIndex - 1)
    }
}
