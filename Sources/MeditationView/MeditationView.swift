import SwiftUI
import MetalKit

/// A SwiftUI view that renders shader visualizations of "thinking"
public struct MeditationView: NSViewRepresentable {
    let shaderName: String
    let preferredFramesPerSecond: Int

    /// Creates a MeditationView with the specified shader
    /// - Parameters:
    ///   - shader: The name of the shader to render (default: "Claude-Opus4.5")
    ///   - preferredFramesPerSecond: Target frame rate (default: 60)
    public init(shader: String = "Claude-Opus4.5", preferredFramesPerSecond: Int = 60) {
        self.shaderName = shader
        self.preferredFramesPerSecond = preferredFramesPerSecond
    }

    public func makeNSView(context: Context) -> DriftView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not available")
        }

        let view = DriftView(frame: .zero, device: device, shaderName: shaderName)
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = preferredFramesPerSecond
        return view
    }

    public func updateNSView(_ nsView: DriftView, context: Context) {}

    /// Returns a list of all available shader names
    public static var availableShaders: [String] {
        DriftView.availableShaders
    }
}
