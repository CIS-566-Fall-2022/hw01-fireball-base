import {mat4, vec3} from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import {gl} from '../../globals';
import ShaderProgram from './ShaderProgram';
import Planet from '../../geometry/Planet';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  private timeMs = 0;

  constructor(public canvas: HTMLCanvasElement) {}

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.colorMask(false, false, false, true);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.colorMask(true, true, true, true);
  }

  addTime(dtMs: number) {
    this.timeMs += dtMs;
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, modelMatrix: mat4 = mat4.identity(mat4.create())) {
    let viewProj = mat4.create();

    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(modelMatrix);
    prog.setViewMatrix(camera.viewMatrix);
    prog.setProjMatrix(camera.projectionMatrix);
    prog.setViewProjMatrix(viewProj);
    prog.setCameraPos(camera.controls.eye);
    prog.setTime(this.timeMs);

    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }

  renderPlanet(camera: Camera, planet: Planet) {
    let modelMatrix = mat4.fromTranslation(mat4.create(), planet.position);
    mat4.multiply(modelMatrix, modelMatrix, mat4.fromRotation(mat4.create(), planet.axisRotation, vec3.fromValues(0, 1, 0)));
    this.render(camera, planet.shaderProgram, [planet], modelMatrix);
    for (let accessory of planet.accessories) {
      this.render(camera, accessory.getShaderProgram(), [accessory.getDrawable()], modelMatrix);
    }
  }
};

export default OpenGLRenderer;
