import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

    constructor(center: vec3) {
      super();
      this.center = vec4.fromValues(center[0], center[1], center[2], 1);
    }

    create() {
      this.indices = new Uint32Array([0, 1, 2,  // front
                                      0, 2, 3,

                                      1, 5, 6,  // right
                                      1, 6, 2,
                                      
                                      5, 4, 7,  // back
                                      5, 7, 6,
                                      
                                      4, 0, 3,  // left
                                      4, 3, 7,
                                      
                                      3, 2, 6,  // top
                                      3, 6, 7,
                                      
                                      5, 4, 0,  // bottom
                                      5, 0, 1]);

      this.normals = new Float32Array([0, 0, 1, 0,  // front
                                      0, 0, 1, 0,
                                      0, 0, 1, 0,
                                      0, 0, 1, 0,

                                      1, 0, 0, 0,  // right
                                      1, 0, 0, 0,
                                      1, 0, 0, 0,
                                      1, 0, 0, 0,

                                      0, 0, -1, 0,  // back
                                      0, 0, -1, 0,
                                      0, 0, -1, 0,
                                      0, 0, -1, 0,

                                      -1, 0, 0, 0,  // left
                                      -1, 0, 0, 0,
                                      -1, 0, 0, 0,
                                      -1, 0, 0, 0,

                                      0, 1, 0, 0,  // top
                                      0, 1, 0, 0,
                                      0, 1, 0, 0,
                                      0, 1, 0, 0,

                                      0, -1, 0, 0,  // bottom
                                      0, -1, 0, 0,
                                      0, -1, 0, 0,
                                      0, -1, 0, 0]);

      this.positions = new Float32Array([this.center[0] + -1, this.center[1] + -1, this.center[2] + 1, 1, // 0 // front
                                        this.center[0] + 1, this.center[1] + -1, this.center[2] + 1, 1,   // 1
                                        this.center[0] + 1, this.center[1] + 1, this.center[2] + 1, 1,    // 2
                                        this.center[0] + -1, this.center[1] + 1, this.center[2] + 1, 1,   // 3

                                        this.center[0] + -1, this.center[1] + -1, this.center[2] + -1, 1,  // 4
                                        this.center[0] + 1, this.center[1] + -1, this.center[2] + -1, 1,   // 5  //back
                                        this.center[0] + 1, this.center[1] + 1, this.center[2] + -1, 1,    // 6
                                        this.center[0] + -1, this.center[1] + 1, this.center[2] + -1, 1,   // 7

                                        this.center[0] + 1, this.center[1] + -1, this.center[2] + 1, 1,   // 1  // right
                                        this.center[0] + 1, this.center[1] + -1, this.center[2] + -1, 1,  // 5
                                        this.center[0] + 1, this.center[1] + 1, this.center[2] + -1, 1,   // 6
                                        this.center[0] + 1, this.center[1] + 1, this.center[2] + 1, 1,    // 2

                                        this.center[0] + -1, this.center[1] + -1, this.center[2] + -1, 1,  // 4  // left
                                        this.center[0] + -1, this.center[1] + -1, this.center[2] + 1, 1,   // 0
                                        this.center[0] + -1, this.center[1] + 1, this.center[2] + 1, 1,    // 3
                                        this.center[0] + -1, this.center[1] + 1, this.center[2] + -1, 1,   // 7

                                        this.center[0] + -1, this.center[1] + 1, this.center[2] + 1, 1,    // 3  // top
                                        this.center[0] + 1, this.center[1] + 1, this.center[2] + 1, 1,     // 2
                                        this.center[0] + 1, this.center[1] + 1, this.center[2] + -1, 1,    // 6
                                        this.center[0] + -1, this.center[1] + 1, this.center[2] + -1, 1,   // 7

                                        this.center[0] + 1, this.center[1] + -1, this.center[2] + -1, 1,   // 5  // bottom
                                        this.center[0] + -1, this.center[1] + -1, this.center[2] + -1, 1,  // 4
                                        this.center[0] + -1, this.center[1] + -1, this.center[2] + 1, 1,   // 0
                                        this.center[0] + 1, this.center[1] + -1, this.center[2] + 1, 1]); // 1

      this.generateIdx();
      this.generatePos();
      this.generateNor();
  
      this.count = this.indices.length;
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);
  
      gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
      gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);
  
      gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
      gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);
  
      console.log(`Created cube`);
    }
};

export default Cube;