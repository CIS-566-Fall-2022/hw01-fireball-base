#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;
uniform float u_Amplitude;
uniform float u_Presistence;
uniform int u_Octaves;
uniform int u_Bloom;
uniform vec4 u_Color;

in vec2 fs_Pos;
in vec2 fs_Nor;
out vec4 out_Col;

float noise2D( vec2 p ) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float interpNoise2D(float x, float y) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);

    float v1 = noise2D(vec2(intX, intY));
    float v2 = noise2D(vec2(intX + 1, intY));
    float v3 = noise2D(vec2(intX, intY + 1));
    float v4 = noise2D(vec2(intX + 1, intY + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    return mix(i1, i2, fractY);
}

float fbm(vec2 p) {
    float total = 0.0;
    float persistence = 0.55;
    int octaves = 10;
    for(int i = 1; i <= octaves; i++) {
        float freq = pow(2.0f, float(i));
        float amp = pow(persistence, float(i));
        total += interpNoise2D(p.x * freq, p.y * freq) * amp;
    }
    return total;
}

float glow(vec2 uv) {
  float d = length(uv);
  float m = 0.5/d;
  m *= smoothstep(0.6, 0.2, d);
  return m;
}

const vec3 colors[5] = vec3[](vec3(94, 65, 65) / 255.0,               // BROWN
                              vec3(161, 190, 190) / 255.0,            // MINT GREEN
                              vec3(194, 128, 171) / 255.0,             // DUSTY ROSE
                              vec3(114, 85, 72) / 255.0,             // DULL BROWN
                              vec3(215, 126, 82) / 255.0);             // DULL ORANGE

void main() {
  vec2 uv = (gl_FragCoord.xy/u_Dimensions.xy) * 2.0f - vec2(1.0f);

  float time = u_Time * u_Amplitude / 30.0;

  vec2 q = vec2(0.0);
  q.x = fbm(uv);
  q.y = fbm(uv + vec2(1.0));

  vec2 r = vec2(0.0);
  r.x = fbm(uv + 1.0 * q + vec2(1.7,9.2)+ 0.001 * time);
  r.y = fbm(uv + 1.0 * q + vec2(8.3,2.8)+ 0.0015 * time);

  float f = fbm(uv + r);

  vec3 newColor = mix(colors[2], colors[4], clamp((f*f)*4.0, 0.0, 1.0));
  newColor = mix(newColor, u_Color.rgb, clamp(length(q),0.0,1.0));
  newColor = mix(newColor, colors[0], clamp(length(r.x),0.0,1.0));
  
  newColor += vec3(glow(uv) * 0.9) * vec3(vec3(255, 151, 56) / 255.0) * 0.8;

  // Compute final shaded color
  out_Col = vec4(newColor * (length(r*r) * 0.5), 1.0);
}
