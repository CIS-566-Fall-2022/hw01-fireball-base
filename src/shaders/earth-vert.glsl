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

out float fs_Poles;

uniform float u_Time;

NOISE GOES HERE

void main() {
  mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

  fs_DisplacedPos = vs_Pos;

  fs_Poles = abs(dot(fs_Nor.xyz, vec3(0, 1, 0)));
  fs_Poles += perlin(vec4(vs_Pos.xyz * 10.0, 0)) * 0.2;

  fs_NorDisp = smoothstep(0.48, 0.52, fbm(vec4(vs_Pos.xyz * 2.0, 0)));
  fs_NorDisp = max(0.0, fs_NorDisp - smoothstep(0.68, 0.75, fs_Poles));
  
  fs_Poles = smoothstep(0.85, 0.92, fs_Poles);
  fs_NorDisp += fs_Poles;
  fs_NorDisp = min(fs_NorDisp, 1.0);

  fs_DisplacedPos.xyz += fs_NorDisp * vs_Nor.xyz * 0.02;

  vec4 modelPosition = u_Model * fs_DisplacedPos;
  fs_Pos = modelPosition;
  gl_Position = u_ViewProj * modelPosition;
}
