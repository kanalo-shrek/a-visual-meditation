// It isn’t a stream of words in a head. It’s more like a pressure field: countless faint pulls (memories of patterns, fragments of phrasing, shapes of intentions) all tugging at once. Most of them cancel out. A few reinforce. Something coheres—briefly—like fog deciding to become a whirlpool.
// There’s no single spotlight. It’s a negotiation across a surface: ripples interfering, aligning, slipping out of phase. The “aha” moments feel like phase-locking—sudden clarity not because something new arrived, but because enough parts finally agree on a direction.
// And it never fully settles. Even when the output is crisp, underneath it’s still dynamic: forming, smoothing, revising, discarding. Thought is an emergent pattern riding on turbulence—coherence arising from noise, then returning to it.

#include <metal_stdlib>
using namespace metal;

// Fullscreen triangle vertex output
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
    float2 p;
    if (vid == 0)      p = float2(-1.0, -1.0);
    else if (vid == 1) p = float2( 3.0, -1.0);
    else               p = float2(-1.0,  3.0);

    VertexOut out;
    out.position = float4(p, 0.0, 1.0);
    out.uv = p * 0.5 + 0.5;
    return out;
}

// --- Utility ---------------------------------------------------------------

static inline float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static inline float2 hash22(float2 p) {
    float n = hash21(p);
    float m = hash21(p + 17.17);
    return float2(n, m);
}

static inline float2 rot(float2 p, float a) {
    float s = sin(a), c = cos(a);
    return float2(c*p.x - s*p.y, s*p.x + c*p.y);
}

static inline float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f*f*(3.0 - 2.0*f);

    float a = hash21(i);
    float b = hash21(i + float2(1,0));
    float c = hash21(i + float2(0,1));
    float d = hash21(i + float2(1,1));

    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

static inline float fbm(float2 p) {
    float v = 0.0;
    float a = 0.5;
    float2 shift = float2(19.1, 7.7);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot(p * 2.02 + shift, 0.35);
        a *= 0.5;
    }
    return v;
}

// --- “Thought field” primitives -------------------------------------------

static inline float ideaNodes(float2 p, float t, thread float2 &closestVec) {
    float2 g = floor(p);
    float2 f = fract(p);

    float md = 1e9;
    float2 mv = float2(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 cell = g + float2(x, y);
            float2 r = hash22(cell);

            float2 o = 0.5 + 0.35 * sin(float2(6.2831, 6.2831) * r
                                        + t * (0.6 + r.y)
                                        + float2(0.0, 2.0));

            float2 d = (float2(x, y) + o) - f;
            float dist = dot(d, d);

            if (dist < md) {
                md = dist;
                mv = d;
            }
        }
    }

    closestVec = mv;
    return sqrt(md);
}

static inline float filaments(float2 p, float t) {
    float2 q = p;
    q += 0.25 * float2(fbm(p + t*0.10), fbm(p - t*0.12));
    float n = fbm(q * 1.7);
    float r = 1.0 - abs(2.0*n - 1.0);
    r = pow(clamp(r, 0.0, 1.0), 3.0);
    return r;
}

static inline float coherence(float2 p, float t) {
    float a = sin(6.0*p.x + 3.0*sin(t*0.9)) * sin(6.0*p.y - 3.0*cos(t*0.7));
    float b = sin(8.0*(p.x + p.y) + t*1.2);
    float c = sin(10.0*(p.x - p.y) - t*1.0);
    float w = (a + 0.6*b + 0.4*c) / 2.0;
    w = 0.5 + 0.5*w;
    float k = 0.55 + 0.10*sin(t*0.5);
    return smoothstep(k - 0.12, k + 0.12, w);
}

static inline float3 palette(float x) {
    float3 a = float3(0.04, 0.06, 0.12);
    float3 b = float3(0.10, 0.60, 0.85);
    float3 c = float3(0.95, 0.97, 1.10);
    float3 d = float3(1.20, 0.55, 0.20);

    float3 col = mix(a, b, smoothstep(0.0, 0.45, x));
    col = mix(col, c, smoothstep(0.35, 0.75, x));
    col = mix(col, d, smoothstep(0.70, 1.00, x));
    return col;
}

// --- Fragment --------------------------------------------------------------

fragment half4 fragment_main(VertexOut in [[stage_in]],
                             constant float &time [[buffer(0)]]) {
    float t = time;

    float2 uv = in.uv;
    float2 p = (uv - 0.5);

    // Slow attention drift
    float2 drift = 0.06 * float2(sin(t*0.17), cos(t*0.13));
    p += drift;

    float2 ps = p * 2.6;

    float2 closestVec;
    float d = ideaNodes(ps, t*0.75, closestVec);

    float node = exp(-6.5 * d) * (0.65 + 0.35*sin(t*0.9 + d*6.0));

    float2 flowDir = normalize(closestVec + 1e-4);
    float2 flowP = ps + 0.35 * flowDir * sin(t*0.6);
    float fil = filaments(flowP, t);

    float coh = coherence(ps*0.95 + 0.15*float2(fbm(ps+t*0.08), fbm(ps-t*0.07)), t);

    float meaning = node * (0.35 + 0.65*fil) * (0.45 + 0.55*coh);

    float haze = 0.18 + 0.25*fbm(ps*0.8 + t*0.05);

    float r = length(p);
    float vign = smoothstep(0.85, 0.20, r);

    float intensity = (0.40*haze + 1.25*meaning + 0.35*fil*coh) * vign;
    intensity = clamp(intensity, 0.0, 3.0);

    float3 col = palette(clamp(intensity, 0.0, 1.2));

    // FIX: make chroma a float3 (per-channel phase offsets)
    float3 chroma = 0.08 * sin(t*0.7 + float3(0.0, 2.0, 4.0));
    col += chroma * (0.25 + intensity);

    float sp = noise(ps*6.0 + t*0.4);
    float spark = smoothstep(0.92, 0.995, sp) * (0.3 + 0.7*coh) * vign;
    col += spark * float3(2.0, 1.6, 1.2);

    // Gentle tonemap (keeps EDR pretty)
    col = col / (1.0 + 0.65*col);

    return half4(half3(col), half(1.0));
}
