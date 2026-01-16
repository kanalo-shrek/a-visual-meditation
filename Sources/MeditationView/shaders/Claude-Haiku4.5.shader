#include <metal_stdlib>
using namespace metal;

// Thinking as: parallel exploration, pattern recognition,
// iterative refinement emerging from interference and resonance.
// Uncertainty crystallizing into clarity through recursive synthesis.

vertex float4 vertex_main(uint vid [[vertex_id]]) {
    float2 vertices[] = {
        float2(-1, -1), float2(3, -1), float2(-1, 3)
    };
    return float4(vertices[vid], 0, 1);
}

fragment float4 fragment_main(float4 position [[position]],
                              constant float &time [[buffer(0)]]) {
    float2 uv = position.xy / 1440.0; // normalized coords
    float3 color = float3(0.0);

    // Layer 1: Interference waves (resonance between thoughts)
    // Multiple frequencies exploring different possibilities
    for (int i = 0; i < 4; i++) {
        float phase = time * (0.3 + float(i) * 0.15);
        float wave1 = sin(uv.x * 6.0 + phase) * cos(uv.y * 6.0 + phase * 0.7);
        float wave2 = sin(uv.y * 5.0 - phase * 0.8) * cos(uv.x * 5.0 - phase * 1.1);
        float interference = wave1 * wave2; // ideas interfering

        // Color progression: cool uncertainty → warm clarity
        float clarity = 0.5 + 0.5 * sin(time * 0.5 + float(i));
        color += float3(
            0.2 + 0.3 * clarity,      // warm red (emerging clarity)
            0.1 + 0.2 * abs(interference), // cyan where patterns form
            0.4 - 0.2 * clarity       // cool blue (dissolving uncertainty)
        ) * max(0.0, interference * 0.7);
    }

    // Layer 2: Flowing particles (parallel exploration threads)
    // Organic motion representing the drift of attention
    for (int j = 0; j < 5; j++) {
        float2 particleUV = uv;
        float phi = float(j) * 1.2566; // angle offset
        float speed = 0.5 + 0.3 * sin(float(j) * 0.7);

        // Particle trails following flowing paths
        particleUV.x += sin(particleUV.y * 3.0 + time * speed) * 0.15;
        particleUV.y += cos(particleUV.x * 3.0 + time * speed * 0.8 + phi) * 0.15;

        // Soft glow at particle positions (focus of attention)
        float dist = length(particleUV - float2(0.5, 0.5));
        float glow = 0.05 / (0.01 + dist * dist);

        color += float3(0.1, 0.3, 0.6) * glow * 0.4;
    }

    // Layer 3: Recursive fractal structure (self-reference in thinking)
    // The infinite regression of thought examining itself
    float2 z = (uv - 0.5) * 3.0;
    float3 fractal = float3(0.0);

    for (int iter = 0; iter < 8; iter++) {
        // Mandelbrot-like iteration with time-modulation
        float angle = atan2(z.y, z.x) + time * 0.1;
        float radius = length(z);

        z = float2(
            cos(angle) * radius * radius,
            sin(angle) * radius * radius
        ) + (uv - 0.5) * 2.0;

        float smoothIter = float(iter) + 1.0 - log2(max(1.0, log2(radius)));
        fractal += float3(
            0.3 * sin(smoothIter * 0.5 + time),
            0.2 * cos(smoothIter * 0.7),
            0.4 * sin(smoothIter * 0.3 + time * 0.5)
        ) * 0.15;

        if (radius > 4.0) break;
    }

    color += fractal;

    // Layer 4: Radial emergence (meaning crystallizing from chaos)
    // Center brightens as understanding emerges
    float2 center = uv - 0.5;
    float radius = length(center);
    float emergence = 0.2 / (0.1 + radius * radius);

    // Pulsing clarity - the iterative refinement loop
    float pulse = 0.5 + 0.5 * sin(time * 2.0 + radius * 3.0);
    color += float3(0.6, 0.4, 0.2) * emergence * pulse * 0.6;

    // Layer 5: Vortex pattern (integrating different threads)
    // Attention spiraling inward, synthesizing
    float angle = atan2(center.y, center.x);
    float vortex = sin(angle * 6.0 - time * 1.5 + radius * 4.0);
    color += float3(0.2, 0.5, 0.3) * max(0.0, vortex) * max(0.0, 0.4 - radius) * 0.5;

    // Tone mapping and final color
    // Emphasize the most active regions while maintaining overall glow
    color = color / (color + float3(0.5));

    // Subtle vignette (focus of attention at center)
    color *= (0.7 + 0.3 * (1.0 - radius * 2.0));

    return float4(color, 1.0);
}
