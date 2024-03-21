#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform vec4 u_CamPos;

uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;


const vec4 lightPos = vec4(0, 5, 0, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

int N_OCTAVES = 1;

// Precision-adjusted variations of https://www.shadertoy.com/view/4djSRW
float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }
float hash(vec2 p) {vec3 p3 = fract(vec3(p.xyx) * 0.13); p3 += dot(p3, p3.yzx + 3.333); return fract((p3.x + p3.y) * p3.z); }

// By Morgan McGuire @morgan3d, http://graphicscodex.com
//3D value noise used from Shadertoy, https://www.shadertoy.com/view/4dS3Wd
//Fbm and etc. implemented by me
float noise_gen4(vec3 x) {
    // 
    vec3 step = vec3(110.f, 241.f, 171.f);

    vec3 i = floor(x);
    vec3 f = fract(x);
 
    // // For performance, compute the base input to a 1D hash from the integer part of the argument and the 
    // // incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float fbm(float x, float y, float z, float persistence, int N_OCTAVES) {
    float total = 0.f;
    float frequency = 1.f;
    float amplitude = 1.f;
    float maxValue = 0.f;  // Used for normalizing result to 0.0 - 1.0
    // float persistence = 0.5f;
    for(int i = 0; i < N_OCTAVES; i++) {
        total += noise_gen4(vec3(x * frequency, y * frequency, z * frequency)) * amplitude;
        // total += noise_gen4(vec3(x, y, z) * amplitude);
        // noise_gen4(vec3 (1.f));
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.f;
    }
    return total/maxValue;
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

//let leftEyeCenter: vec3 = vec3.fromValues(0.65, 0.1, -1.2);

vec3 leftEyeCenter = vec3(0.65, 0.1, -1.2);
vec3 mouthCenter = vec3(0.0, -0.3, -1.2);

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = normalize(vec4(invTranspose * vec3(vs_Nor), 0));

    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    vec3 tempPos = vec3(modelposition);
    vec3 center = mouthCenter;

    //First, calculate the angle between tempPos and the center

    // float angle = acos(dot(normalize(tempPos + vec3(0, 0, 0)), vec3(0, 1, 0)));

    // float weight = (1.f / (angle + 0.45f));
    float weight = 1.f;
    // float angle_1 = acos(dot(normalize(vec3(vs_Pos)), vec3(0, 0, 1)));
    weight = length(vec3(tempPos) - center);
    // tempPos += 0.1f * weight * vec3(0, 0, 1);
    // tempPos += 0.04f * angle_1 * vec3(normalize(vec4(invTranspose * vec3(vs_Nor), 0)));
    fs_LightVec = lightPos - vec4(tempPos, 1.f);

    gl_Position = u_ViewProj * vec4(tempPos, 1.f);// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices

    fs_Pos = vec4(tempPos, 1.f);
}
