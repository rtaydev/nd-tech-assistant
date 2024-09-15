import Cocoa
import FlutterMacOS
import ScreenCaptureKit

class ScreenshotManager {
  static let shared = ScreenshotManager()
  var overlayWindow: NSWindow?

  private init() {}

  func setupScreenshotChannel(mainFlutterWindow: NSWindow?) {
    guard let flutterViewController = NSApplication.shared.windows.first(where: { $0.contentViewController is FlutterViewController })?.contentViewController as? FlutterViewController else {
      return
    }

    WindowManager.shared.configureMainWindow(controller: flutterViewController)
    setupMethodChannel(controller: flutterViewController)
  }

  private func setupMethodChannel(controller: FlutterViewController) {
    let screenshotChannel = FlutterMethodChannel(name: "com.ndtechassistant.screenshot", binaryMessenger: controller.engine.binaryMessenger)
    screenshotChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      if call.method == "drawRectAndCapture" {
        self.showOverlayWindow(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func showOverlayWindow(result: @escaping FlutterResult) {
    guard let screenSize = NSScreen.main?.frame else {
      result(FlutterError(code: "UNAVAILABLE", message: "Screen size unavailable", details: nil))
      return
    }
    WindowManager.shared.setupOverlayWindow(screenSize: screenSize)
    
    let view = CaptureView(frame: screenSize, result: result)
    overlayWindow?.contentView = view
    overlayWindow?.makeKeyAndOrderFront(nil)
    
    if let mainFlutterWindow = NSApplication.shared.windows.first(where: { $0.contentViewController is FlutterViewController })?.contentViewController?.view.window {
      mainFlutterWindow.orderOut(nil)
    }
    
    NSApp.activate(ignoringOtherApps: true)
    
    view.onCaptureComplete = {
      if let mainFlutterWindow = NSApplication.shared.windows.first(where: { $0.contentViewController is FlutterViewController })?.contentViewController?.view.window {
        mainFlutterWindow.makeKeyAndOrderFront(nil)
      }
    }
  }

  func hideMainWindow() {
    if let mainFlutterWindow = NSApplication.shared.windows.first(where: { $0.contentViewController is FlutterViewController })?.contentViewController?.view.window {
      mainFlutterWindow.orderOut(nil)
    }
  }

  func showMainWindow() {
    if let mainFlutterWindow = NSApplication.shared.windows.first(where: { $0.contentViewController is FlutterViewController })?.contentViewController?.view.window {
      mainFlutterWindow.makeKeyAndOrderFront(nil)
    }
  }
}