#version 300 es

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj; 

uniform int u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col; 

const vec4 lightPos = vec4(5, 5, 3, 1);

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

    // deform model
    vec4 deform = modelposition;
    deform[0] = sin(modelposition[1] + float(u_Time) / 189.0);
    //deform[0] = clamp(deform[0], -0.5, 0.5) * 1.5;


    deform[1] = sin(modelposition[2] + float(u_Time) / 114.0); 
    //deform[1] = clamp(deform[1], -0.5, 0.5) * 1.5;

    deform[2] = sin(modelposition[0] + float(u_Time) / 164.0);
    //deform[2] = clamp(deform[2], -0.5, 0.5) * 1.5;

    deform[0] += sin(modelposition[2] + float(u_Time) / 127.0);
    deform[0] = clamp(deform[0], -0.5, 0.5) * 1.5;


    deform[1] += sin(modelposition[0] + float(u_Time) / 145.0); 
    deform[1] = clamp(deform[1], -0.5, 0.5) * 1.5;

    deform[2] += sin(modelposition[1] + float(u_Time) / 245.0);
    deform[2] = clamp(deform[2], -0.5, 0.5) * 1.5;

    gl_Position = u_ViewProj * deform;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}


