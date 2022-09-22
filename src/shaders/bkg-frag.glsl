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
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float GetBias(float time, float bias)
{
  return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0));
}

float GetGain(float time, float gain)
{
  if(time < 0.5) {
    return GetBias(time * 2.0,gain)/2.0;
  }
  else {
    return GetBias(time * 2.0 - 1.0,1.0 - gain)/2.0 + 0.5;
  }
}

void main()
{
    // Material base color (before shading)
    vec3 center = vec3(0,0,-10);
    vec3 tmpPos = fs_Pos.xyz;
    float scale = 6.0;
    float freq = 0.01;
    tmpPos += GetGain(abs(sin(freq * u_Time)), 0.3) * scale * normalize(fs_Nor.xyz);

    float dis = length(vec3(tmpPos - center));
  
    vec4 diffuseColor = vec4(max(0.0, u_Color.x - dis * 0.1), max(0.0, u_Color.y - dis * 0.1), max(0.0, u_Color.z - dis * 0.1), 1.0);

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}