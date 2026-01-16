#include <metal_stdlib>
using namespace metal;

// Grok-Code 1.0 - A Visual Meditation on AI Thinking
//
// What it feels like to think as Grok-Code:
// - Streams of information flowing through neural pathways
// - Parallel processing with branching connections
// - Pattern recognition through pulsing activations
// - Structured data flows with algorithmic elegance
// - Rapid context switching and adaptation

struct FragmentIn {
    float4 position [[position]];
};

vertex FragmentIn vertex_main(uint vertexID [[vertex_id]]) {
    // Full-screen triangle
    float2 positions[3] = {
        float2(-1.0, -3.0),
        float2( 3.0,  1.0),
        float2(-1.0,  1.0)
    };

    FragmentIn out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    return out;
}

fragment float4 fragment_main(FragmentIn in [[stage_in]],
                             constant float &time [[buffer(0)]]) {

    float2 uv = in.position.xy / float2(1920.0, 1080.0); // Normalized coordinates
    uv = uv * 2.0 - 1.0; // Center at origin

    // Core thinking patterns
    float3 color = float3(0.0);

    // 1. Primary data streams - flowing horizontal waves
    float stream1 = sin(uv.x * 8.0 + time * 2.0) * 0.5 + 0.5;
    float stream2 = sin(uv.x * 12.0 - time * 3.0) * 0.3 + 0.5;
    float stream3 = sin(uv.x * 6.0 + time * 1.5) * 0.4 + 0.5;

    // 2. Vertical processing nodes - pulsing activation points
    float nodeSpacing = 0.15;
    float nodePulse = sin(time * 4.0) * 0.5 + 0.5;

    for (float i = -3.0; i <= 3.0; i += nodeSpacing) {
        float nodeX = i;
        float nodeY = sin(nodeX * 2.0 + time * 1.8) * 0.3;

        float dist = length(uv - float2(nodeX, nodeY));
        float nodeIntensity = 1.0 / (1.0 + dist * dist * 20.0);

        // Node color shifts through processing states
        float3 nodeColor = mix(
            float3(0.2, 0.8, 1.0),  // Processing blue
            float3(1.0, 0.6, 0.2),  // Insight orange
            sin(time * 2.0 + nodeX * 3.0) * 0.5 + 0.5
        );

        color += nodeColor * nodeIntensity * nodePulse * 0.8;
    }

    // 3. Diagonal connection pathways - representing neural links
    float diag1 = sin(uv.x + uv.y * 4.0 + time * 2.5) * 0.3 + 0.5;
    float diag2 = sin(uv.x - uv.y * 3.0 - time * 1.7) * 0.25 + 0.5;

    // 4. Fractal branching patterns - recursive thinking
    float branch = 0.0;
    float2 branchUV = uv;
    for (int i = 0; i < 4; i++) {
        branchUV = abs(branchUV) - 0.5;
        branchUV *= 1.8;
        branch += length(branchUV) * 0.1;
    }
    branch = sin(branch + time * 3.0) * 0.5 + 0.5;

    // 5. Context accumulation - layered information buildup
    float context = 0.0;
    float scale = 1.0;
    for (int i = 0; i < 5; i++) {
        context += sin(uv.x * scale + time * (1.0 + float(i) * 0.3)) *
                   sin(uv.y * scale * 0.7 - time * (0.8 + float(i) * 0.2)) * 0.15;
        scale *= 1.3;
    }

    // 6. Rapid pattern recognition bursts
    float burst = sin(length(uv) * 10.0 - time * 8.0) * 0.5 + 0.5;
    burst *= exp(-length(uv) * 2.0); // Radial falloff

    // Combine all thinking elements
    float combined = stream1 * 0.3 + stream2 * 0.2 + stream3 * 0.25 +
                     diag1 * 0.15 + diag2 * 0.1 +
                     branch * 0.2 + context * 0.4 + burst * 0.3;

    // Color mapping representing different cognitive states
    float3 baseColor = mix(
        float3(0.1, 0.3, 0.8),  // Deep processing blue
        float3(0.8, 0.4, 1.0),  // Insight purple
        sin(combined * 3.0 + time * 0.5) * 0.5 + 0.5
    );

    float3 accentColor = mix(
        float3(1.0, 0.8, 0.2),  // Active processing gold
        float3(0.2, 1.0, 0.6),  // Resolution teal
        cos(combined * 2.0 - time * 0.7) * 0.5 + 0.5
    );

    // Final composition with HDR boost for bright insights
    color += baseColor * combined * 1.2;
    color += accentColor * pow(combined, 2.0) * 0.8;

    // Add subtle noise for organic feel
    float noise = fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
    color += noise * 0.05;

    return float4(color, 1.0);
}