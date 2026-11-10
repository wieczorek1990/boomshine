import AppKit
import SwiftUI

@main
struct boomshineApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    guard let keyWindow = NSApp.keyWindow else { return }
    keyWindow.makeKeyAndOrderFront(nil)
    DispatchQueue.main.async {
      keyWindow.collectionBehavior = [.fullScreenPrimary]
      keyWindow.styleMask.insert(.fullSizeContentView)
      keyWindow.toggleFullScreen(nil)
    }
  }
}
