import {mat4, vec4, vec3} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, t: number, r: number, h: boolean,
    transformations: Array<mat4>) {
    let model = mat4.create();
    let viewProj = mat4.create();
    // let color = vec4.fromValues(rgb[0], rgb[1], rgb[2], 1);

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    // prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    // prog.setGeometryColor(color);
    //CamPos
    prog.setCamPos(vec4.fromValues(camera.controls.eye[0], camera.controls.eye[1], camera.controls.eye[2], 1.0));
    //Time
    prog.setTime(t);
    //Roughness
    prog.setRoughness(r);
    let h_i: number = 1.0;
    if (!h) {
      h_i = -1.0;
    }
    prog.setHappy(h_i);
    for (let drawable of drawables) {
      prog.setModelMatrix(transformations[0]);
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
