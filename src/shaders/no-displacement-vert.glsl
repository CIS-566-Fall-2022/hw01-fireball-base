#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;

in vec4 vs_Pos;
in vec4 vs_Nor;

out vec4 fs_Nor;
out vec4 fs_Pos;

out vec4 fs_OriginalPos;

uniform float u_Time;
void main() {
  mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

  fs_OriginalPos = vs_Pos;

  vec4 modelPosition = u_Model * vs_Pos;
  fs_Pos = modelPosition;
  gl_Position = u_ViewProj * modelPosition;
}
