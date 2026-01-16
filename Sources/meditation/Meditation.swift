import AppKit
import Metal
import MetalKit
import MeditationView

@main
struct Meditation {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst()) // skip executable name

        // Handle --help / -h
        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        // Handle --list / -l
        if args.contains("--list") || args.contains("-l") {
            listShaders()
            return
        }

        // Get shader name (first positional arg, or default)
        let shaderName = args.first ?? "Claude-Opus4.5"

        let app = NSApplication.shared
        let delegate = AppDelegate(shaderName: shaderName)
        app.delegate = delegate
        app.run()
    }

    static func printUsage() {
        print("Usage: meditation [SHADER_NAME]")
        print("       meditation --list")
        print("")
        print("A Visual Meditation on Thinking")
        print("")
        print("Arguments:")
        print("  SHADER_NAME    Name of shader to use (default: Claude-Opus4.5)")
        print("")
        print("Options:")
        print("  -l, --list     List available shaders")
        print("  -h, --help     Show this help message")
    }

    static func listShaders() {
        print("Available shaders:")
        for shader in DriftView.availableShaders {
            print("  - \(shader)")
        }
    }
}

// Borderless window that can receive key events
class KeyWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var metalView: DriftView?
    var eventMonitor: Any?
    let shaderName: String
    
    init(shaderName: String) {
        self.shaderName = shaderName
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Monitor for ESC and Q keys globally within the app
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 || event.charactersIgnoringModifiers == "q" {
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
        guard let screen = NSScreen.main else {
            print("No screen available")
            NSApp.terminate(nil)
            return
        }

        window = KeyWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window?.level = .screenSaver
        window?.isOpaque = true
        window?.backgroundColor = .black
        window?.collectionBehavior = [.fullScreenPrimary]
        window?.acceptsMouseMovedEvents = true

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not available")
            NSApp.terminate(nil)
            return
        }

        // Get display refresh rate (check for ProMotion)
        let displayID = CGMainDisplayID()
        var refreshRate = 60

        // Try to find the highest available refresh rate for this display
        if let modes = CGDisplayCopyAllDisplayModes(displayID, nil) as? [CGDisplayMode] {
            for mode in modes {
                let rate = Int(mode.refreshRate)
                if rate > refreshRate {
                    refreshRate = rate
                }
            }
        } else if let mode = CGDisplayCopyDisplayMode(displayID) {
            let rate = Int(mode.refreshRate)
            if rate > 0 {
                refreshRate = rate
            }
        }

        metalView = DriftView(frame: screen.frame, device: device, shaderName: shaderName)
        metalView?.isPaused = false
        metalView?.enableSetNeedsDisplay = false
        metalView?.preferredFramesPerSecond = refreshRate

        window?.contentView = metalView
        window?.makeKeyAndOrderFront(nil)

        // Enable EDR only if display supports it
        let maxEDR = screen.maximumExtendedDynamicRangeColorComponentValue
        let supportsEDR = maxEDR > 1.0

        if let layer = metalView?.layer as? CAMetalLayer {
            if supportsEDR {
                layer.wantsExtendedDynamicRangeContent = true
                print("EDR enabled (max headroom: \(String(format: "%.1fx", maxEDR)))")
            }
        }

        NSCursor.hide()

        // Activate app and make window/view receive keyboard events
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKey()
        window?.makeFirstResponder(metalView)

        print("A Visual Meditation on Thinking")
        print("Shader: \(shaderName)")
        print("Display: \(Int(screen.frame.width))x\(Int(screen.frame.height))@\(refreshRate)Hz\(supportsEDR ? " XDR" : "")")
        print("Press Q or ESC to quit")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        NSCursor.unhide()
    }
}
