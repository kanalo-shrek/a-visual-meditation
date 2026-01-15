import AppKit
import Metal
import MetalKit

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
        if let shadersURL = Bundle.module.url(forResource: "shaders", withExtension: nil),
           let files = try? FileManager.default.contentsOfDirectory(at: shadersURL, includingPropertiesForKeys: nil) {
            for file in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) where file.pathExtension == "shader" {
                let name = file.deletingPathExtension().lastPathComponent
                print("  - \(name)")
            }
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

class DriftView: MTKView, MTKViewDelegate {
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var startTime: CFAbsoluteTime = 0
    let shaderName: String

    init(frame: CGRect, device: MTLDevice?, shaderName: String) {
        self.shaderName = shaderName
        super.init(frame: frame, device: device)
        setup()
    }

    required init(coder: NSCoder) {
        self.shaderName = "Claude-Opus4.5"
        super.init(coder: coder)
        setup()
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 || event.charactersIgnoringModifiers == "q" {
            NSApp.terminate(nil)
        }
    }

    func setup() {
        guard let device = device else { return }

        commandQueue = device.makeCommandQueue()
        startTime = CFAbsoluteTimeGetCurrent()

        // Load shader from bundle
        guard let shaderURL = Bundle.module.url(forResource: shaderName,
                                                 withExtension: "shader",
                                                 subdirectory: "shaders"),
              let shaderSource = try? String(contentsOf: shaderURL) else {
            print("Failed to load shader: \(shaderName)")
            print("Use 'meditation --list' to see available shaders")
            return
        }

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let vertexFunction = library.makeFunction(name: "vertex_main")
            let fragmentFunction = library.makeFunction(name: "fragment_main")

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = .rgba16Float

            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Failed to create pipeline: \(error)")
        }

        delegate = self
        colorPixelFormat = .rgba16Float

        // Enable EDR/HDR for XDR displays
        if let layer = self.layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
            layer.pixelFormat = .rgba16Float
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipeline = pipelineState else { return }

        var time = Float(CFAbsoluteTimeGetCurrent() - startTime)

        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
