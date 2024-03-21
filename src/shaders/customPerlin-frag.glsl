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
// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

int perm[256] = int[256](151,160,137,91,90,15, 
131,13,201,95,96,53,194,233,7,225,140,36,
103,30,69,142,8,99,37,240,21,10,23, 190, 
6,148,247,120,234,75,0,26,197,62,94,252,219,
203,117,35,11,32,57,177,33, 88,237,149,56,87,
174,20,125,136,171,168, 68,175,74,165,71,134,
139,48,27,166, 77,146,158,231,83,111,229,122,
60,211,133,230,220,105,92,41,55,46,245,40,244, 
102,143,54, 65,25,63,161, 1,216,80,73,209,76,
132,187,208, 89,18,169,200,196, 135,130,116,
188,159,86,164,100,109,198,173,186, 3,64,52,
217,226,250,124,123, 5,202,38,147,118,126,
255,82,85,212,207,206,59,227,47,16,58,17,182,
189,28,42, 223,183,170,213,119,248,152, 2,44,
154,163, 70,221,153,101,155,167, 43,172,9, 
129,22,39,253, 19,98,108,110,79,113,224,232,
178,185, 112,104,218,246,97,228, 251,34,242,
193,238,210,144,12,191,179,162,241, 81,51,145,
235,249,14,239,107, 49,192,214, 31,181,199,
106,157,184, 84,204,176,115,121,50,45,127, 
4,150,254, 138,236,205,93,222,114,67,29,24,
72,243,141,128,195,78,66,215,61,156,180);

float fade(float t) {
  //Fade function, referenced from https://adrianb.io/2014/08/09/perlinnoise.html
    return t * t * t * (t * (t * 6.f - 15.f) + 10.f);         // 6t^5 - 15t^4 + 10t^3
}

// Source: http://riven8192.blogspot.com/2010/08/calculate-perlinnoise-twice-as-fast.html
float grad(int hash, float x, float y, float z) {
  if ((hash & 0xF) == 0x0) {
    return  x + y;
  } else if ((hash & 0xF) == 0x1) {
    return -x + y;
  } else if ((hash & 0xF) == 0x2) {
    return  x - y;
  } else if ((hash & 0xF) == 0x3) {
    return -x - y;
  } else if ((hash & 0xF) == 0x4) {
    return  x + z;
  } else if ((hash & 0xF) == 0x5) {
    return -x + z;
  } else if ((hash & 0xF) == 0x6) {
    return  x - z;
  } else if ((hash & 0xF) == 0x7) {
    return -x - z;
  } else if ((hash & 0xF) == 0x8) {
    return  y + z;
  } else if ((hash & 0xF) == 0x9) {
    return -y + z;
  } else if ((hash & 0xF) == 0xA) {
    return  y - z;
  } else if ((hash & 0xF) == 0xB) {
    return -y - z;
  } else if ((hash & 0xF) == 0xC) {
    return  y + x;
  } else if ((hash & 0xF) == 0xD) {
    return -y + z;
  } else if ((hash & 0xF) == 0xE) {
    return  y - x;
  } else if ((hash & 0xF) == 0xF) {
    return -y - z;
  } else {
    return 0.f;
  }
}

int repeat = 200;

int inc(int num) {
    num++;
    if (repeat > 0) num %= repeat;
    return num;
}

float perlinNoise(vec3 i) {
  //Dont mix up i and j!
  //0. Set up repeat
    float x = i.x;
    float y = i.y;
    float z = i.z;

  if (repeat > 0) {
    int repeatX_i = int(x) % repeat;                              
    int repeatY_i = int(y) % repeat;                              
    int repeatZ_i = int(z) % repeat;

    x = float(repeatX_i) + fract(x);
    y = float(repeatY_i) + fract(y);
    z = float(repeatZ_i) + fract(z);
  }


  //1. populate look up table
  int p[512];
  for(int j=0; j<512; j++) {
    p[j] = perm[j % 256]; //I fill up twice of the look-up-table of random numbers to prevent overflow issues
  }

  // 2. Find unit grid cell containing point (that is, the integer floats of each coord) (X, Y, Z)
  int X = int(x) % 256;                              
  int Y = int(y) % 256;                              
  int Z = int(z) % 256;

  // 3. Get relative local xyz coordinates of point within that cell (x_r, y_r, z_r)
  float x_r = x - float(X); 
  float y_r = y - float(Y); 
  float z_r = z - float(Z);

  // 4. Finally, let's also use our quintic fade function to smooth out the location
  float u = fade(x_r);
  float v = fade(y_r);
  float w = fade(z_r);

  // 5. From what I understand, we're going to follow similar logic from lecture and 
  //   use a hash function to map all 8 3D coordinates that surround the input coord, 
  //   to 4-coord location vectors.

  int aaa, aba, aab, abb, baa, bba, bab, bbb;
  aaa = p[p[p[X]+Y]+Z];
  aba = p[p[p[X]+inc(Y)]+Z];
  aab = p[p[p[X]+Y]+inc(Z)];
  abb = p[p[p[X]+inc(Y)]+inc(Z)];
  baa = p[p[p[inc(X)]+Y]+Z];
  bba = p[p[p[inc(X)]+inc(Y)]+Z];
  bab = p[p[p[inc(X)]+Y]+inc(Z)];
  bbb = p[p[p[inc(X)]+inc(Y)]+inc(Z)];

  // 6. Gradient time! Let's use grad to calculate all of the dot products between the location vectors
  //and the pseudo random gradient vectors, and then interpolate between all of these to find a weighted
  //average based on the faded values (u, v, w) from earlier.

  float x1, x2, y1, y2;
  x1 = mix(grad(aaa, x_r, y_r, z_r), grad(baa, x_r-1.f, y_r, z_r), u);                                   
  x2 = mix(grad(aba, x_r, y_r-1.f, z_r),grad (bba, x_r-1.f, y_r-1.f, z_r),             
           u);
  y1 = mix(x1, x2, v);

  x1 = mix(grad(aab, x_r, y_r, z_r-1.f),
           grad(bab, x_r-1.f, y_r, z_r-1.f),
           u);
  x2 = mix(grad(abb, x_r, y_r-1.f, z_r-1.f),
                grad(bbb, x_r-1.f, y_r-1.f, z_r-1.f),
                u);
  y2 = mix(x1, x2, v);
  
  return (mix(y1, y2, w)+1.f)/2.f;
}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    diffuseTerm = clamp(diffuseTerm, 0.f, 1.f);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.
    float pNoise = perlinNoise(6.f * (vec3(fs_LightVec)) + 0.1 * vec3(u_Time));
    out_Col = vec4(lightIntensity * vec3(mix(vec4(diffuseColor), vec4(vec3(1.f) - vec3(diffuseColor), 1.f), pNoise)), 1.f);
}
