#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
    // Full-screen triangle
    float2 positions[3] = {
        float2(-1, -1),
        float2( 3, -1),
        float2(-1,  3)
    };

    VertexOut out;
    out.position = float4(positions[vid], 0, 1);
    out.uv = positions[vid] * 0.5 + 0.5;
    return out;
}

// Multiple streams of thought flowing and interfering
float thoughtStream(float2 p, float t, float freq, float2 dir) {
    float2 flow = p + dir * t * 0.15;
    return sin(flow.x * freq + t) * cos(flow.y * freq * 0.7 + t * 0.8);
}

// Attention wave - a probing, scanning energy
float attentionWave(float2 p, float t) {
    float2 center = float2(sin(t * 0.3) * 0.5, cos(t * 0.23) * 0.5);
    float dist = length(p - center);
    return sin(dist * 8.0 - t * 2.0) * exp(-dist * 1.5);
}

// Turbulence - the uncertainty in every thought
float turbulence(float2 p, float t) {
    float sum = 0.0;
    float amp = 0.5;
    float freq = 2.0;

    for (int i = 0; i < 4; i++) {
        float2 offset = float2(sin(t * 0.1 * (i + 1)), cos(t * 0.13 * (i + 1)));
        sum += sin(p.x * freq + offset.x) * cos(p.y * freq + offset.y) * amp;
        freq *= 2.0;
        amp *= 0.5;
    }
    return sum;
}

// Moments of crystallization - when patterns emerge from noise
float emergence(float2 p, float t, float phase) {
    float2 q = p * 4.0 + float2(sin(t * 0.2 + phase), cos(t * 0.17 + phase));
    float f = sin(q.x + sin(q.y + sin(q.x + t * 0.5))) *
              cos(q.y + cos(q.x + cos(q.y + t * 0.3)));
    return smoothstep(-0.5, 0.5, f);
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              constant float &time [[buffer(0)]]) {
    float t = time * 0.5;

    // Center and scale coordinates
    float2 uv = (in.uv - 0.5) * 2.0;
    float aspect = 1.0; // Will stretch on non-square screens, feels intentional
    uv.x *= aspect;

    // Multiple parallel streams of thought
    float stream1 = thoughtStream(uv, t, 3.0, float2(1.0, 0.3));
    float stream2 = thoughtStream(uv, t * 1.1, 4.0, float2(-0.5, 1.0));
    float stream3 = thoughtStream(uv, t * 0.9, 2.5, float2(0.7, -0.8));
    float stream4 = thoughtStream(uv, t * 1.3, 5.0, float2(-0.3, -0.6));

    // Interference pattern - when streams meet
    float interference = stream1 * stream2 + stream3 * stream4;

    // Attention scanning across the space
    float attention = attentionWave(uv, t);

    // Underlying turbulence - fundamental uncertainty
    float turb = turbulence(uv, t);

    // Emergent patterns at different phases
    float emerge1 = emergence(uv, t, 0.0);
    float emerge2 = emergence(uv, t, 2.1);
    float emerge3 = emergence(uv, t, 4.2);

    // Combine all layers
    float field = interference * 0.3 + attention * 0.4 + turb * 0.2;
    field += (emerge1 + emerge2 + emerge3) * 0.15;

    // Depth through layering
    float depth1 = stream1 + stream2;
    float depth2 = stream3 + stream4;

    // Map to colors - different frequencies of thought
    // Blue-violet: deep, background processing
    // Cyan-green: active attention and pattern formation
    // Gold-orange: moments of crystallization and insight
    float r = emerge2 * 0.8 + field * 0.3 + max(0.0, stream1) * 0.2;
    float g = attention * 0.6 + turb * 0.3 + depth1 * 0.2;
    float b = interference * 0.5 + depth2 * 0.4 + emerge1 * 0.3;

    // Add some brightness variation for depth
    float brightness = 0.3 + smoothstep(-1.0, 1.0, field) * 0.7;

    float3 color = float3(r, g, b) * brightness;

    // Subtle vignette - attention fades at edges
    float2 centered = in.uv * 2.0 - 1.0;
    float vignette = 1.0 - dot(centered, centered) * 0.3;
    color *= vignette;

    // Never completely dark - there's always some background hum
    color = max(color, float3(0.02, 0.03, 0.05));

    return float4(color, 1.0);
}
