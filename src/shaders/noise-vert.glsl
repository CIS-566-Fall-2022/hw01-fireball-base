#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj; 

uniform int u_Time;
uniform float u_NoiseWeight;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

in vec2 vs_UV;

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col; 
out float fs_Noise;
out float fs_Time;
out vec2 fs_UV;

const vec4 lightPos = vec4(5, 5, 3, 1);

#define NoiseSteps 1
#define NoiseAmplitude 0.1
#define NoiseFrequency 4.0
#define Animation vec3(0.0, -3.0, 0.5)

float bias(float b, float t) {
    return (t / ((((1.0 / b) - 2.0)*(1.0 - t))+ 1.0));
}

float gain(float g, float t) {
    if (t < 0.5) {
        return bias(1.0 - g, 2.0 * t) / 2.0;
    } else {
        return 1.0 - bias(1.0 - g, 2.0 - 2.0 * t) / 2.0;
    }
}

float noise3D( vec3 p ) {
    return fract(sin((dot(p, vec3(127.1, 311.7, 191.999)))) * 43758.5453);
}

Add Simplex Noise

// Generic 3d noise
float interpNoise3D(vec3 p){
    int intX = int(floor(p.x));
    float fractX = fract(p.x);
    int intY = int(floor(p.y));
    float fractY = fract(p.y);
    int intZ = int(floor(p.z));
    float fractZ = fract(p.z);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
    float v5 = noise3D(vec3(intX, intY, intZ + 1));
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

// FBM noise
#define NUM_OCTAVES 8
float fbm(vec3 x) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < NUM_OCTAVES; ++i) {
		v += a * interpNoise3D(x);
		x = x * 2.0;
		a *= 0.5;
	}
	return v;
}


float turbulence(vec3 position, float minFreq, float maxFreq, float qWidth)
{
	float value = 0.0;
	float cutoff = clamp(0.5/qWidth, 0.0, maxFreq);
	float fade;
	float fOut = minFreq;
	for(int i=NoiseSteps ; i>=0 ; i--)
	{
		if(fOut >= 0.5 * cutoff) break;
		fOut *= 2.0;
		value += abs(snoise(position * fOut))/fOut;
	}
	fade = clamp(2.0 * (cutoff-fOut)/cutoff, 0.0, 1.0);
	value += fade * abs(snoise(position * fOut))/fOut;
	return 1.0-value;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    float pulse = gain(0.6, cos(float(u_Time) * 0.01));
    float init = clamp(sin(modelposition.x * 0.1 + modelposition.y * 0.1 + modelposition.z * 0.1 + (float(u_Time) * 0.01)), -0.5, 1.0) * 2.0;
    init = init * pulse;
    float displacement = turbulence(modelposition.xyz * NoiseFrequency + Animation * (float(u_Time) * 0.01), 0.1, 1.5, 0.03) * NoiseAmplitude;
    displacement = clamp(abs(displacement), 0.0, 1.0); //+ (fbm(fs_Nor.xyz));
    float fbmNoise = fbm(fs_Nor.xyz * 10.0 + Animation * (float(u_Time) * 0.01));
    displacement = mix(displacement, fbmNoise, u_NoiseWeight);

    fs_Noise = displacement;
    fs_Time = float(u_Time);
    fs_UV = vs_UV;

    vec4 newPos = modelposition + fs_Nor * init * displacement;
    gl_Position = u_ViewProj * newPos; // gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
