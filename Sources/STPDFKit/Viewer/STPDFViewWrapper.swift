import SwiftUI
import PDFKit

/// UIViewRepresentable wrapper for Apple's PDFView with drawing, shape, eraser, and selection overlays
struct STPDFViewWrapper: UIViewRepresentable {

    let document: PDFDocument
    @Binding var currentPageIndex: Int
    let configuration: STPDFConfiguration
    let annotationManager: STAnnotationManager
    let isAnnotationModeActive: Bool

    // Explicit value-type copies so SwiftUI detects changes and calls updateUIView
    let activeTool: STAnnotationType?
    let activeStyle: STAnnotationStyle
    let hasSelection: Bool
    let hasMultiSelection: Bool
    let isMarqueeSelectEnabled: Bool

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        // PDF view
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.pageShadowsEnabled = true
        pdfView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        context.coordinator.pdfView = pdfView
        context.coordinator.annotationManager = annotationManager
        annotationManager.pdfView = pdfView

        // Ink drawing overlay (initially hidden)
        let drawingView = STInkDrawingView()
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.isHidden = true
        drawingView.isUserInteractionEnabled = false
        drawingView.pdfView = pdfView
        container.addSubview(drawingView)
        NSLayoutConstraint.activate([
            drawingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            drawingView.topAnchor.constraint(equalTo: container.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.drawingView = drawingView

        // Each ink stroke is committed immediately — record for undo
        drawingView.onStrokeCommitted = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in
                coordinator?.annotationManager?.undoManager.record(.add(annotation: annotation, page: page))
            }
        }

        // Shape drawing overlay (initially hidden)
        let shapeView = STShapeDrawingView()
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        shapeView.isHidden = true
        shapeView.isUserInteractionEnabled = false
        shapeView.pdfView = pdfView
        container.addSubview(shapeView)
        NSLayoutConstraint.activate([
            shapeView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shapeView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shapeView.topAnchor.constraint(equalTo: container.topAnchor),
            shapeView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.shapeView = shapeView

        // Each shape is committed immediately — record for undo
        shapeView.onShapeCommitted = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in
                coordinator?.annotationManager?.undoManager.record(.add(annotation: annotation, page: page))
            }
        }

        // Eraser overlay (initially hidden)
        let eraserView = STEraserOverlayView()
        eraserView.translatesAutoresizingMaskIntoConstraints = false
        eraserView.isHidden = true
        eraserView.isUserInteractionEnabled = false
        eraserView.pdfView = pdfView
        container.addSubview(eraserView)
        NSLayoutConstraint.activate([
            eraserView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            eraserView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            eraserView.topAnchor.constraint(equalTo: container.topAnchor),
            eraserView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.eraserView = eraserView

        // After eraser removes an annotation, record for undo
        eraserView.onAnnotationErased = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in
                coordinator?.annotationManager?.undoManager.record(.remove(annotation: annotation, page: page))
            }
        }

        // Selection overlay (initially hidden) — for selecting, moving, resizing annotations
        let selectionView = STAnnotationSelectionView()
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.isHidden = true
        selectionView.isUserInteractionEnabled = false
        selectionView.pdfView = pdfView
        container.addSubview(selectionView)
        NSLayoutConstraint.activate([
            selectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            selectionView.topAnchor.constraint(equalTo: container.topAnchor),
            selectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.selectionView = selectionView

        // Selection callbacks
        selectionView.onAnnotationSelected = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in
                coordinator?.annotationManager?.selectAnnotation(annotation, on: page)
            }
        }
        selectionView.onSelectionCleared = { [weak coordinator = context.coordinator] in
            Task { @MainActor in
                coordinator?.annotationManager?.clearAnnotationSelection()
            }
        }
        selectionView.onAnnotationModified = { [weak coordinator = context.coordinator] annotation, page, oldBounds in
            Task { @MainActor in
                coordinator?.annotationManager?.undoManager.record(.move(annotation: annotation, page: page, oldBounds: oldBounds))
            }
        }
        selectionView.onMultipleAnnotationsSelected = { [weak coordinator = context.coordinator] annotations, page in
            Task { @MainActor in
                coordinator?.annotationManager?.selectMultipleAnnotations(annotations, on: page)
            }
        }
        selectionView.onMultiAnnotationsModified = { [weak coordinator = context.coordinator] annotations, page, oldBounds in
            Task { @MainActor in
                var batchActions: [STUndoManager.Action] = []
                for (i, annotation) in annotations.enumerated() where i < oldBounds.count {
                    batchActions.append(.move(annotation: annotation, page: page, oldBounds: oldBounds[i]))
                }
                coordinator?.annotationManager?.undoManager.record(.batch(batchActions))
            }
        }

        // Long-press-to-select on overlays (select annotation from ANY tool)
        // When recognized, touchesCancelled fires on the overlay → cancels in-progress drawing
        for overlay in [drawingView, shapeView, eraserView] as [UIView] {
            let longPress = UILongPressGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleAnnotationLongPress(_:))
            )
            longPress.minimumPressDuration = 0.4
            overlay.addGestureRecognizer(longPress)
        }

        // Page change tracking
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        // Zoom/scroll change tracking — refresh selection handles + clear stale overlays
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.viewChanged(_:)),
            name: .PDFViewScaleChanged,
            object: pdfView
        )

        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let drawingView = context.coordinator.drawingView,
              let shapeView = context.coordinator.shapeView,
              let eraserView = context.coordinator.eraserView,
              let selectionView = context.coordinator.selectionView else { return }

        // Navigate to page if binding changed externally
        if let targetPage = document.page(at: currentPageIndex),
           pdfView.currentPage != targetPage {
            pdfView.go(to: targetPage)
        }

        // Keep references current
        context.coordinator.annotationManager = annotationManager
        annotationManager.pdfView = pdfView

        // Use explicit value-type parameters (guaranteed to trigger updateUIView)
        let tool = activeTool
        let isDrawing = tool?.isDrawingTool == true
        let isShape = tool?.isShapeTool == true
        let isErasing = tool?.isEraserTool == true
        let isSelectionMode = (tool == nil) && isAnnotationModeActive

        // === Annotation mode OFF: hide everything, clear overlays ===
        if !isAnnotationModeActive {
            drawingView.clearOverlayLayers()
            drawingView.isHidden = true
            drawingView.isUserInteractionEnabled = false
            drawingView.layer.mask = nil

            shapeView.clearCurrentShape()
            shapeView.isHidden = true
            shapeView.isUserInteractionEnabled = false
            shapeView.layer.mask = nil

            eraserView.isHidden = true
            eraserView.isUserInteractionEnabled = false

            selectionView.isHidden = true
            selectionView.isUserInteractionEnabled = false
            if selectionView.selectedAnnotation != nil {
                selectionView.clearSelection()
            }
            return
        }

        // === Annotation mode ON ===

        // Ink Drawing: visible when drawing or in selection/shape/eraser mode
        // (overlay layers persist briefly so ink annotations render before tiled layer catches up).
        // HIDDEN when markup tools are active → PDFView needs direct touch access for text selection.
        let isMarkup = tool?.requiresTextSelection == true
        drawingView.isHidden = isMarkup
        drawingView.isUserInteractionEnabled = isDrawing
        if isMarkup {
            drawingView.clearOverlayLayers()
        }
        if !isDrawing {
            drawingView.clearCurrentStroke() // Cancel any mid-stroke if switching away
        }

        // Shape Drawing: visible only when shape tool active.
        // Shapes render immediately in PDFView, no overlay persistence needed.
        shapeView.isHidden = !isShape
        shapeView.isUserInteractionEnabled = isShape
        if isShape, let shapeTool = tool {
            shapeView.shapeType = shapeTool
        }
        if !isShape {
            shapeView.clearCurrentShape()
        }

        // Eraser
        eraserView.isHidden = !isErasing
        eraserView.isUserInteractionEnabled = isErasing

        // Selection
        selectionView.isHidden = !isSelectionMode
        selectionView.isUserInteractionEnabled = isSelectionMode
        selectionView.isMarqueeEnabled = annotationManager.isMarqueeSelectEnabled

        // If selection mode was just deactivated, clear selection visuals
        if !isSelectionMode && selectionView.selectedAnnotation != nil {
            selectionView.clearSelection()
        }

        // Sync annotation manager's selection → selection view (for long-press-to-select)
        if isSelectionMode {
            if let annotation = annotationManager.selectedAnnotation,
               let page = annotationManager.selectedAnnotationPage {
                // Single selection
                if selectionView.selectedAnnotation !== annotation {
                    selectionView.select(annotation: annotation, on: page)
                }
                selectionView.refreshVisuals()
            } else if !annotationManager.multiSelectedAnnotations.isEmpty,
                      let page = annotationManager.multiSelectionPage {
                // Multi-selection — sync if needed
                let viewAnnotations = selectionView.multiSelectedAnnotations
                let managerAnnotations = annotationManager.multiSelectedAnnotations
                let needsSync = viewAnnotations.count != managerAnnotations.count
                    || !zip(viewAnnotations, managerAnnotations).allSatisfy({ $0 === $1 })
                if needsSync {
                    selectionView.selectMultiple(annotations: managerAnnotations, on: page)
                }
                selectionView.refreshVisuals()
            } else if selectionView.selectedAnnotation != nil || !selectionView.multiSelectedAnnotations.isEmpty {
                // Nothing selected in manager — clear selection frame
                selectionView.clearSelection()
            }
        }

        // Clip drawing overlays to visible PDF page bounds
        let overlayViews: [UIView] = [drawingView, shapeView]

        for overlay in overlayViews {
            if !overlay.isHidden {
                let combinedPath = UIBezierPath()
                for page in pdfView.visiblePages {
                    let pageBounds = page.bounds(for: .mediaBox)
                    let rectInPDFView = pdfView.convert(pageBounds, from: page)
                    let rectInOverlay = overlay.convert(rectInPDFView, from: pdfView)
                    combinedPath.append(UIBezierPath(rect: rectInOverlay))
                }
                let mask = CAShapeLayer()
                mask.path = combinedPath.cgPath
                overlay.layer.mask = mask
            } else {
                overlay.layer.mask = nil
            }
        }

        // Sync drawing style
        let style = activeStyle
        drawingView.strokeColor = style.color
        drawingView.strokeWidth = style.lineWidth
        drawingView.strokeOpacity = style.opacity

        shapeView.strokeColor = style.color
        shapeView.strokeWidth = style.lineWidth
        shapeView.strokeOpacity = style.opacity
    }

    /// Force PDFView to re-render all page tiles with the new annotations.
    private func refreshPDFView(_ pdfView: PDFView) {
        pdfView.layoutDocumentView()
        pdfView.setNeedsLayout()
        pdfView.setNeedsDisplay()
        // Walk the entire PDFView subtree to ensure tiled layers redraw
        func forceRedraw(_ view: UIView) {
            view.setNeedsLayout()
            view.setNeedsDisplay()
            for child in view.subviews {
                forceRedraw(child)
            }
        }
        forceRedraw(pdfView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject {
        let parent: STPDFViewWrapper
        weak var pdfView: PDFView?
        weak var drawingView: STInkDrawingView?
        weak var shapeView: STShapeDrawingView?
        weak var eraserView: STEraserOverlayView?
        weak var selectionView: STAnnotationSelectionView?
        var annotationManager: STAnnotationManager?

        init(parent: STPDFViewWrapper) {
            self.parent = parent
            self.annotationManager = parent.annotationManager
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }

            DispatchQueue.main.async {
                if self.parent.currentPageIndex != pageIndex {
                    self.parent.currentPageIndex = pageIndex
                }
                // Clear stale ink overlays (screen-space layers don't move with PDF pages)
                self.drawingView?.clearOverlayLayers()
            }
        }

        @objc func viewChanged(_ notification: Notification) {
            DispatchQueue.main.async {
                // Clear stale ink overlays (screen-space layers are at wrong scale after zoom)
                self.drawingView?.clearOverlayLayers()
                self.selectionView?.refreshVisuals()

                // Second refresh after PDFView layout fully settles
                // (usePageViewController transitions need an extra layout cycle)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.selectionView?.refreshVisuals()
                }
            }
        }

        /// Long-press on an overlay → check for annotation under finger → switch to selection mode
        @objc func handleAnnotationLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let overlay = gesture.view,
                  let pdfView = pdfView else { return }

            let point = gesture.location(in: overlay)
            let pointInPDFView = overlay.convert(point, to: pdfView)
            guard let page = pdfView.page(for: pointInPDFView, nearest: false) else { return }

            let pointInPage = pdfView.convert(pointInPDFView, to: page)

            // Hit test for annotations
            let hitRadius: CGFloat = 12
            let hitRect = CGRect(
                x: pointInPage.x - hitRadius,
                y: pointInPage.y - hitRadius,
                width: hitRadius * 2,
                height: hitRadius * 2
            )

            let protectedSubtypes: Set<String> = ["Link", "Widget"]

            for annotation in page.annotations.reversed() {
                if let subtype = annotation.type, protectedSubtypes.contains(subtype) {
                    continue
                }
                if annotation.bounds.intersects(hitRect) {
                    // Found annotation — switch to selection mode
                    Task { @MainActor [weak self] in
                        self?.annotationManager?.setTool(nil)
                        self?.annotationManager?.selectAnnotation(annotation, on: page)
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    return
                }
            }
        }
    }
}
