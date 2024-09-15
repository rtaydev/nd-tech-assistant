import Cocoa
import FlutterMacOS

class WindowManager {
  static let shared = WindowManager()

  private init() {}

  func setInitialWindowSizeAndPosition(window: NSWindow?, screenSize: CGSize) {
    let windowSize = CGSize(width: 400, height: 300)
    let x = screenSize.width - windowSize.width
    let y = screenSize.height - windowSize.height
    window?.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
    window?.styleMask.insert([.resizable, .titled])
}

  func configureMainWindow(controller: FlutterViewController) {
    let window = controller.view.window
    window?.backgroundColor = NSColor.clear
    window?.isOpaque = false
    window?.hasShadow = false
    window?.styleMask.remove(.titled)
    window?.styleMask.remove(.resizable)
    window?.styleMask.remove(.closable)
    window?.ignoresMouseEvents = false
    window?.level = .floating
  }

  func setupOverlayWindow(screenSize: CGRect) {
    ScreenshotManager.shared.overlayWindow = NSWindow(contentRect: screenSize,
                                                      styleMask: [.borderless],
                                                      backing: .buffered,
                                                      defer: false)
    
    ScreenshotManager.shared.overlayWindow?.isOpaque = false
    ScreenshotManager.shared.overlayWindow?.backgroundColor = NSColor.clear
    ScreenshotManager.shared.overlayWindow?.ignoresMouseEvents = false
    ScreenshotManager.shared.overlayWindow?.level = .screenSaver
  }
}