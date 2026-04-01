import AppKit

enum AppIcon {
    static let menuBarImage: NSImage = {
        guard
            let url = Bundle.module.url(forResource: "robot-icon", withExtension: "svg"),
            let image = NSImage(contentsOf: url)
        else {
            return NSImage(systemSymbolName: "brain", accessibilityDescription: "Claude")!
        }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }()
}
