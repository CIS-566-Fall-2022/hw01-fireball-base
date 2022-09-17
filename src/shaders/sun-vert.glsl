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

uniform float u_DisplacementHeight;
uniform float u_TimeScale;

NOISE GOES HERE

void main() {
  float time = u_Time * u_TimeScale;

  mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

  fs_DisplacedPos = vs_Pos;

  fs_NorDisp = smoothstep(0.0, 4.0, worley(vs_Pos.xyz * 1.2, time / 2000.0).dist) * 0.5;
  fs_NorDisp += worley(vs_Pos.xyz * 7.0, time / 2000.0).dist * 0.1;
  fs_NorDisp += fbm(vs_Pos.xyz * 5.0, time / 4000.0) * 0.2;

  fs_DisplacedPos.xyz += fs_NorDisp * vs_Nor.xyz * u_DisplacementHeight * 1.5;

  vec4 modelPosition = u_Model * fs_DisplacedPos;
  fs_Pos = modelPosition;
  gl_Position = u_ViewProj * modelPosition;
}
