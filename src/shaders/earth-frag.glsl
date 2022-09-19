#version 300 es

precision highp float;

// #define NO_LAMBERT

in vec4 fs_Nor;
in vec4 fs_Pos;

in vec4 fs_DisplacedPos;
in float fs_NorDisp;

in float fs_Poles;

uniform vec3 u_CameraPos;

uniform float u_Time;

out vec4 out_Col;

NOISE GOES HERE

const vec3 landGreenColor1 = vec3(128.0, 179.0, 52.0) / 255.0;
const vec3 landGreenColor2 = vec3(48.0, 102.0, 48.0) / 255.0;
const vec3 landIceColor = vec3(219.0, 241.0, 253.0) / 255.0;
const vec3 oceanColor = vec3(6.0, 66.0, 115.0) / 255.0;

void main() {
  float landColorNoise = fbm(vec4(fs_DisplacedPos.xyz * 2.5, 0));
  landColorNoise = smoothstep(0.4, 0.6, landColorNoise);
  vec3 landGreenColor = mix(landGreenColor1, landGreenColor2, landColorNoise);
  vec3 landColor = mix(landGreenColor, landIceColor, smoothstep(0.0, 0.02, fs_Poles));

  vec4 diffuseColor = vec4(mix(oceanColor, landColor, fs_NorDisp), 1);
  
LAMBERT GOES HERE
}
