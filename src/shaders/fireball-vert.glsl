#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;

uniform float u_Time;
uniform float u_Amplitude;
uniform float u_Freq;
uniform float u_Presistence;
uniform int u_Octaves;
uniform float u_Rate;

in vec4 vs_Pos;

in vec4 vs_Nor;
in vec4 vs_Col;

out vec4 fs_Nor;
out vec4 fs_LightVec;
out vec4 fs_Col;

out float fs_offset;

const vec4 lightPos = vec4(5, 5, 3, 1);

const float PI = 3.14159265359;

vec2 random2(vec2 p){
  return normalize(2.f * fract(sin(vec2(dot(p,vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)))) * 43758.5453f) - 1.f);
}

vec3 random3(vec3 p){
  return normalize(2.f * fract(sin(vec3(dot(p, vec3(127.1, 311.7, 191.999)),
                                        dot(p, vec3(269.5, 183.3, 191.999)),
                                        dot(p, vec3(420.6, 631.2, 191.999)))) * 43758.5453f) - 1.f);         
}

float noise3D(vec3 p) {
  return fract(sin(dot(p, vec3(127.1, 311.7, 183.3))) * 43758.5453);
}

float surflet(vec3 p, vec3 gridPoint)
{
  float distX = abs(p.x - gridPoint.x);
  float distY = abs(p.y - gridPoint.y);
  float distZ = abs(p.z - gridPoint.z);
  float tX = 1.0 - 6.0 * pow(distX, 5.0) + 15.0 * pow(distX, 4.0) - 10.0 * pow(distX, 3.0);
  float tY = 1.0 - 6.0 * pow(distY, 5.0) + 15.0 * pow(distY, 4.0) - 10.0 * pow(distY, 3.0);
  float tZ = 1.0 - 6.0 * pow(distZ, 5.0) + 15.0 * pow(distZ, 4.0) - 10.0 * pow(distZ, 3.0);

  vec3 gradient = vec3(random3(gridPoint));
  vec3 diff = p - gridPoint;
  float height = dot(diff, gradient);
  return height * tX * tY * tZ;
}

float perlinNoise3D(vec3 p)
{
  vec3 pFloor = vec3(floor(p.x), floor(p.y), floor(p.z));
  float surfletSum = 0.0f;

  for(int dx = 0; dx <= 1; ++dx)
  {
    for(int dy = 0; dy <= 1; ++dy)
    {
      for(int dz = 0; dz <= 1; ++dz)
      {
        surfletSum += surflet(p, pFloor + vec3(dx, dy, dz));
      }
    }
  }

  return surfletSum;
}

float cosineInterpolate(float a, float b, float t) {
  float cos_t = (1.0 - cos(t * PI)) * 0.5f;
  return mix(a, b, cos_t);
}

float interpNoise3D(float x, float y, float z) {
  int intX = int(floor(x));
  float fractX = fract(x);
  int intY = int(floor(y));
  float fractY = fract(y);
  int intZ = int(floor(z));
  float fractZ = fract(z);

  float v1 = noise3D(vec3(intX, intY, intZ));
  float v2 = noise3D(vec3(intX + 1, intY, intZ));
  float v3 = noise3D(vec3(intX, intY + 1, intZ));
  float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
  float v5 = noise3D(vec3(intX, intY, intZ + 1));
  float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
  float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
  float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

  float i1 = cosineInterpolate(v1, v2, fractX);
  float i2 = cosineInterpolate(v3, v4, fractX);
  float i3 = cosineInterpolate(v5, v6, fractX);
  float i4 = cosineInterpolate(v7, v8, fractX);

  float mix1 = cosineInterpolate(i1, i2, fractY);
  float mix2 = cosineInterpolate(i3, i4, fractY);

  return cosineInterpolate(mix1, mix2, fractZ);
}

float fbm3D(vec3 point, float persistence, int octaves)
{
  float total = 0.f;
  for(int i = 1; i <= octaves; i++) {
      float freq = pow(2.f, float(i));
      float amp = pow(persistence, float(i));
      total += interpNoise3D(point.x * freq, point.y * freq, point.z * freq) * amp;
  }
  return total;
}

mat4 rotateAboutYMat(float angle)
{
  return mat4(cos(angle), 0, sin(angle), 0,
              0, 1, 0, 0,
              -sin(angle), 0, cos(angle), 0,
              0, 0, 0, 1);
}

void main()
{
    float time = u_Time * u_Amplitude;

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0); 

    float lowFreqHighAmp_offset = 0.8f * perlinNoise3D(sin(vs_Pos.xyz * vec3(u_Freq) * time / 1000.0)); //freq for perlin
    float highFreqLowAmp_offset = 0.5f * fbm3D(sin(vs_Pos.xyz + time / 2000.0), u_Presistence, u_Octaves); //persistence, octaves

    float offset = lowFreqHighAmp_offset + highFreqLowAmp_offset;
    fs_offset = offset;

    vec4 newPos = vs_Pos + (offset * vs_Nor * 2.0); //amplitude
    newPos = (newPos * rotateAboutYMat(float(time) / float((1.0/u_Rate) * 1000.0)));

    vec4 modelposition = u_Model * newPos;
    fs_Col = modelposition;

    fs_LightVec = lightPos - modelposition;

    gl_Position = u_ViewProj * modelposition;
}
