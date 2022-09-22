#version 300 es

#ifdef GL_ES
precision mediump float;
#endif

uniform float u_Warmth;

in vec2 fs_UV;
in float fs_Time;

out vec4 out_Col;

Add Background Shader

void main() {
    out_Col = colorizeBack();
}
