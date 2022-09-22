import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Cube extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;

  constructor(center: vec3) {
    super(); // Call the constructor of the super class. This is required.
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
  }

  create() {

  this.indices = new Uint32Array([0, 1, 2, 0, 2, 3, // front
                                    4, 5, 7, 4, 6, 7, // left side
                                    8, 9, 11, 8, 10, 11, // bottom side
                                    12, 13, 15, 12, 14, 15, // right side
                                    16, 17, 19, 16, 18, 19, // top side
                                    20, 21, 22, 20, 22, 23]); // back side
                                
  this.normals = new Float32Array([0, 0, 1, 0, // front
                                   0, 0, 1, 0,
                                   0, 0, 1, 0,
                                   0, 0, 1, 0,
                                   0, -1, 0, 0, // bottom
                                   0, -1, 0, 0,
                                   0, -1, 0, 0,
                                   0, -1, 0, 0,
                                   1, 0, 0, 0, // right
                                   1, 0, 0, 0,
                                   1, 0, 0, 0,
                                   1, 0, 0, 0,
                                   0, 1, 0, 0, // top
                                   0, 1, 0, 0,
                                   0, 1, 0, 0,
                                   0, 1, 0, 0,
                                   -1, 0, 0, 0, // left
                                   -1, 0, 0, 0,
                                   -1, 0, 0, 0,
                                   -1, 0, 0, 0,
                                   0, 0, -1, 0, // back
                                   0, 0, -1, 0,
                                   0, 0, -1, 0,
                                   0, 0, -1, 0]);
  this.positions = new Float32Array([-1, -1, 1, 1, // front
                                     1, -1, 1, 1,
                                     1, 1, 1, 1,
                                     -1, 1, 1, 1,
                                     -1, -1, 1, 1, // bottom
                                     1, -1, 1, 1,
                                     -1, -1, -1, 1,
                                     1, -1, -1, 1,
                                     1, -1, 1, 1, // right
                                     1, 1, 1, 1,
                                     1, -1, -1, 1,
                                     1, 1, -1, 1,
                                     1, 1, 1, 1, // top
                                     -1, 1, 1, 1,
                                     1, 1, -1, 1,
                                     -1, 1, -1, 1,
                                     -1, -1, 1, 1, // left
                                     -1, 1, 1, 1,
                                     -1, -1, -1, 1,
                                     -1, 1, -1, 1,
                                     -1, -1, -1, 1, // bottom
                                     1, -1, -1, 1,
                                     1, 1, -1, 1,
                                     -1, 1, -1, 1,]);

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