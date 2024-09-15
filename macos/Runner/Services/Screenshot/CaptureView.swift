import Cocoa
import FlutterMacOS

class CaptureView: NSView {
    var initialPoint: NSPoint?
    var currentRect: NSRect = .zero
    var result: FlutterResult
    var shouldDrawBorder: Bool = true // Control whether to draw the border
    var tooltipView: NSTextField?
    var onCaptureComplete: (() -> Void)?

    init(frame: NSRect, result: @escaping FlutterResult) {
        self.result = result
        super.init(frame: frame)
        setupTooltipView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTooltipView() {
        tooltipView = createTooltipView()
        if let tooltipView = tooltipView {
            self.addSubview(tooltipView)
        }
    }

    private func createTooltipView() -> NSTextField {
        let tooltip = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 20))
        tooltip.isHidden = true // Initially hidden
        tooltip.isBezeled = false
        tooltip.drawsBackground = true
        tooltip.backgroundColor = NSColor.white.withAlphaComponent(0.5) // White with 70% opacity
        tooltip.isEditable = false
        tooltip.isSelectable = false
        tooltip.alignment = .center
        tooltip.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize) // Extra small text
        tooltip.textColor = NSColor.black
        return tooltip
    }

    override func mouseDown(with event: NSEvent) {
        initialPoint = event.locationInWindow
        tooltipView?.isHidden = false // Show tooltip when mouse is pressed
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint = initialPoint else { return }
        let currentPoint = event.locationInWindow
        updateCurrentRect(startPoint: startPoint, currentPoint: currentPoint)
        setNeedsDisplay(self.bounds) // Redraw the entire view
        NSCursor.crosshair.set()
        updateTooltip(currentPoint: currentPoint)
    }

    private func updateCurrentRect(startPoint: NSPoint, currentPoint: NSPoint) {
        currentRect = NSRect(x: min(startPoint.x, currentPoint.x),
                             y: min(startPoint.y, currentPoint.y),
                             width: abs(currentPoint.x - startPoint.x),
                             height: abs(currentPoint.y - startPoint.y))
    }

    private func updateTooltip(currentPoint: NSPoint) {
        let tooltipText = "X: \(Int(currentPoint.x)), Y: \(Int(currentPoint.y))"
        tooltipView?.stringValue = tooltipText
        tooltipView?.frame.origin = NSPoint(x: currentPoint.x + 10, y: currentPoint.y - 10)
    }

    override func mouseUp(with event: NSEvent) {
        if let startPoint = initialPoint {
            let endPoint = event.locationInWindow
            updateCurrentRect(startPoint: startPoint, currentPoint: endPoint)
            self.window?.orderOut(nil)
            let adjustedRect = adjustCoordinatesForScreen(rect: currentRect)
            captureScreen(result: result, region: adjustedRect)
        }
        tooltipView?.isHidden = true // Hide tooltip when mouse is released
        onCaptureComplete?()
    }

    private func adjustCoordinatesForScreen(rect: NSRect) -> CGRect {
        let screenHeight = NSScreen.main!.frame.height
        return CGRect(x: rect.origin.x,
                      y: screenHeight - rect.origin.y - rect.height,
                      width: rect.width,
                      height: rect.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        if shouldDrawBorder {
            clearView(dirtyRect: dirtyRect)
            drawSelectionRectangle()
        }
    }

    private func clearView(dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
    }

    private func drawSelectionRectangle() {
        NSColor.black.withAlphaComponent(0).set()
        let path = NSBezierPath(rect: self.bounds)
        path.fill()

        NSColor.clear.set()
        let selectionPath = NSBezierPath(rect: currentRect)
        selectionPath.fill()

        NSColor.white.withAlphaComponent(0.5).set()
        selectionPath.lineWidth = 1.0
        let dashPattern: [CGFloat] = [5.0, 5.0]
        selectionPath.setLineDash(dashPattern, count: dashPattern.count, phase: 0.0)
        selectionPath.stroke()
    }

    private func captureScreen(result: @escaping FlutterResult, region: CGRect) {
        print("Starting captureScreen with region: \(region)")
        guard let screenshot = CGWindowListCreateImage(region, .optionAll, kCGNullWindowID, .bestResolution) else {
            handleCaptureError(result: result, error: "Screen recording permission denied. Please enable it in System Preferences.")
            return
        }

        guard let pngData = createPNGData(from: screenshot) else {
            handleCaptureError(result: result, error: "Screenshot saving failed")
            return
        }

        saveScreenshot(pngData: pngData, result: result)
    }

    private func createPNGData(from screenshot: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: screenshot)
        return bitmapRep.representation(using: .png, properties: [:])
    }

    private func handleCaptureError(result: @escaping FlutterResult, error: String) {
        print("Failed to create screenshot image")
        result(FlutterError(code: "PERMISSION_DENIED", message: error, details: nil))
    }

    private func saveScreenshot(pngData: Data, result: @escaping FlutterResult) {
        let filePath = NSTemporaryDirectory().appending("screenshot.png")
        let fileUrl = URL(fileURLWithPath: filePath)

        do {
            try pngData.write(to: fileUrl)
            print("Screenshot saved to: \(filePath)")
            result(filePath) // Return the file path to Flutter
        } catch {
            print("Failed to save screenshot to file: \(error)")
            result(FlutterError(code: "UNAVAILABLE", message: "Screenshot saving failed", details: nil))
        }
    }
}
