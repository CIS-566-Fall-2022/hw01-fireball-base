#version 300 es

uniform int u_Time;

in vec4 vs_Pos;
in vec2 vs_UV;

out vec2 fs_UV;
out vec4 fs_Pos;
out float fs_Time;

void main() {
  fs_UV = vs_UV;
  fs_Pos = vs_Pos;
  fs_Time = float(u_Time);
  gl_Position = vs_Pos;
}
