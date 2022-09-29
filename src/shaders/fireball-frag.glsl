#version 300 es

precision highp float;
const float PI = 3.14159265359;

uniform vec4 u_Color;
uniform int u_Bloom;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

in float fs_offset;

out vec4 out_Col;

const vec3 fireColors[6] = vec3[](vec3(99, 5, 0) / 255.0,         // MARRON
                            vec3(128, 6, 4) / 255.0,        // RED
                            vec3(245, 96, 55) / 255.0,     // DARK ORANGE
                            vec3(255, 151, 56) / 255.0,     // ORANGE
                            vec3(249, 222, 81) / 255.0,     // YELLOW
                            vec3(255, 255, 129) / 255.0);    // LIGHT YELLOW

vec3 getColor(float threshold)
{
  float bucket = 0.1;
    if(threshold < 0.4) {
        return fireColors[5];
    }
    else if(threshold < 0.5) {
        float t = (threshold - 0.4)/bucket;
        return mix(fireColors[5], fireColors[4], t);
    }
    else if(threshold < 0.6) {
        float t = (threshold - 0.5)/bucket;
        return mix(fireColors[4], fireColors[3], t);
    }
    else if(threshold < 0.7) {
        float t = (threshold - 0.6)/bucket;
        return mix(fireColors[3], fireColors[2], t);
    }
    else if(threshold < 0.8) {
        float t = (threshold - 0.7)/bucket;
        return mix(fireColors[2], fireColors[1], t);
    }
    else {
      float t = (threshold - 0.8)/bucket;
      return mix(fireColors[1], fireColors[0], t);
    }
}

const float u_GaussianKernel[121] = float[121](0.004411, 0.005278, 0.006068, 0.006704, 0.007117, 0.00726, 0.007117, 0.006704, 0.006068, 0.005278, 0.004411,0.005278, 0.006315, 0.00726, 0.008021, 0.008515, 0.008687, 0.008515, 0.008021, 0.00726, 0.006315, 0.005278,0.006068, 0.00726, 0.008347, 0.009222, 0.00979, 0.009988, 0.00979, 0.009222, 0.008347, 0.00726, 0.006068,0.006704, 0.008021, 0.009222, 0.010189, 0.010817, 0.011034, 0.010817, 0.010189, 0.009222, 0.008021, 0.006704,0.007117, 0.008515, 0.00979, 0.010817, 0.011483, 0.011714, 0.011483, 0.010817, 0.00979, 0.008515, 0.007117,0.00726, 0.008687, 0.009988, 0.011034, 0.011714, 0.01195, 0.011714, 0.011034, 0.009988, 0.008687, 0.00726,0.007117, 0.008515, 0.00979, 0.010817, 0.011483, 0.011714, 0.011483, 0.010817, 0.00979, 0.008515, 0.007117,0.006704, 0.008021, 0.009222, 0.010189, 0.010817, 0.011034, 0.010817, 0.010189, 0.009222, 0.008021, 0.006704,0.006068, 0.00726, 0.008347, 0.009222, 0.00979, 0.009988, 0.00979, 0.009222, 0.008347, 0.00726, 0.006068,0.005278, 0.006315, 0.00726, 0.008021, 0.008515, 0.008687, 0.008515, 0.008021, 0.00726, 0.006315, 0.005278,0.004411, 0.005278, 0.006068, 0.006704, 0.007117, 0.00726, 0.007117, 0.006704, 0.006068, 0.005278, 0.004411);

void main()
{
    
    vec3 newColor = getColor(fs_offset);

    vec3 L = vec3(0.2125, 0.7154, 0.0721);
    vec3 weightedAverage = vec3(0.f, 0.f, 0.f);
    if(u_Bloom == 1) {
      for(int i = 0; i < 11; i++)
      {
          for(int j = 0; j < 11; j++)
          {
              int index = i + (11 * j);
              float luminance = dot(newColor, L);

              if(luminance > 0.9)
              {
                  weightedAverage += newColor * u_GaussianKernel[index];
              }
          }
      }
    }

    // Compute final shaded color
    out_Col = vec4(newColor + weightedAverage, 1.0);
}
