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

float random1(float p) {
  return fract(sin(p * 592.4) * 102934.239);
}

vec3 random3(vec3 p) {
  return fract(sin(vec3(dot(p, vec3(185.3, 563.9, 887.2)),
                        dot(p, vec3(593.1, 591.2, 402.1)),
                        dot(p, vec3(938.2, 723.4, 768.9))
                  )) * 58293.492);
}

vec4 random4(vec4 p) {
  return fract(sin(vec4(dot(p, vec4(127.1, 311.7, 921.5, 465.8)),
                        dot(p, vec4(269.5, 183.3, 752.4, 429.1)),
                        dot(p, vec4(420.6, 631.2, 294.3, 910.8)),
                        dot(p, vec4(213.7, 808.1, 126.8, 572.0))
                  )) * 43758.5453);
}

float surflet(vec4 p, vec4 gridPoint) {
  vec4 t2 = abs(p - gridPoint);
  vec4 t = vec4(1.f) - 6.f * pow(t2, vec4(5.f)) + 15.f * pow(t2, vec4(4.f)) - 10.f * pow(t2, vec4(3.f));
  vec4 gradient = random4(gridPoint) * 2. - vec4(1.);
  vec4 diff = p - gridPoint;
  float height = dot(diff, gradient);
  return height * t.x * t.y * t.z * t.w;
}

float perlin(vec4 p) {
	float surfletSum = 0.f;

	for (int dx = 0; dx <= 1; ++dx) {
		for (int dy = 0; dy <= 1; ++dy) {
			for (int dz = 0; dz <= 1; ++dz) {
        for (int dw = 0; dw <= 1; ++dw) {
          surfletSum += surflet(p, floor(p) + vec4(dx, dy, dz, dw));
        }
			}
		}
	}

	return surfletSum;
}

#define OCTAVES 4
float fbm(vec4 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < OCTAVES; ++i) {
    value += amplitude * ((perlin(p) + 1.0) / 2.0);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}

struct WorleyInfo {
  float dist;
  vec3 color;
};

WorleyInfo worley(vec4 uv) {
  vec4 uvInt = floor(uv);
  vec4 uvFract = uv - uvInt;
  float minDist = 1.0f;

  vec3 color;
  for (int x = -1; x <= 1; ++x) {
    for (int y = -1; y <= 1; ++y) {
      for (int z = -1; z <= 1; ++z) {
        for (int w = -1; w <= 1; ++w) {
          vec4 neighbor = vec4(float(x), float(y), float(z), float(w));
          vec4 point = random4(uvInt + neighbor);

          if (random1(point.x) < 0.8) {
            continue;
          }

          vec4 diff = neighbor + point - uvFract;
          float dist = length(diff);
          if (dist < minDist) {
            minDist = dist;
            color = random4(point).rgb;
          }
        }
      }
    }
  }

  WorleyInfo worleyInfo;
  worleyInfo.dist = minDist;
  worleyInfo.color = color;
  return worleyInfo;
}

void main() {
  mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);

  fs_DisplacedPos = vs_Pos;

  fs_NorDisp = worley(vec4(vs_Pos.xyz * 700.0, 0)).dist * 0.05;

  fs_DisplacedPos.xyz += fs_NorDisp * vs_Nor.xyz;

  vec4 modelPosition = u_Model * fs_DisplacedPos;
  fs_Pos = modelPosition;
  gl_Position = u_ViewProj * modelPosition;
}
