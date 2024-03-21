#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform vec4 u_CamPos;
uniform float u_Happy;
uniform sampler2D u_Texture;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;


out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

int N_OCTAVES = 1;
#define PI 3.1415926538

float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }

float noise_gen2(float x, float y, float z, float w) {
    return fract(sin(dot(vec4(x, y, z, w), vec4(1.9898, 7.233, 4.984, 100.2974))) * 437.54531);
}

float noise_gen3(float x, float y, float z) {
    return fract(sin(dot(vec3(x, y, z), vec3(0, 1, 0))) * 4337.54531);
}

float fbm_test(float x, float y, float z) {
    float total = 0.f;
    float frequency = 1.f;
    float amplitude = 1.f;
    float maxValue = 0.f;  // Used for normalizing result to 0.0 - 1.0
    float persistence = 0.5f;
    for(int i = 0; i < N_OCTAVES; i++) {
        total += noise_gen3(x * frequency, y * frequency, z * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.f;
    }
    return total/maxValue;
}

float fbm(float x, float y, float z) {
    float total = 0.f;
    float persistence = 1.f / 2.f;
    float amplitude = 1.f;
    float frequency = 1.f;
    for (int i = 0; i < N_OCTAVES; ++i) {
        frequency *= 2.f;
        amplitude *= persistence;
        total += amplitude * noise_gen2(x, y, z, frequency);
    }
    return total;
}

float bias(float t, float b) {
    return (t / ((((1.0/b) - 2.0)*(1.0 - t))+1.0));
}

float easeInOutExpo(float x) {
return x == 0.0
  ? 0.0
  : x == 1.0
  ? 1.0
  : x < 0.5 ? pow(2.0, 20.0 * x - 10.0) / 2.0
  : (2.0 - pow(2.0, -20.0 * x + 10.0)) / 2.0;
}

float easeInOutCubic(float x) {
    return x < 0.5 ? 4.0 * x * x * x : 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0;
}

float fade(float t) {
    return 6.0 * pow(t, 5.0) - 15.0 * pow(t, 4.0) + 10.0 * 10.0 *pow(t, 3.0);
}

vec3 mouthCenter = vec3(0.0, -0.35, -1.2);

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

        float ambientTerm = 0.6;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color

        vec3 yellow = vec3(250.f / 255.f, 188.f / 255.f, 70.f / 255.f);
        vec3 red = vec3(200.f / 255.f, 74.f / 255.f, 50.f / 255.f);

        float dist = length(fs_Pos);
        dist = 1.f;

        dist = acos(dot(normalize(vec3(fs_Nor)), normalize(vec3(u_CamPos))));
        dist /= (2.0*PI);
        dist = fade(dist);
        dist = easeInOutCubic(dist + 0.09f * sin(0.12f * u_Time) + 0.2f);
        vec3 ipol = mix(yellow, red, dist);

        vec3 mouthPoint = vec3(fs_Pos);
        float mouthAngle = acos(dot(normalize(vec3(fs_Pos) - vec3(mouthCenter)), normalize(vec3(0, 1, 0))));
        
        vec3 dir = normalize(mouthPoint - mouthCenter);

        mouthPoint += 0.15f * sin(u_Happy * -mouthAngle * 2.2f + 1.2f) * dir;

        float mouthDist = length(vec3(mouthPoint) - vec3(mouthCenter));
        float mouthDistY = abs(mouthPoint.y - mouthCenter.y);

        if (mouthDist <= 0.17f) {
            vec3 mouth = vec3(161.f / 255.f, 61.f / 255.f, 34.f / 255.f);
            ipol = mouth;
        }
        if (mouthDist >= 0.17f && mouthDist <= 0.192f) {
            float t = (mouthDist - 0.17f) / 0.022f;
            vec3 mouth = vec3(161.f / 255.f, 61.f / 255.f, 34.f / 255.f);
            ipol = mix(mouth, ipol, t);
        }

        out_Col = vec4(ipol, 1.0f);
}
