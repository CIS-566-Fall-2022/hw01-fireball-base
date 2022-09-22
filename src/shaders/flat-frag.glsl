#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

float noise3D( vec3 p ) {
    return fract(sin(dot(p, vec3(127.1f, 311.7f, 245.3f))) *
                 43758.5453);
}

float interpNoise3D(float x, float y, float z) {
    int intX = int(floor(x));
    float fractX = fract(x);
    int intY = int(floor(y));
    float fractY = fract(y);
    int intZ = int(floor(z));
    float fractZ = fract(z);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);
    float j1 = mix(i1, i2, fractY);
    float j2 = mix(i3, i4, fractY);

    return mix(j1, j2, fractZ);
}

float fbm3D(float x, float y, float z) {
    float total = 0.f;
    float persistence = 0.5f;
    int octaves = 16;
    float freq = 25.0;
    float amp = 0.5;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(x * freq,
                               y * freq, z * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

void main() {
  float noise = fbm3D(fs_Pos.x, fs_Pos.y, 0.0);
  if (noise < 0.2)
  {
    out_Col = vec4(1.0, 1.0, 1.0, 1.0);
  }
  else
  {
    out_Col = vec4(0.0, 0.0, 0.0, 1.0);
  }
  
  //out_Col = vec4(0.5 * (fs_Pos + vec2(1.0)), 0.5 * (sin(u_Time * 3.14159 * 0.01) + 1.0), 1.0);
}
