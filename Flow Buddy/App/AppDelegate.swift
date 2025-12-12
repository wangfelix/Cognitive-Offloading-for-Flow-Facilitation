import SwiftUI
import SwiftData
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var bubbleWindow: NSPanel!
    var captureWindow: NSPanel!
    var dashboardWindow: NSWindow!
    var statusBarItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    
    // Track the previously active application to restore focus
    var lastActiveApp: NSRunningApplication?
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ThoughtItem.self])
        return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
    }()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as accessory app (no dock icon)
        NSApp.setActivationPolicy(.accessory)
        
        setupBubbleWindow()
        setupCaptureWindow()
        setupDashboardWindow()
        setupStatusBar()
        setupGlobalShortcut()
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleCapture), name: .toggleCaptureWindow, object: nil)
    }
    
    func setupDashboardWindow() {
        dashboardWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        dashboardWindow.title = "Flow Buddy Dashboard"
        dashboardWindow.center()
        dashboardWindow.isReleasedWhenClosed = false
        
        // Toolbar configuration for unified look
        dashboardWindow.titlebarAppearsTransparent = true

        dashboardWindow.toolbarStyle = .unified
        
        dashboardWindow.delegate = self
        
        let contentView = DashboardView()
            .environmentObject(AppState.shared)
            .modelContainer(sharedModelContainer)
            
        dashboardWindow.contentView = NSHostingView(rootView: contentView)
    }
    
    func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "wind", accessibilityDescription: "Flow Buddy")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Dashboard", action: #selector(openDashboard), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusBarItem.menu = menu
    }
    
    @objc func openDashboard() {
        // Show Dock icon
        NSApp.setActivationPolicy(.regular)
        
        // Show Window
        dashboardWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openDashboard()
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == dashboardWindow {
            // Hide Dock icon when dashboard closes
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    func setupBubbleWindow() {
        bubbleWindow = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        bubbleWindow.level = .floating
        bubbleWindow.backgroundColor = .clear
        bubbleWindow.isOpaque = false
        bubbleWindow.hasShadow = false
        bubbleWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let contentView = BubbleView()
            .environmentObject(AppState.shared)
            .modelContainer(sharedModelContainer)
            
        bubbleWindow.contentView = NSHostingView(rootView: contentView)
        
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 380
            let y = screen.visibleFrame.minY + 50
            bubbleWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
        bubbleWindow.orderFront(nil)
    }
    
    func setupCaptureWindow() {
        captureWindow = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 200),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        captureWindow.level = .floating
        captureWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        captureWindow.backgroundColor = .clear
        captureWindow.isOpaque = false
        captureWindow.isFloatingPanel = true
        captureWindow.hasShadow = false
        
        captureWindow.hidesOnDeactivate = true
        
        let contentView = RapidCaptureView()
            .environmentObject(AppState.shared)
            .modelContainer(sharedModelContainer)
            
        captureWindow.contentView = NSHostingView(rootView: contentView)
        captureWindow.center()
    }

    func setupGlobalShortcut() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x464C4F57), id: 1) // Signature 'FLOW'
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handler: EventHandlerProcPtr = { _, _, _ in
            DispatchQueue.main.async {
                AppState.shared.isCaptureInterfaceOpen.toggle()
            }
            return noErr
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)
        
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_Period) 
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status != noErr {
            print("Failed to register global hotkey: \(status)")
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        // No-op
    }
    
    @objc func toggleCapture() {
        if AppState.shared.isCaptureInterfaceOpen {
            // Save the currently active app before we take focus
            lastActiveApp = NSWorkspace.shared.frontmostApplication
            
            // Move window to the screen containing the mouse cursor
            let mouseLocation = NSEvent.mouseLocation
            if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
                let screenFrame = screen.visibleFrame
                let windowSize = captureWindow.frame.size
                let newOriginX = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
                let newOriginY = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2 + 250
                captureWindow.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))
            }
            
            captureWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            closeCaptureWindow()
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == captureWindow else { return }
        
        if AppState.shared.isCaptureInterfaceOpen {
             AppState.shared.isCaptureInterfaceOpen = false
        }
    }
    
    // MARK: - Focus Management Helper
    
    func closeCaptureWindow() {
        captureWindow.orderOut(nil)
        
        // If we are currently the active app (meaning user hit Escape or Return),
        // we MUST manually return focus to the previous app.
        // If we are NOT the active app (meaning user clicked outside),
        // the system has already transferred focus, so we do nothing.
        if NSApp.isActive {
            lastActiveApp?.activate(options: .activateIgnoringOtherApps)
        }
    }
}
