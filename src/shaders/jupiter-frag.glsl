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

void main() {
  vec4 diffuseColor = vec4(1, 0, 0, 1);

LAMBERT GOES HERE
}
