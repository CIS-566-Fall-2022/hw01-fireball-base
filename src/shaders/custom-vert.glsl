#version 300 es

// Custom vertex shader

precision highp float;

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform int u_Time;         // The tick function time component

uniform float u_Amp;          // The amplitude of 3Dfbm

uniform float u_Freq;       // The freq of 3Dfbm

uniform int u_Oct;        // The number of octaves

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

out float fs_Time;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

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
    int octaves = u_Oct;
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
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vs_Pos;                         // Pass the pos to the fragment shader for noise interpolation
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    float t = float(u_Time) * 0.01;
    fs_Time = t;
    vec3 animPos = vs_Pos.xyz;
    animPos.x = (bias(cos(t), 0.1) * vs_Pos.x - bias(sin(t),0.1) * vs_Pos.y);
    animPos.y = (sin(t) * vs_Pos.x + cos(t) * vs_Pos.y);
    vec3 offset = vec3(cos(t), sin(t), -cos(t));
    //offset.x = cos(t) * t - sin(t) * t;
    //offset.y = cos(t) * t - sin(t) * t;
    animPos += offset;

    float noise = fbm3D(animPos.x,animPos.y,animPos.z);
    float noise2 = fbmLOW(animPos.x,animPos.y,animPos.z);
    float x = vs_Pos.x + noise * vs_Nor.x + gain(noise2 * vs_Nor.x, 0.2);
    float y = vs_Pos.y + noise * vs_Nor.y + gain(noise2 * vs_Nor.y, 0.5);
    float z = vs_Pos.z + noise * vs_Nor.z + gain(noise2 * vs_Nor.z, 0.7);
    vec4 altPos = vec4(x,y,z, 1.f);

    // linearly interpolate original position with respect to time and cos funct
    // vec4 modelposition = uS_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    vec4 modelposition = u_Model * altPos; 

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
