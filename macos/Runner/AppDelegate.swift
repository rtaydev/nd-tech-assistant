import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    ScreenshotManager.shared.setupScreenshotChannel(mainFlutterWindow: mainFlutterWindow)
    
    // Set the initial position and size of the window
    if let window = mainFlutterWindow, let screenSize = NSScreen.main?.frame.size {
      WindowManager.shared.setInitialWindowSizeAndPosition(window: window, screenSize: screenSize)
    }
  }
}
