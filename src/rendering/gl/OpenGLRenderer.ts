import {mat4, vec4} from 'gl-matrix';
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

  render(camera: Camera, prog: Array<ShaderProgram>, drawables: Array<Drawable>, time: number, col: number[], blue_persistence: number, red_persistence: number) {
    //prog.setEyeRefUp(camera.controls.eye, camera.controls.center, camera.controls.up);
    prog[0].setTime(time);
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = vec4.fromValues(1, 0, 0, 1);
    let offset = vec4.fromValues(-1, 0, 0, 1);

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog[0].setEyeRefUp(camera.position, camera.direction, camera.up);
    prog[0].setModelMatrix(model);
    prog[0].setViewProjMatrix(viewProj);
    prog[0].setGeometryColor(color);
    //prog[0].setOffsetFromCenter(offset);
    prog[0].setBluePersistence(blue_persistence);
    prog[0].setRedness(red_persistence);
    prog[0].draw(drawables[0]);
    // for (let drawable of drawables) {
    //   prog[0].draw(drawable);
    // }

    prog[1].setTime(time);
    color = vec4.fromValues(0, 0, 0, 1);
    mat4.identity(model);
    mat4.identity(viewProj);
    prog[1].setEyeRefUp(camera.position, camera.direction, camera.up);
    prog[1].setModelMatrix(model);
    prog[1].setViewProjMatrix(viewProj);
    
    color = vec4.fromValues(col[0]/255, col[1]/255, col[2]/255, col[3]);
    prog[1].setGeometryColor(color);
    //prog[1].setOffsetFromCenter(offset);
    prog[1].draw(drawables[1]);

  }
};

export default OpenGLRenderer;
