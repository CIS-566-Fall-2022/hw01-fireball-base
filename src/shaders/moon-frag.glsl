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

const vec3 moonColor1 = vec3(145.0) / 255.0;
const vec3 moonColor2 = vec3(89.0, 96.0, 97.0) / 255.0;

void main() {
  float moonColorNoise = fbm(vec4(fs_DisplacedPos.xyz * 20.0, 0));
  vec3 moonColor = mix(moonColor1, moonColor2, smoothstep(0.3, 0.7, moonColorNoise));
  moonColor *= mix(0.85, 1.0, smoothstep(0.0, 0.01, fs_NorDisp));

  vec4 diffuseColor = vec4(moonColor, 1);

LAMBERT GOES HERE
}
