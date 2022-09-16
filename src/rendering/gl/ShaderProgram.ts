import {vec3, mat4} from 'gl-matrix';
import Drawable from './Drawable';
import {gl} from '../../globals';

var activeProgram: WebGLProgram = null;

const noiseShaderCode = `
float random1(float p) {
  return fract(sin(p * 592.4) * 102934.239);
}

vec3 random3(vec3 p) {
  return fract(sin(vec3(dot(p, vec3(185.3, 563.9, 887.2)),
                        dot(p, vec3(593.1, 591.2, 402.1)),
                        dot(p, vec3(938.2, 723.4, 768.9))
                  )) * 58293.492);
}

vec4 random4(vec4 p) {
  return fract(sin(vec4(dot(p, vec4(127.1, 311.7, 921.5, 465.8)),
                        dot(p, vec4(269.5, 183.3, 752.4, 429.1)),
                        dot(p, vec4(420.6, 631.2, 294.3, 910.8)),
                        dot(p, vec4(213.7, 808.1, 126.8, 572.0))
                  )) * 43758.5453);
}

float surflet(vec4 p, vec4 gridPoint) {
  vec4 t2 = abs(p - gridPoint);
  vec4 t = vec4(1.f) - 6.f * pow(t2, vec4(5.f)) + 15.f * pow(t2, vec4(4.f)) - 10.f * pow(t2, vec4(3.f));
  vec4 gradient = random4(gridPoint) * 2. - vec4(1.);
  vec4 diff = p - gridPoint;
  float height = dot(diff, gradient);
  return height * t.x * t.y * t.z * t.w;
}

float perlin(vec4 p) {
	float surfletSum = 0.f;

	for (int dx = 0; dx <= 1; ++dx) {
		for (int dy = 0; dy <= 1; ++dy) {
			for (int dz = 0; dz <= 1; ++dz) {
        for (int dw = 0; dw <= 1; ++dw) {
          surfletSum += surflet(p, floor(p) + vec4(dx, dy, dz, dw));
        }
			}
		}
	}

	return surfletSum;
}

#define OCTAVES 4
float fbm(vec4 p) {
  float value = 0.0;
  float amplitude = 0.5;
  for (int i = 0; i < OCTAVES; ++i) {
    value += amplitude * ((perlin(p) + 1.0) / 2.0);
    p *= 2.0;
    amplitude *= 0.5;
  }
  return value;
}

struct WorleyInfo {
  float dist;
  vec3 color;
};

WorleyInfo worley(vec4 uv) {
  vec4 uvInt = floor(uv);
  vec4 uvFract = uv - uvInt;
  float minDist = 1.0f;

  vec3 color;
  for (int x = -1; x <= 1; ++x) {
    for (int y = -1; y <= 1; ++y) {
      for (int z = -1; z <= 1; ++z) {
        for (int w = -1; w <= 1; ++w) {
          vec4 neighbor = vec4(float(x), float(y), float(z), float(w));
          vec4 point = random4(uvInt + neighbor);
          vec4 diff = neighbor + point - uvFract;
          float dist = length(diff);
          if (dist < minDist) {
            minDist = dist;
            color = random4(point).rgb;
          }
        }
      }
    }
  }

  WorleyInfo worleyInfo;
  worleyInfo.dist = minDist;
  worleyInfo.color = color;
  return worleyInfo;
}
`

const lambertShaderCode = `
#ifdef NO_LAMBERT
  out_Col = diffuseColor;
#else
  float diffuseTerm = dot(normalize(fs_Nor), normalize(-fs_Pos)) + 0.2;
  diffuseTerm = clamp(diffuseTerm, 0.0, 1.0) * 2.0;
  float ambientTerm = 0.05;
  float lightIntensity = diffuseTerm + ambientTerm;
  out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
#endif
`

export class Shader {
  shader: WebGLShader;

  constructor(type: number, source: string) {
    source = source.replace('NOISE GOES HERE', noiseShaderCode);
    source = source.replace('LAMBERT GOES HERE', lambertShaderCode);

    this.shader = gl.createShader(type);
    gl.shaderSource(this.shader, source);
    gl.compileShader(this.shader);

    if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(this.shader);
    }
  }
};

class ShaderProgram {
  prog: WebGLProgram;

  attrPos: number;
  attrNor: number;
  attrUvs: number;

  unifModel: WebGLUniformLocation;
  unifModelInvTr: WebGLUniformLocation;
  unifViewMat: WebGLUniformLocation;
  unifProjMat: WebGLUniformLocation;
  unifViewProj: WebGLUniformLocation;
  unifCameraPos: WebGLUniformLocation;
  unifTime: WebGLUniformLocation;

  unifDisplacementHeight: WebGLUniformLocation;
  unifTimeScale: WebGLUniformLocation;
  unifTemperature: WebGLUniformLocation;

  constructor(shaders: Array<Shader>) {
    this.prog = gl.createProgram();

    for (let shader of shaders) {
      gl.attachShader(this.prog, shader.shader);
    }
    gl.linkProgram(this.prog);
    if (!gl.getProgramParameter(this.prog, gl.LINK_STATUS)) {
      throw gl.getProgramInfoLog(this.prog);
    }

    this.attrPos = gl.getAttribLocation(this.prog, "vs_Pos");
    this.attrNor = gl.getAttribLocation(this.prog, "vs_Nor");
    this.attrUvs = gl.getAttribLocation(this.prog, "vs_UV");

    this.unifModel      = gl.getUniformLocation(this.prog, "u_Model");
    this.unifModelInvTr = gl.getUniformLocation(this.prog, "u_ModelInvTr");
    this.unifViewMat    = gl.getUniformLocation(this.prog, "u_ViewMat");
    this.unifProjMat    = gl.getUniformLocation(this.prog, "u_ProjMat");
    this.unifViewProj   = gl.getUniformLocation(this.prog, "u_ViewProj");
    this.unifCameraPos  = gl.getUniformLocation(this.prog, "u_CameraPos");
    this.unifTime       = gl.getUniformLocation(this.prog, "u_Time");

    this.unifDisplacementHeight = gl.getUniformLocation(this.prog, "u_DisplacementHeight");
    this.unifTimeScale = gl.getUniformLocation(this.prog, "u_TimeScale");
    this.unifTemperature = gl.getUniformLocation(this.prog, "u_Temperature");
  }

  use() {
    if (activeProgram !== this.prog) {
      gl.useProgram(this.prog);
      activeProgram = this.prog;
    }
  }

  setModelMatrix(model: mat4) {
    this.use();
    if (this.unifModel !== -1) {
      gl.uniformMatrix4fv(this.unifModel, false, model);
    }

    if (this.unifModelInvTr !== -1) {
      let modelinvtr: mat4 = mat4.create();
      mat4.transpose(modelinvtr, model);
      mat4.invert(modelinvtr, modelinvtr);
      gl.uniformMatrix4fv(this.unifModelInvTr, false, modelinvtr);
    }
  }

  setViewMatrix(viewMat: mat4) {
    this.use();
    if (this.unifViewMat !== -1) {
      gl.uniformMatrix4fv(this.unifViewMat, false, viewMat);
    }
  }

  setProjMatrix(projMat: mat4) {
    this.use();
    if (this.unifProjMat !== -1) {
      gl.uniformMatrix4fv(this.unifProjMat, false, projMat);
    }
  }

  setViewProjMatrix(vp: mat4) {
    this.use();
    if (this.unifViewProj !== -1) {
      gl.uniformMatrix4fv(this.unifViewProj, false, vp);
    }
  }

  setCameraPos(cameraPos: vec3) {
    this.use();
    if (this.unifCameraPos !== -1) {
      gl.uniform3fv(this.unifCameraPos, cameraPos);
    }
  }

  setTime(time: number) {
    this.use();
    if (this.unifTime !== -1) {
      gl.uniform1f(this.unifTime, time);
    }
  }

  setDisplacementHeight(displacementHeight: number) {
    this.use();
    if (this.unifDisplacementHeight !== -1) {
      gl.uniform1f(this.unifDisplacementHeight, displacementHeight);
    }
  }

  setTimeScale(timeScale: number) {
    this.use();
    if (this.unifTimeScale !== -1) {
      gl.uniform1f(this.unifTimeScale, timeScale);
    }
  }

  setTemperature(temperature: number) {
    this.use();
    if (this.unifTemperature !== -1) {
      gl.uniform1f(this.unifTemperature, temperature);
    }
  }

  draw(d: Drawable) {
    this.use();

    if (this.attrPos != -1 && d.bindPos()) {
      gl.enableVertexAttribArray(this.attrPos);
      gl.vertexAttribPointer(this.attrPos, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrNor != -1 && d.bindNor()) {
      gl.enableVertexAttribArray(this.attrNor);
      gl.vertexAttribPointer(this.attrNor, 4, gl.FLOAT, false, 0, 0);
    }

    if (this.attrUvs != -1 && d.bindUvs()) {
      gl.enableVertexAttribArray(this.attrUvs);
      gl.vertexAttribPointer(this.attrUvs, 2, gl.FLOAT, false, 0, 0);
    }

    d.bindIdx();
    gl.drawElements(d.drawMode(), d.elemCount(), gl.UNSIGNED_INT, 0);

    if (this.attrPos != -1) gl.disableVertexAttribArray(this.attrPos);
    if (this.attrNor != -1) gl.disableVertexAttribArray(this.attrNor);
    if (this.attrUvs != -1) gl.disableVertexAttribArray(this.attrUvs);
  }
};

export default ShaderProgram;
