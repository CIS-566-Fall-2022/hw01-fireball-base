#version 300 es

precision highp float;

in vec4 fs_Nor;
in vec4 fs_Pos;

in vec4 fs_OriginalPos;

uniform vec3 u_CameraPos;

uniform float u_Time;

out vec4 out_Col;

NOISE GOES HERE

const vec3 ringsColor1 = vec3(92.0, 85.0, 66.0) / 255.0 * 0.8;
const vec3 ringsColor2 = vec3(108.0, 98.0, 73.0) / 255.0;

const float ringsStart = 1.5;
const float ringsEnd = 3.0;

const float gapStart = 0.60;
const float gapEnd = 0.68;

void main() {
  float dist = distance(vec3(0), fs_OriginalPos.xyz);
  dist = (dist - ringsStart) / (ringsEnd - ringsStart);

  float colorNoise = (perlin(dist * 30.0) + 1.0) / 2.0;
  vec3 ringsColor = mix(ringsColor1, ringsColor2, colorNoise);
  if (dist > gapEnd) {
    ringsColor *= 0.7;
  }

  float alphaDistFalloff = mix(0.7, 1.0, smoothstep(0.0, 0.15, dist));
  float gapAlpha = (dist < gapStart || dist > gapEnd) ? 1.0 : 0.0;
  float alphaNoise = perlin(dist * 50.0 + 100.0);
  alphaNoise = mix(0.8, 1.0, smoothstep(-0.7, 0.7, alphaNoise));
  float alpha = alphaNoise * alphaDistFalloff * gapAlpha;

  if (alpha < 0.01) {
    discard;
  }

  out_Col = vec4(ringsColor, alpha);
  // out_Col = vec4(vec3(1.0), 1);
}
