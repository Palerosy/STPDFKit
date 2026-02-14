import SwiftUI
import PhotosUI
import PDFKit

/// PHPicker wrapper that directly opens the photo library.
struct STPHPickerView: UIViewControllerRepresentable {

    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, onCancel: onCancel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImageSelected: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onCancel()
                return
            }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.onImageSelected(image)
                    } else {
                        self?.onCancel()
                    }
                }
            }
        }
    }
}

/// Overlay for placing a photo at a tapped location on the PDF.
struct STPhotoPlacementOverlay: View {

    let onPlace: (_ screenPoint: CGPoint) -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { _ in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    onPlace(location)
                }
        }
        .overlay(alignment: .top) {
            HStack {
                Image(systemName: "hand.tap")
                Text(STStrings.tapToPlace)
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.85))
            .clipShape(Capsule())
            .padding(.top, 12)
        }
    }
}
