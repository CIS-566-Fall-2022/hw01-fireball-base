#version 300 es

// Custom frag shader

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

uniform float u_Amp; // Amp of 3Dfbm

uniform float u_Freq; // Freq of 3Dfbm

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float fs_Time;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float noise3D( vec3 p ) {
    return fract(sin(dot(p, vec3(127.1f, 311.7f, 245.3f))) *
                 43758.5453);
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
    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);
    float j1 = mix(i1, i2, fractY);
    float j2 = mix(i3, i4, fractY);

    return mix(j1, j2, fractZ);
}

float fbm3D(float x, float y, float z) {
    float total = 0.f;
    float persistence = 0.5f;
    int octaves = 8;
    float freq = u_Freq;
    float amp = u_Amp;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(x * freq,
                               y * freq, z * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

float fbmLOW(float x, float y, float z) {
    float total = 0.f;
    float persistence = 0.5f;
    int octaves = 2;
    float freq = 0.2;
    float amp = 0.8;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(x * freq,
                               y * freq, z * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

float bias(float t, float b) {
    return (t / ((((1.0f/b) - 2.0f)*(1.0f - t)) + 1.0f));
}

float gain(float t, float g) {
    if (t < 0.5)
        return bias(t * 2.0, g)/2.0;
    else
        return bias(t * 2.0 - 1.0, 1.0 - g)/2.0 + 0.5;
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        float t = fs_Time;
        vec3 animPos = fs_Pos.xyz;
        animPos.x = (bias(cos(t), 0.1) * fs_Pos.x - bias(sin(t),0.1) * fs_Pos.y);
        animPos.y = (sin(t) * fs_Pos.x + cos(t) * fs_Pos.y);
        vec3 offset = vec3(cos(t), sin(t), -cos(t));
        animPos += offset;

        float noise = fbm3D(animPos.x,animPos.y,animPos.z);
        float noise2 = fbmLOW(animPos.x,animPos.y,animPos.z);
        float x = fs_Pos.x + noise * fs_Nor.x + gain(noise2 * fs_Nor.x, 0.2);
        float y = fs_Pos.y + noise * fs_Nor.y + gain(noise2 * fs_Nor.y, 0.5);
        float z = fs_Pos.z + noise * fs_Nor.z + gain(noise2 * fs_Nor.z, 0.7);
        
        float fbmNoise = fbm3D(float(x), float(y), float(z));
        float dist = 10.0f * length(vec3(x,y,z) - (1.0f * fs_Nor.xyz));
        dist = dist - ((u_Amp + 0.3) * 10.0f);
        vec3 colorChange = vec3(dist * fbmNoise, dist * fbmNoise, -dist * fbmNoise);
        // vec3 colorChange = vec3(fbmNoise, fbmNoise, -1.f * fbmNoise);
        diffuseColor = clamp(diffuseColor + vec4(colorChange, 0.f), 0.f, 1.f);

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);
 
        float ambientTerm = 0.5f; //0.2f

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
