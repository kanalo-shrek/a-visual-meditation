import AppKit
import Metal
import MetalKit

/// A Metal-based view that renders shader visualizations of "thinking"
public class DriftView: MTKView, MTKViewDelegate {
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var startTime: CFAbsoluteTime = 0

    /// The name of the shader being rendered
    public let shaderName: String

    /// Creates a DriftView with the specified shader
    /// - Parameters:
    ///   - frame: The frame rectangle for the view
    ///   - device: The Metal device to use for rendering
    ///   - shaderName: The name of the shader to load (without extension)
    public init(frame: CGRect, device: MTLDevice?, shaderName: String) {
        self.shaderName = shaderName
        super.init(frame: frame, device: device)
        setup()
    }

    required init(coder: NSCoder) {
        self.shaderName = "Claude-Opus4.5"
        super.init(coder: coder)
        setup()
    }

    public override var acceptsFirstResponder: Bool { true }

    func setup() {
        guard let device = device else { return }

        commandQueue = device.makeCommandQueue()
        startTime = CFAbsoluteTimeGetCurrent()

        guard let shaderURL = Bundle.module.url(forResource: shaderName,
                                                 withExtension: "shader",
                                                 subdirectory: "shaders"),
              let shaderSource = try? String(contentsOf: shaderURL) else {
            print("Failed to load shader: \(shaderName)")
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

        if let layer = self.layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
            layer.pixelFormat = .rgba16Float
        }
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    public func draw(in view: MTKView) {
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

    /// Returns a list of all available shader names
    public static var availableShaders: [String] {
        guard let shadersURL = Bundle.module.url(forResource: "shaders", withExtension: nil),
              let files = try? FileManager.default.contentsOfDirectory(at: shadersURL, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .filter { $0.pathExtension == "shader" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }
}
