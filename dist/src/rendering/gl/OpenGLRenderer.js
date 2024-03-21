import { mat4, vec4 } from 'gl-matrix';
import { gl } from '../../globals';
// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
    constructor(canvas) {
        this.canvas = canvas;
    }
    setClearColor(r, g, b, a) {
        gl.clearColor(r, g, b, a);
    }
    setSize(width, height) {
        this.canvas.width = width;
        this.canvas.height = height;
    }
    clear() {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }
    render(camera, prog, drawables, t, r, h, transformations) {
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
        let h_i = 1.0;
        if (!h) {
            h_i = -1.0;
        }
        prog.setHappy(h_i);
        for (let drawable of drawables) {
            prog.setModelMatrix(transformations[0]);
            prog.draw(drawable);
        }
    }
}
;
export default OpenGLRenderer;
//# sourceMappingURL=OpenGLRenderer.js.map