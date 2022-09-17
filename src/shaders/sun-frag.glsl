#version 300 es

precision highp float;

in vec4 fs_Nor;
in vec4 fs_Pos;

in vec4 fs_DisplacedPos;
in float fs_NorDisp;

uniform vec3 u_CameraPos;

uniform float u_Time;

uniform float u_TimeScale;
uniform float u_Temperature;

out vec4 out_Col;

NOISE GOES HERE

const vec3 sunColorRed1 = vec3(130.0, 0.0, 0.0) / 255.0 * 1.2;
const vec3 sunColorRed2 = vec3(214.0, 70.0, 14.0) / 255.0 * 1.4;
const vec3 sunColorOrange1 = vec3(211.0, 49.0, 3.0) / 255.0;
const vec3 sunColorOrange2 = vec3(255.0, 161.0, 67.0) / 255.0;
const vec3 sunColorYellow1 = vec3(191.0, 160.0, 20.0) / 255.0 * 0.5;
const vec3 sunColorYellow2 = vec3(255.0, 210.0, 13.0) / 255.0 * 0.8;
const vec3 sunColorWhite1 = vec3(252.0, 252.0, 252.0) / 255.0 * 0.4;
const vec3 sunColorWhite2 = vec3(247.0, 255.0, 254.0) / 255.0 * 0.6;
const vec3 sunColorBlue1 = vec3(179.0, 231.0, 255.0) / 255.0 * 0.4;
const vec3 sunColorBlue2 = vec3(222.0, 248.0, 255.0) / 255.0 * 0.6;

vec3 getSunColor(float temperature, float mixFactor) {
  vec3 color1;
  vec3 color2;

  if (temperature < 4500.0) {
    float mixFactor2 = smoothstep(2000.0, 4500.0, temperature);
    color1 = mix(sunColorRed1, sunColorOrange1, mixFactor2);
    color2 = mix(sunColorRed2, sunColorOrange2, mixFactor2);
  } else if (temperature < 9000.0) {
    float mixFactor2 = smoothstep(4500.0, 9000.0, temperature);
    color1 = mix(sunColorOrange1, sunColorYellow1, mixFactor2);
    color2 = mix(sunColorOrange2, sunColorYellow2, mixFactor2);
  } else if (temperature < 13000.0) {
    float mixFactor2 = smoothstep(9000.0, 13000.0, temperature);
    color1 = mix(sunColorYellow1, sunColorWhite1, mixFactor2);
    color2 = mix(sunColorYellow2, sunColorWhite2, mixFactor2);
  } else {
    float mixFactor2 = smoothstep(13000.0, 28000.0, temperature);
    color1 = mix(sunColorWhite1, sunColorBlue1, mixFactor2);
    color2 = mix(sunColorWhite2, sunColorBlue2, mixFactor2);
  }

  return mix(color1, color2, mixFactor);
}

void main() {
  float time = u_Time * u_TimeScale;

  float colorNoiseDisplace = perlin(fs_DisplacedPos.xyz * 1.5, time / 10000.0);
  colorNoiseDisplace = smoothstep(0.1, 0.8, colorNoiseDisplace);
  float colorNoise = fbm(vec4(fs_DisplacedPos.xyz * 30.0 + colorNoiseDisplace * 10.0, time / 3500.0));
  vec3 baseColor = getSunColor(u_Temperature, smoothstep(0.25, 0.75, colorNoise));

  float emissionNoise = perlin(fs_DisplacedPos.xyz, time / 4500.0);
  emissionNoise = smoothstep(0.5, 0.75, emissionNoise);
  emissionNoise = perlin((fs_DisplacedPos.xyz * 1.5) + emissionNoise, time / 4500.0);

  float aura = smoothstep(0.35, 0.0, dot(fs_Nor.xyz, normalize(u_CameraPos - fs_Pos.xyz)));
  float emissionStrength = 1.5 
          + colorNoiseDisplace * 5.0
          + emissionNoise * 0.6
          + fs_NorDisp * 2.0
          + aura * 2.0;
  
  out_Col = vec4(baseColor * emissionStrength, 1);
}
