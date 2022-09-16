#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;

in vec4 vs_Pos;
in vec4 vs_Nor;

out vec4 fs_Nor;
out vec4 fs_Pos;

out vec4 fs_DisplacedPos;
out float fs_NorDisp;

uniform float u_Time;

NOISE GOES HERE

void main() {
  mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

  fs_DisplacedPos = vs_Pos;

  fs_NorDisp = worley(vec4(vs_Pos.xyz * 40.0, 0)).dist * 0.01;

  fs_DisplacedPos.xyz += fs_NorDisp * vs_Nor.xyz;

  vec4 modelPosition = u_Model * fs_DisplacedPos;
  fs_Pos = modelPosition;
  gl_Position = u_ViewProj * modelPosition;
}
