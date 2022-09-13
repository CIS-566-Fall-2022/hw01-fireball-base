#version 300 es

precision highp float;

uniform mat4 u_ViewMat;
uniform mat4 u_ProjMat;

in vec2 fs_UV;

out vec4 out_Col;

vec3 random3(vec3 p) {
  return fract(sin(vec3(dot(p, vec3(185.3, 563.9, 887.2)),
                        dot(p, vec3(593.1, 591.2, 402.1)),
                        dot(p, vec3(938.2, 723.4, 768.9))
                  )) * 58293.492);
}

struct WorleyInfo {
  float dist;
  vec3 color;
};

WorleyInfo modifiedWorley(vec3 uv) {
  vec3 uvInt = floor(uv);
  vec3 uvFract = uv - uvInt;
  vec3 point = random3(uvInt);
  float dist = distance(point, uvFract);
  vec3 color = random3(point);

  WorleyInfo worleyInfo;
  worleyInfo.dist = dist;
  worleyInfo.color = color;
  return worleyInfo;
}

const float starColorMultiplier = 3.0;
const vec3 starPalette[5] = vec3[](
  vec3(123.0, 208.0, 255.0) / 255.0 * starColorMultiplier,
  vec3(255.0, 220.0, 85.0) / 255.0 * starColorMultiplier,
  vec3(255.0, 116.0, 72.0) / 255.0 * starColorMultiplier,
  vec3(255.0, 169.0, 69.0) / 255.0 * starColorMultiplier,
  vec3(237.0, 251.0, 255.0) / 255.0 * starColorMultiplier
);

vec3 floatToPalette(float val, vec3[5] palette) {
    // more common colors: 1, 4
    // less common color: 0, 3
    // rare color: 2

    if (val < 0.35) {
        return palette[1];
    } else if(val < 0.70) {
        return palette[4];
    } else if(val < 0.82) {
        return palette[0];
    } else if(val < 0.94) {
        return palette[3];
    } else if(val < 1.0) {
        return palette[2];
    }
    return palette[1];
}

void main() {
  vec2 ndc = fs_UV * 2.0 - 1.0;
  vec3 cameraForward = vec3(u_ViewMat[0][2], u_ViewMat[1][2], u_ViewMat[2][2]);
  vec3 cameraRight = vec3(u_ViewMat[0][0], u_ViewMat[1][0], u_ViewMat[2][0]);
  vec3 cameraUp = vec3(u_ViewMat[0][1], u_ViewMat[1][1], u_ViewMat[2][1]);
  vec3 rayDir = normalize(-cameraForward + (ndc.x / u_ProjMat[0][0] * cameraRight) + (ndc.y / u_ProjMat[1][1] * cameraUp));

  WorleyInfo worley = modifiedWorley(rayDir * 50.0);
  float starBrightness = smoothstep(0.08, 0.05, worley.dist);
  vec3 starColor = floatToPalette(worley.color.r, starPalette);

  out_Col = vec4(starColor * starBrightness, 1);
}