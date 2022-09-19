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
precision highp int;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform int u_Time;   // The current time elapsed since the start of the program.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

const float PI = 3.1415926535897932384626433832795;

// From Inigo Quilez - "Color Palettes" https://iquilezles.org/articles/palettes/ 
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

// Noise function implementation based on CIS 560 and CIS 566 Slides - "Noise Functions"
float noise3D(vec3 p) 
{
    return fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);
}

float cosineInterpolate(float a, float b, float t)
{
    float cos_t = (1.f - cos(t * PI)) * 0.5f;
    return mix(a, b, cos_t);
}

float interpolateNoise3D(float x, float y, float z)
{
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
    float mix1 = cosineInterpolate(i1, i2, fractY);
    float i3 = cosineInterpolate(v5, v6, fractX);
    float i4 = cosineInterpolate(v7, v8, fractX);
    float mix2 = cosineInterpolate(i3, i4, fractY);
    return cosineInterpolate(mix1, mix2, fractZ);
}

float fbm3D(vec3 p)
{
    float total = 0.f;
    float persistence = 0.5f;
    int octaves = 8;

    for (int i = 1; i < octaves; ++i)
    {
        float freq = pow(2.f, float(i));
        float amp = pow(persistence, float(i));

        total += amp * interpolateNoise3D(p.x * freq, p.y * freq, p.z * freq);
    }

    return total;
}

// TODO: redo this
// https://gist.github.com/companje/29408948f1e8be54dd5733a74ca49bb9
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main()
{
        // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Define color palette
        /*vec3 a = vec3(1.0, 0.4, 0.0);
        vec3 b = vec3(0.4, 0.8, 0.0);
        vec3 c = vec3(0.45, 0.3, 0.9);
        vec3 d = vec3(0.9, 0.25, 0.5);*/

        vec3 a = vec3(0.5f);
        vec3 b = vec3(0.5f);
        vec3 c = vec3(1.0f);
        vec3 d = vec3(0.0f, 0.1f, 0.2f);
        //float t = 0.5f * sin(float(u_Time) / 500.f);    

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        //diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Calculate noise (distorted FBM)
        //float s = 0.5 * (sin(float(u_Time) / 500.0f) + 1.f);
        float s = 4.0;
        vec3 p1 = vec3(fbm3D(fs_Pos.xyz), fbm3D(fs_Pos.xyz + vec3(1.3f, 3.5f, 4.5f)), fbm3D(fs_Pos.xyz + vec3(4.4f, 3.2f, 9.0f)));
        vec3 p2 = vec3(fbm3D(fs_Pos.xyz), fbm3D(fs_Pos.xyz + vec3(10.3f, 3.3f, 1.4f)), fbm3D(fs_Pos.xyz + vec3(5.6f, 45.2f, 2.0f)));
        float fbmDist = fbm3D(p1 + s * p2);

        float fbm = 1.f - fs_Col.x;
        //float fbm = smoothstep(0.0, 1.0, 1.f - fs_Col.x);
        //fbm = map(fbmDist + fs_Col.x, 0.0, 2.0, 0.0, 0.55);
        fbm = map(1.f - fbm, 0.0, 1.0, 0.0, 0.3);

        // Compute final shaded color
        vec3 paletteColor = palette(fbm, a, b, c, d);
        //diffuseColor.xyz = mix(diffuseColor.xyz, paletteColor.xyz, fbm);
        out_Col = vec4(paletteColor.xyz, 1.0);
        //out_Col = fs_Col;
}
