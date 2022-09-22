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

uniform vec4 u_NoiseColor; // The color with which to render this instance of geometry.
uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


// refer to code from https://www.shadertoy.com/view/ttsBWl by evgenys 
// and https://www.shadertoy.com/view/4dS3Wd by Morgan McGuire
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
void main()
{

        // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        
        // Compute shaded color from lights

        vec4 lightColor = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);

        // vec4 color = mix(lightColor.rgb, u_Color.rgb, fbm(fs_Pos.xyz));
        vec3 color = u_NoiseColor.xyz;
        


        // vec3 color = vec3(1, 0.5, 0.3);
        float scale = 1.0f;
        vec3 noiseDrive = (fs_Pos.xyz + u_Time.xyz) * scale;
        color = mix(color, u_Color.rgb, fbm(noiseDrive));
        
        out_Col = vec4(color.rgb, 1);
}