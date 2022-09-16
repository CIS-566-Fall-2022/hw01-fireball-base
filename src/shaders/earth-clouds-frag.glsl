#version 300 es

precision highp float;

// #define NO_LAMBERT

in vec4 fs_Nor;
in vec4 fs_Pos;

in vec4 fs_OriginalPos;

uniform vec3 u_CameraPos;

uniform float u_Time;

out vec4 out_Col;

NOISE GOES HERE

const vec3 landGreenColor1 = vec3(128.0, 179.0, 52.0) / 255.0;
const vec3 landGreenColor2 = vec3(48.0, 102.0, 48.0) / 255.0;
const vec3 landIceColor = vec3(219.0, 241.0, 253.0) / 255.0;
const vec3 oceanColor = vec3(6.0, 66.0, 115.0) / 255.0;

void main() {
  float perlinOffset = perlin(vec4(fs_OriginalPos.xyz * 4.0, 0)) * 1.2;
  float cloudsNoise = fbm(vec4(fs_OriginalPos.xyz * 8.0 + vec3(perlinOffset), 0));
  float alpha = smoothstep(0.45, 0.65, cloudsNoise);

  if (alpha < 0.01) {
    discard;
  }

  vec4 diffuseColor = vec4(vec3(1.0), alpha);

LAMBERT GOES HERE
}
