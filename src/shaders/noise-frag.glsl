#version 300 es

precision highp float;

uniform vec4 u_Color;
uniform float u_Warmth;
uniform float u_Alpha;
uniform vec2 u_Dimensions;
uniform sampler2D u_RenderedTexture;
uniform bool u_Bloom;

in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_Noise;
in float fs_Time;
in vec2 fs_UV;

out vec4 out_Col;

vec3 bloom(vec3 currCol) {
    vec3 bloomColor;
    float bright = dot(currCol, vec3(0.2126, 0.7152, 0.0722));
    if (bright > 0.4) {
        bloomColor = currCol;
    } else {
        bloomColor = vec3(0.0, 0.0, 0.0);
    }

    vec2 offset = 1.0 / u_Dimensions;

    float gauss[121] = float[121](0.006849,	0.007239,	0.007559,	0.007795,	0.007941,	0.00799,	0.007941,	0.007795,	0.007559,	0.007239,	0.006849,
                                  0.007239,	0.007653,	0.00799,	0.00824,	0.008394,	0.008446,	0.008394,	0.00824,	0.00799,	0.007653,	0.007239,
                                  0.007559,	0.00799,	0.008342,	0.008604,	0.008764,	0.008819,	0.008764,	0.008604,	0.008342,	0.00799,	0.007559,
                                  0.007795,	0.00824,	0.008604,	0.008873,	0.009039,	0.009095,	0.009039,	0.008873,	0.008604,	0.00824,	0.007795,
                                  0.007941,	0.008394,	0.008764,	0.009039,	0.009208,	0.009265,	0.009208,	0.009039,	0.008764,	0.008394,	0.007941,
                                  0.00799,	0.008446,	0.008819,	0.009095,	0.009265,	0.009322,	0.009265,	0.009095,	0.008819,	0.008446,	0.00799,
                                  0.007941,	0.008394,	0.008764,	0.009039,	0.009208,	0.009265,	0.009208,	0.009039,	0.008764,	0.008394,	0.007941,
                                  0.007795,	0.00824,	0.008604,	0.008873,	0.009039,	0.009095,	0.009039,	0.008873,	0.008604,	0.00824,	0.007795,
                                  0.007559,	0.00799,	0.008342,	0.008604,	0.008764,	0.008819,	0.008764,	0.008604,	0.008342,	0.00799,    0.007559,
                                  0.007239,	0.007653,	0.00799,	0.00824,	0.008394,	0.008446,	0.008394,	0.00824,	0.00799,	0.007653,	0.007239,
                                  0.006849,	0.007239,	0.007559,	0.007795,	0.007941,	0.00799,	0.007941,	0.007795,	0.007559,	0.007239,	0.006849);
    
    vec3 result = vec3(0.0, 0.0, 0.0);

    for (int i = 0; i < 11; i ++) {
        for (int j = 0; j < 11; j++) {
            result += texture(u_RenderedTexture, fs_UV + vec2(offset.x * float(i - 5), offset.y * float(j - 5))).rgb * gauss[60 + (11 * (j - 5)) + (i - 5)];
        }
    }

    return result + bloomColor;
}

float cubicPulse(float c, float w, float x) {
    x = abs(x - c);
    if (x > w) {
        return 0.0;
    }
    x /= w;
    return 1.0 - x * x * (3.0 - 2.0 * x);
}

#define White vec4(1.0, 1.0, 1.0, 1.0)
#define Yellow vec4(1.0, 0.8, 0.2, 1.0)
#define Red vec4(1.0, 0.03, 0.0, 1.0)
#define Black vec4(0.05, 0.02, 0.02, 1.0)
#define LightBlue vec4(0.5, 0.9, 1.0, 1.0)
#define DarkBlue vec4(0.0, 0.2, 0.7, 1.0)

vec4 colorize(float n) {
    vec4 color1 = mix(LightBlue, White, u_Warmth);
    vec4 color2 = mix(White, Yellow, u_Warmth);
    vec4 color3 = mix(DarkBlue, Red, u_Warmth);

    float c1 = clamp(n * 4.0 + 0.5, 0.0, 1.0);
    float c2 = clamp(n * 4.0, 0.0, 1.0);
    float c3 = clamp(n * 2.4 - 0.5, 0.0, 1.0);

    vec4 a = mix(color1, color2, c1);
    vec4 b = mix(a, color3, c2);
    return mix(b, Black, c3);
}

Add Background Shader

void main()
{
    vec3 fireColor = (colorize(fs_Noise)).xyz;
    vec4 backColor = colorizeBack();
    vec4 outputCol;
    float pulse = clamp((1.0, 0.2, mod(fs_Time * 0.01, 2.0)), 0.9, 1.5);
    if (u_Bloom) {
        vec3 bloomColor = bloom(fireColor.xyz);
        fireColor += bloomColor;
        vec3 blend = pow(fireColor, vec3(1.0 / 2.2));
        outputCol = vec4(blend * pulse, 1.0);
    } else {
        outputCol = vec4(fireColor * pulse, 1.0);
    }
    out_Col = mix(backColor, outputCol, u_Alpha);
}
