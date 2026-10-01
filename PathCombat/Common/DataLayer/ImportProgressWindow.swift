import AppKit

final class ImportProgressWindow {
    private let sheetWindow: NSWindow
    private let parentWindow: NSWindow?

    init(message: String) {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.isIndeterminate = true
        indicator.startAnimation(nil)
        indicator.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: message)
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [indicator, label])
        stack.orientation = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 70))
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])

        let window = NSWindow(
            contentRect: contentView.frame,
            styleMask: [.titled],
            backing: .buffered,
            defer: false)
        window.contentView = contentView
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false

        sheetWindow = window
        parentWindow = NSApp.keyWindow

        if let parentWindow {
            parentWindow.beginSheet(window)
        } else {
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }

    func close() {
        if let parentWindow {
            parentWindow.endSheet(sheetWindow)
        } else {
            sheetWindow.close()
        }
    }
}
