import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';

class Ring extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;

  constructor(private r1: number, private r2: number, private segments: number) {
    super();
  }

  create() {
    this.indices = new Uint32Array(this.segments * 6);
    this.positions = new Float32Array(this.segments * 8);
    this.normals = new Float32Array(this.segments * 8);

    let dTheta = 2.0 * Math.PI / this.segments;
    for (let i = 0; i < this.segments * 2; ++i) {
      let j = i * 4;

      this.normals[j] = 0;
      this.normals[j + 1] = 1;
      this.normals[j + 2] = 0;
      this.normals[j + 3] = 0;

      let r = (i % 2 == 0) ? this.r1 : this.r2;
      let theta = dTheta * Math.floor(i / 2);
      this.positions[j] = r * Math.cos(theta);
      this.positions[j + 1] = 0;
      this.positions[j + 2] = r * Math.sin(theta);
      this.positions[j + 3] = 1;
    }

    for (let i = 0; i < this.segments - 1; i++) {
      let j = i * 6;

      let firstVert = i * 2;
      this.indices[j] = firstVert;
      this.indices[j + 1] = firstVert + 1;
      this.indices[j + 2] = firstVert + 2;
      this.indices[j + 3] = firstVert + 1;
      this.indices[j + 4] = firstVert + 2;
      this.indices[j + 5] = firstVert + 3;
    }

    let firstVert = (this.segments - 1) * 6;
    this.indices[firstVert] = this.segments * 2 - 2;
    this.indices[firstVert + 1] = this.segments * 2 - 1;
    this.indices[firstVert + 2] = 0;
    this.indices[firstVert + 3] = this.segments * 2 - 1;
    this.indices[firstVert + 4] = 0;
    this.indices[firstVert + 5] = 1;

    this.generateIdx();
    this.generatePos();
    this.generateNor();

    this.count = this.indices.length;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);
  }
};

export default Ring;