import SwiftUI
import SwiftData

class AppDelegate: NSObject, NSApplicationDelegate {
    var bubbleWindow: NSPanel!
    var captureWindow: NSPanel!
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ThoughtItem.self])
        return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
    }()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupBubbleWindow()
        setupCaptureWindow()
        NotificationCenter.default.addObserver(self, selector: #selector(toggleCapture), name: .toggleCaptureWindow, object: nil)
    }
    
    func setupBubbleWindow() {
        // Bubble uses standard NSPanel because it doesn't need keyboard focus
        bubbleWindow = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200), // Increased size for "Intervention Box"
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        bubbleWindow.level = .floating
        bubbleWindow.backgroundColor = .clear
        bubbleWindow.isOpaque = false
        bubbleWindow.hasShadow = false
        
        let contentView = BubbleView()
            .environmentObject(AppState.shared)
            .modelContainer(sharedModelContainer)
            
        bubbleWindow.contentView = NSHostingView(rootView: contentView)
        
        // Position Bottom Right
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 380
            let y = screen.visibleFrame.minY + 50
            bubbleWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
        bubbleWindow.orderFront(nil)
    }
    
    func setupCaptureWindow() {
        // Capture Window uses CUSTOM FloatingPanel to allow typing
        captureWindow = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 200),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow], // .nonactivatingPanel keeps it floating but subclass overrides key status
            backing: .buffered,
            defer: false
        )
        
        captureWindow.level = .floating // Floats above everything
        captureWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        captureWindow.backgroundColor = .clear
        captureWindow.isOpaque = false
        captureWindow.isFloatingPanel = true
        captureWindow.hasShadow = false
        
        // 1. Enable automatic closing on outside clicks
        captureWindow.hidesOnDeactivate = true
        
        let contentView = RapidCaptureView()
            .environmentObject(AppState.shared)
            .modelContainer(sharedModelContainer)
            
        captureWindow.contentView = NSHostingView(rootView: contentView)
        captureWindow.center()
    }
    
    // 2. Handle the window resigning key status (losing focus)
    func applicationDidResignActive(_ notification: Notification) {
         // If the app loses focus (user clicks another app), close the capture window state
         if AppState.shared.isCaptureInterfaceOpen {
             AppState.shared.isCaptureInterfaceOpen = false
         }
    }
    
    @objc func toggleCapture() {
        if AppState.shared.isCaptureInterfaceOpen {
            captureWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true) // Forces app to front so you can type
        } else {
            captureWindow.orderOut(nil)
        }
    }
    
    // 3. Specific delegate method for the window itself
    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == captureWindow else { return }
        
        // When capture window loses focus, close it
        // We must wrap this in a check to ensure we aren't just switching focus within the app
        if AppState.shared.isCaptureInterfaceOpen {
             AppState.shared.isCaptureInterfaceOpen = false
        }
    }
}

