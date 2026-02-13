import SwiftUI
import PDFKit

/// Grid view of page thumbnails for quick navigation
struct STThumbnailGridView: View {

    @ObservedObject var viewModel: STPDFViewerViewModel
    let onPageSelected: (Int) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        thumbnailCell(for: index)
                            .onTapGesture {
                                onPageSelected(index)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        viewModel.isThumbnailGridVisible = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnailCell(for index: Int) -> some View {
        VStack(spacing: 6) {
            if let page = viewModel.document.page(at: index) {
                let stPage = STPDFPage(id: index, page: page)
                Image(uiImage: stPage.thumbnail(maxSize: 150))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 160)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(
                                viewModel.currentPageIndex == index ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            }

            Text("\(index + 1)")
                .font(.caption)
                .foregroundColor(viewModel.currentPageIndex == index ? .accentColor : .secondary)
        }
    }
}
