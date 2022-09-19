#version 300 es

precision highp float;

// #define NO_LAMBERT

in vec4 fs_Nor;
in vec4 fs_Pos;

in vec4 fs_DisplacedPos;
in float fs_NorDisp;

uniform vec3 u_CameraPos;

uniform float u_Time;

out vec4 out_Col;

NOISE GOES HERE

const vec3 asteroidColor1 = vec3(145.0) / 255.0;
const vec3 asteroidColor2 = vec3(89.0, 96.0, 97.0) / 255.0;

void main() {
  float asteroidColorNoise = fbm(vec4(fs_DisplacedPos.xyz * 20.0, 0));
  vec3 asteroidColor = mix(asteroidColor1, asteroidColor2, smoothstep(0.3, 0.7, asteroidColorNoise));
  asteroidColor *= mix(0.65, 1.0, smoothstep(0.0, 0.12, fs_NorDisp)) * 0.6;

  vec4 diffuseColor = vec4(asteroidColor, 1);

LAMBERT GOES HERE
}
