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
uniform vec4 u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Pos;
out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Displacement;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

int[] perm = int[](
    151,160,137,91,90,15,
    131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
    190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
    88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
    77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
    102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
    135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
    5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
    223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
    129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
    251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
    49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
    138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
    151
);
int perm1plus(int i, int k) { return int(mod(float(perm[i]) + float(k), 256.)); }

float Fade(float t) { return t * t * t * (t * (t * 6. - 15.) + 10.); }

float Grad(int hash, float x, float y, float z) {
    int h = hash & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : (h == 12 || h == 14 ? x : z);
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

float Noise3D(vec3 val) {
    vec3 v1 = floor(val);
    vec3 v2 = fract(val);
    int X = int(mod(v1.x, 256.));
    int Y = int(mod(v1.y, 256.));
    int Z = int(mod(v1.z, 256.));
    float x = v2.x;
    float y = v2.y;
    float z = v2.z;
    float u = Fade(x);
    float v = Fade(y);
    float w = Fade(z);
    int A  = perm1plus(X, Y);
    int B  = perm1plus(X+1, Y);
    int AA = perm1plus(A, Z);
    int BA = perm1plus(B, Z);
    int AB = perm1plus(A+1, Z);
    int BB = perm1plus(B+1, Z);

    return mix(mix(mix(Grad(perm[AA  ], x, y   , z  ),  Grad(perm[BA  ], x-1., y   , z  ), u),
                   mix(Grad(perm[AB  ], x, y-1., z  ),  Grad(perm[BB  ], x-1., y-1., z  ), u),
                   v),
               mix(mix(Grad(perm[AA+1], x, y   , z-1.), Grad(perm[BA+1], x-1., y   , z-1.), u),
                   mix(Grad(perm[AB+1], x, y-1., z-1.), Grad(perm[BB+1], x-1., y-1., z-1.), u),
                   v),
               w);
}

// number of octaves of fbm
#define NUM_NOISE_OCTAVES 10

float hash(float p) { p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); }

float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);
    vec3 i = floor(x);
    vec3 f = fract(x);
    float n = dot(i, step);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

float fbm(vec3 x) {
	float v = 0.0;
	float a = 0.5;
	vec3 shift = vec3(100);
	for (int i = 0; i < NUM_NOISE_OCTAVES; ++i) {
		//v += a * noise(x);
        v += a * (Noise3D(x) * .5 + .5);
		x = x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
}

// Range (-1,1)
float sin10x(float x){
    float res = sin(30.f * x);
    return res;
}

void main()
{
    float PI = 3.1415926;

    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.
    
    vec4 deform = vs_Nor * (sin10x(fbm(vs_Pos.xyz) * float(sin(u_Time))) + 1.0 / 2.f) * 0.03f;  // Range(0, 0.03)    higher-frequency, lower-amplitude layer of fractal Brownian motion

    vec4 deformLF = vs_Nor * (sin(0.5f * fbm(vs_Pos.xyz) * float(sin(u_Time))) + 1.0 / 2.f) * 0.2f;   // Range(0, 0.09)    low-frequency, high-amplitude displacement, combination of sine

    fs_Displacement = deform + deformLF;    // Range (0, 0.09)

    vec4 deformedPos = vs_Pos + deform + deformLF;
    vec4 modelposition = u_Model * deformedPos;   // Temporarily store the transformed vertex positions for use below

    fs_Pos = modelposition;
    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
     
                                             // used to render the final positions of the geometry's vertices
}
