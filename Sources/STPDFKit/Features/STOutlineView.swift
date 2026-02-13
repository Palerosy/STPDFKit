import SwiftUI
import PDFKit

/// Document outline / table of contents view
struct STOutlineView: View {

    let document: PDFDocument
    let onPageSelected: (Int) -> Void
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Group {
                if let outline = document.outlineRoot, outline.numberOfChildren > 0 {
                    List {
                        ForEach(flattenedOutline(outline), id: \.id) { entry in
                            Button {
                                if let dest = entry.outline.destination, let page = dest.page {
                                    let pageIndex = document.index(for: page)
                                    onPageSelected(pageIndex)
                                    isPresented = false
                                }
                            } label: {
                                HStack {
                                    Text(entry.outline.label ?? "Untitled")
                                        .foregroundColor(.primary)
                                        .padding(.leading, CGFloat(entry.depth) * 16)
                                    Spacer()
                                    if let dest = entry.outline.destination, let page = dest.page {
                                        Text("p. \(document.index(for: page) + 1)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.indent")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No outline available")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Outline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private struct OutlineEntry: Identifiable {
        let id = UUID()
        let outline: PDFOutline
        let depth: Int
    }

    private func flattenedOutline(_ root: PDFOutline) -> [OutlineEntry] {
        var result: [OutlineEntry] = []
        flatten(root, depth: 0, into: &result)
        return result
    }

    private func flatten(_ parent: PDFOutline, depth: Int, into result: inout [OutlineEntry]) {
        for i in 0..<parent.numberOfChildren {
            if let child = parent.child(at: i) {
                result.append(OutlineEntry(outline: child, depth: depth))
                if child.numberOfChildren > 0 {
                    flatten(child, depth: depth + 1, into: &result)
                }
            }
        }
    }
}
