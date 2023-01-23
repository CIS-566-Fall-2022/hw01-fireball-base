#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;
uniform vec4 u_Color;
uniform float u_BluePersistence;
uniform float u_RedPersistence;

in vec4 fs_Col;
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
out vec4 out_Col;

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float random3D( vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + p.z * 50.0;

    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
}

float surflet(vec2 P, vec2 gridPoint) {
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float tX = 1.f - 6.f * pow(distX, 5.f) + 15.f * pow(distX, 4.f) - 10.f * pow(distX, 3.f);
    float tY = 1.f - 6.f * pow(distY, 5.f) + 15.f * pow(distY, 4.f) - 10.f * pow(distY, 3.f);
    // Get the random vector for the grid point
    vec2 gradient = 2.f * random3D(vec3(gridPoint.xy, 1.0)) - vec2(1.f);
    // Get the vector from the grid point to P
    vec2 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY;
}

float perlinNoise(vec2 uv) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			surfletSum += surflet(uv, floor(uv) + vec2(dx, dy));
		}
	}
	return surfletSum;
}


float interpNoise3D(vec3 p) {
    int intX = int(floor(p.x));
    float fractX = fract(p.x);
    int intY = int(floor(p.y));
    float fractY = fract(p.y);
    int intZ = int(floor(p.z));
    float fractZ = fract(p.z);

    float v1 = random3D(vec3(intX, intY, intZ));
    float v2 = random3D(vec3(intX, intY, intZ + 1));
    float v3 = random3D(vec3(intX, intY + 1, intZ));
    float v4 = random3D(vec3(intX, intY + 1, intZ + 1));

    float v5 = random3D(vec3(intX + 1, intY, intZ));
    float v6 = random3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = random3D(vec3(intX + 1, intY + 1, intZ));
    float v8 = random3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractZ);
    float i2 = mix(v3, v4, fractZ);
    float i3 = mix(i1, i2, fractY);
    
    float i4 = mix(v5, v6, fractZ);
    float i5 = mix(v7, v8, fractZ);
    float i6 = mix(i4, i5, fractY);

    return mix(i3, i6, fractX);
}

float fbm(vec3 p, float freq, float persistence) {
    float total = 0.f;
    //float persistence = 0.5f;
    int octaves = 8;
    //float freq = 2.f;
    float amp = 0.5f;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(p.xyz * freq) * amp;
        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

void main() {
    vec4 baseCol = vec4(1.0, 1.0, 0.0, 1.0);
    float theta = atan(fs_Pos.x, fs_Pos.y);
    float r = sqrt(pow(fs_Pos.x, 2.0f) + pow(fs_Pos.y, 2.0f));
    vec4 brown = vec4(0.36, 0.29, 0.01, 1.0) * fbm(vec3(fs_Pos.xyz), 2.f, 0.5f);
    vec4 green = vec4(0.24, abs(sin(0.4 * r * 20.f)), cos(0.22 * r * 90.f), 1.0);    
    vec4 blue = vec4(0.0, 0.0, 1.0, 1.0);

    vec4 eye_color = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 pupil_color = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 iris_color = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 eyeball_color = vec4(0.0, 0.0, 0.0, 1.0);
    
    /*
     * Pupil Color
     */
    // mixes black with r(which depends on x and y) and gives more weight to r
    // So when both x and y tend to 0, mixed result shows black 
    float smoothVal = smoothstep(0.9, 0.99f, fs_Pos.z);
    //pupil_color = mix(vec4(0.0, 0.0, 0.0, 1.0), smoothVal * vec4(r, r, r, 1.0), 0.98);    // if we multiply smoothvalue here, influence of white disappears when x and y is max
    pupil_color = mix(vec4(0.0, 0.0, 0.0, 1.0), vec4(r, r, r, 1.0), 0.98);
    
    /*
     * Iris Color
     */
    // blue with low persistence noise function
    float f_blue = fbm(vec3(fs_Pos.xyz), 20.f, u_BluePersistence);//0.7f);
    blue *= f_blue;

    // increasing blue influence with radius and adjusting green ring position with appropriate multiple
    float f_green = fbm(vec3(fs_Pos.xyz), 20.f, 0.5f);
    green *= f_green;

    // multiplying with cos(theta) makes cos wave look like rays around the circle
    // use sin function based on z to set a varying phase difference
    float f_brown = fbm(vec3(fs_Pos.xyz), 2.f, 0.5f);
    brown = vec4(0.36, 0.29, 0.01, 1.0) * f_brown;
    brown *= abs(cos(theta * 20.f - sin(fs_Pos.z * interpNoise3D(fs_Pos.xyz) * 200.f) * 3.14f/8.f));

    // In smoothstep function below, fs_Pos.z value changes from 0.98 to 0.99, value gradually decreases
    // Subtracting it from 1.0 inverses the effect, so as fs_Pos.z moves towards 0.99, the value increases
    smoothVal = smoothstep(0.98, 0.99f, fs_Pos.z);

    iris_color = mix(mix(green, blue, 0.5f), brown, f_brown);
    iris_color *= (1.f - smoothVal);
    
    /*
     * Outer white eyeball color
     */
    float f_red = fbm(vec3(fs_Pos.xyz), 1.f, u_RedPersistence);
    //float f_red = mix(interpNoise3D(vec3(fs_Pos.xyz)), sin(perlinNoise(vec2(fs_Pos.xy)) * 10.f), 0.1);
    //float f_red = interpNoise3D(vec3(fs_Pos.xyz));
    eyeball_color = vec4(1.0, 0.0, 0.0f, 1.0) * f_red * (0.4 * (-fs_Pos.z + 1.5f));

    //eye_color = eyeball_color + iris_color + pupil_color;

    if(fs_Pos.z > 0.998) {
        eye_color = pupil_color;
    }
    else if (fs_Pos.z > 0.9 &&  fs_Pos.z < 0.998) {
        eye_color = pupil_color + iris_color;
    }
    else if (fs_Pos.z > 0.84 &&  fs_Pos.z < 0.9) {
        eye_color = mix(iris_color, eyeball_color, (1.f - fs_Pos.z) * 0.5f);
    }
    // behind the eyeball to get red waves/veins
    else if (fs_Pos.z < 0.0) {
        eye_color = mix(iris_color, eyeball_color, (1.f - fs_Pos.z));
    }
    else {
        eye_color = mix(iris_color, eyeball_color, 0.99f);
    }
    out_Col = eye_color;

    // // Material base color (before shading)
    // //vec4 diffuseColor = texture(u_Texture, fs_UV);

    // // Calculate the diffuse term for Lambert shading
    // vec4 N = vec4(normalize(fs_Pos.xyz), 0.0);
    // float diffuseTerm = dot(N, normalize(fs_LightVec));
    // // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

    // float ambientTerm = 0.2f;
    // float specularTerm;

    // vec4 V, L, H;
    // float shininess = 50.;
    // L = normalize(fs_LightVec);
    // V = normalize(vec4(u_Eye.xyz - fs_Pos.xyz, 0.0));
    // H = V;//(V + L) / 2.0;
    // specularTerm = dot(normalize(H), normalize(N));// * diffuseTerm;

    // float lightIntensity = diffuseTerm + specularTerm + ambientTerm;   //Add a small float value to the color multiplier
    //                                                     //to simulate ambient lighting. This ensures that faces that are not
    //                                                     //lit by our point light are not completely black.

    // // Compute final shaded color

    // out_Col = vec4(specularTerm, specularTerm, specularTerm, 1.0);
}
