import SwiftUI
import SwiftData
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var bubbleWindow: NSPanel!
    var captureWindow: NSPanel!
    var dashboardWindow: NSWindow!
    var statusBarItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    
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
            // Added .fullSizeContentView for modern sidebar look
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        dashboardWindow.title = "Flow Buddy Dashboard"
        dashboardWindow.center()
        dashboardWindow.isReleasedWhenClosed = false
        
        // Toolbar configuration for unified look
        dashboardWindow.titlebarAppearsTransparent = true
        dashboardWindow.titleVisibility = .hidden
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
            // Use async to allow close animation to complete smoothly
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    func setupBubbleWindow() {
        // Bubble uses standard NSPanel because it doesn't need keyboard focus
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
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        captureWindow.level = .floating // Floats above everything
        captureWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        captureWindow.backgroundColor = .clear
        captureWindow.isOpaque = false
        captureWindow.isFloatingPanel = true
        captureWindow.hasShadow = false
        
        // Enable automatic closing on outside clicks
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
         if AppState.shared.isCaptureInterfaceOpen {
             AppState.shared.isCaptureInterfaceOpen = false
         }
    }
    
    @objc func toggleCapture() {
        if AppState.shared.isCaptureInterfaceOpen {
            captureWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            captureWindow.orderOut(nil)
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window == captureWindow else { return }
        
        if AppState.shared.isCaptureInterfaceOpen {
             AppState.shared.isCaptureInterfaceOpen = false
        }
    }
}
