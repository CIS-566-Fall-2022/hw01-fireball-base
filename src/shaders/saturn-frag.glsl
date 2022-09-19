#version 300 es

precision highp float;

#define NO_LAMBERT

in vec4 fs_Nor;
in vec4 fs_Pos;

in vec4 fs_OriginalPos;

uniform vec3 u_CameraPos;

uniform float u_Time;

out vec4 out_Col;

NOISE GOES HERE

const vec3 saturnBaseColor1 = vec3(190.0, 193.0, 163.0) / 255.0;
const vec3 saturnBaseColor2 = vec3(173.0, 156.0, 104.0) / 255.0;
const vec3 saturnStormsBlueColor1 = vec3(48.0, 173.0, 240.0) / 255.0;
const vec3 saturnStormsBlueColor2 = vec3(30.0, 118.0, 212.0) / 255.0 * 0.5;

void main() {
  float verticalNoise = perlin(fs_OriginalPos.y * 3.0 + 10.0 + perlin(fs_OriginalPos.xyz * 2.0, u_Time / 2000.0) * 0.05);
  verticalNoise = mix(verticalNoise, verticalNoise * perlin(fs_OriginalPos.y * 20.0), 0.5);
  verticalNoise = smoothstep(-0.1, 0.1, verticalNoise);
  verticalNoise = clamp(verticalNoise, 0.0, 1.0);
  verticalNoise = mix(0.36, 0.64, verticalNoise);

  float poles = abs(dot(fs_Nor.xyz, vec3(0, 1, 0)));
  float polesMultiplier = sin(atan(fs_OriginalPos.z, fs_OriginalPos.x) * 6.0);
  polesMultiplier = (polesMultiplier + 1.0) / 2.0;
  poles *= mix(0.996, 1.0, polesMultiplier);
  poles = smoothstep(0.92, 0.98, poles);
  vec3 saturnBlueStormsColor = mix(saturnStormsBlueColor1, saturnStormsBlueColor2, perlin(vec3(poles * 5.0)));
  
  vec3 saturnColor = mix(saturnBaseColor1, saturnBaseColor2, verticalNoise);
  saturnColor = mix(saturnColor, saturnBlueStormsColor, poles * 0.15);

  vec4 diffuseColor = vec4(saturnColor, 1);

LAMBERT GOES HERE
}
