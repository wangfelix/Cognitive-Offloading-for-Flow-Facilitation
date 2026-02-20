import AppKit

// Custom Panel that ALLOWS typing
class FloatingPanel: NSPanel {
    // Needed for TextField focus
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

