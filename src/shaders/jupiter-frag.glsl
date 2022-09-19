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

const vec3 jupiterBaseColor1 = vec3(193.0, 181.0, 163.0) / 255.0;
const vec3 jupiterBaseColor2 = vec3(172.0, 149.0, 110.0) / 255.0;
const vec3 jupiterHighlightColor1 = vec3(205.0, 134.0, 54.0) / 255.0;
const vec3 jupiterHighlightColor2 = vec3(255.0, 136.0, 3.0) / 255.0;
const vec3 jupiterStormsBlueColor1 = vec3(48.0, 173.0, 240.0) / 255.0;
const vec3 jupiterStormsBlueColor2 = vec3(30.0, 118.0, 212.0) / 255.0 * 0.5;
const vec3 jupiterStormsRedColor1 = vec3(252.0, 73.0, 3.0) / 255.0;
const vec3 jupiterStormsRedColor2 = vec3(201.0, 45.0, 14.0) / 255.0 * 0.5;

void main() {
  float verticalNoiseLarge = perlin(fs_OriginalPos.y * 3.0 + 10.0 + perlin(fs_OriginalPos.xyz * 3.0, u_Time / 2000.0) * 0.15);
  verticalNoiseLarge = smoothstep(-0.1, 0.1, verticalNoiseLarge);
  verticalNoiseLarge = clamp(verticalNoiseLarge, 0.0, 1.0);
  float verticalNoiseSmall = perlin(fs_OriginalPos.y * 25.0 + 100.0 + perlin(fs_OriginalPos.xyz * 5.0, u_Time / 3000.0) * 0.8) * 0.2;
  float verticalNoiseThin = perlin(fs_OriginalPos.y * 10.0 + 30.0 + perlin(fs_OriginalPos.xyz * 20.0, u_Time / 4000.0) * 0.2);
  verticalNoiseThin = clamp(verticalNoiseThin, 0.0, 1.0);

  float blueStormsNoise = worley(fs_OriginalPos.xyz * 7.0 + perlin(fs_OriginalPos * 20.0) * 10.0, u_Time / 5000.0).dist;
  vec3 blueStormsColor = mix(jupiterStormsBlueColor1, jupiterStormsBlueColor2, blueStormsNoise);
  float polesNoise = abs(dot(fs_Nor.xyz, vec3(0, 1, 0))) + blueStormsNoise * 0.1;
  polesNoise = smoothstep(0.94, 1.0, polesNoise);

  float redStormsNoise = fbm(fs_OriginalPos.xyz * 10.0, u_Time / 1500.0) * blueStormsNoise;
  vec3 redStormsColor = mix(jupiterStormsRedColor1, jupiterStormsRedColor2, redStormsNoise);
  redStormsNoise = smoothstep(0.0, 0.5, redStormsNoise);
  float redStormsDistance = distance(fs_OriginalPos.xyz * vec3(1.0, 1.5, 1.0) + perlin(fs_OriginalPos.xyz * 10.0) * 0.05, vec3(1.2, -0.32, 0));
  redStormsDistance = smoothstep(0.3, 0.20, redStormsDistance);
  redStormsNoise = smoothstep(0.0, 0.3, redStormsNoise) * redStormsDistance;

  vec3 jupiterColor = mix(jupiterBaseColor1, jupiterBaseColor2, verticalNoiseLarge);
  jupiterColor += jupiterHighlightColor1 * verticalNoiseSmall;
  jupiterColor = mix(jupiterColor, jupiterHighlightColor2, verticalNoiseThin * 0.5);
  jupiterColor = mix(jupiterColor, blueStormsColor, polesNoise * 0.45);
  jupiterColor = mix(jupiterColor, redStormsColor, redStormsNoise * 0.4);

  float stripeNoise = smoothstep(0.35, 0.15, abs(fs_OriginalPos.y + 0.28 + perlin(fs_OriginalPos.xyz * 4.0, u_Time / 2000.0) * 0.1));
  jupiterColor += redStormsColor * stripeNoise * 0.15;

  vec4 diffuseColor = vec4(jupiterColor * 0.5, 1);

LAMBERT GOES HERE
}
