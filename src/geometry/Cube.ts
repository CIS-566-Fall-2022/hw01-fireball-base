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

  createCubeIndices() {
    let idx = 0;
    for (let i = 0; i < 6; i++) {
        this.indices[idx++] = i*4;
        this.indices[idx++] = i*4+1;
        this.indices[idx++] = i*4+2;
        this.indices[idx++] = i*4;
        this.indices[idx++] = i*4+2;
        this.indices[idx++] = i*4+3;
        console.log ("Block statement execution no." + i);
    }
  }

  createCubeVertexNormals() {
    let idx = 0;
    //Front
    for(let i = 0; i < 4; i++){
        // this.normals[idx++] = glm::vec4(0,0,1,0);
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
        this.normals[idx++] = 1;
        this.normals[idx++] = 0;
    }
    //Right
    for(let i = 0; i < 4; i++){
        // cub_vert_nor[idx++] = glm::vec4(1,0,0,0);
        this.normals[idx++] = 1;
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
    }
    //Left
    for(let i = 0; i < 4; i++){
        // cub_vert_nor[idx++] = glm::vec4(-1,0,0,0);
        this.normals[idx++] = -1;
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
    }
    //Back
    for(let i = 0; i < 4; i++){
        // cub_vert_nor[idx++] = glm::vec4(0,0,-1,0);
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
        this.normals[idx++] = -1;
        this.normals[idx++] = 0;
    }
    //Top
    for(let i = 0; i < 4; i++){
        // cub_vert_nor[idx++] = glm::vec4(0,1,0,0);
        this.normals[idx++] = 0;
        this.normals[idx++] = 1;
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
    }
    //Bottom
    for(let i = 0; i < 4; i++){
        // cub_vert_nor[idx++] = glm::vec4(0,-1,0,0);
        this.normals[idx++] = 0;
        this.normals[idx++] = -1;
        this.normals[idx++] = 0;
        this.normals[idx++] = 0;
    }
  }

  createCubeVertexPositions() {
    let idx = 0;
    //Front face
    //UR (1, 1, 1, 1)
    this.positions.set([1.0, 1.0, 1.0, 1.0], idx);
    idx += 4;
    //LR (1, 0, 1, 1)
    this.positions.set([1.0, 0.0, 1.0, 1.0], idx);
    idx += 4;
    //LL (0, 0, 1, 1)
    this.positions.set([0.0, 0.0, 1.0, 1.0], idx);
    idx += 4;
    //UL (0, 1, 1, 1)
    this.positions.set([0.0, 1.0, 1.0, 1.0], idx);
    idx += 4;

    //Right face
    //UR (1, 1, 0 , 1)
    this.positions.set([1.0, 1.0, 0.0, 1.0], idx);
    idx += 4;
    //LR (1, 0, 0, 1)
    this.positions.set([1.0, 0.0, 0.0, 1.0], idx);
    idx += 4;
    //LL (1, 0, 1, 1)
    this.positions.set([1.0, 0.0, 1.0, 1.0], idx);
    idx += 4;
    //UL (1, 1, 1, 1)
    this.positions.set([1.0, 1.0, 1.0, 1.0], idx);
    idx += 4;

    //Left face
    //UR (0, 1, 1, 1)
    this.positions.set([0.0, 1.0, 1.0, 1.0], idx);
    idx += 4;
    //LR
    this.positions.set([0.0, 0.0, 1.0, 1.0], idx);
    idx += 4;
    //LL
    this.positions.set([0.0, 0.0, 0.0, 1.0], idx);
    idx += 4;
    //UL
    this.positions.set([0.0, 1.0, 0.0, 1.0], idx);
    idx += 4;

    //Back ace
    //UR
    this.positions.set([0.0, 1.0, 0.0, 1.0], idx);
    idx += 4;
    //LR
    this.positions.set([0.0, 0.0, 0.0, 1.0], idx);
    idx += 4;
    //LL
    this.positions.set([1.0, 0.0, 0.0, 1.0], idx);
    idx += 4;
    //UL
    this.positions.set([1.0, 1.0, 0.0, 1.0], idx);
    idx += 4;

    //Top ace
    //UR
    this.positions.set([1.0, 1.0, 0.0, 1.0], idx);
    idx += 4;
    //LR
    this.positions.set([1.0, 1.0, 1.0, 1.0], idx);
    idx += 4;
    //LL
    this.positions.set([0.0, 1.0, 1.0, 1.0], idx);
    idx += 4;
    //UL
    this.positions.set([0.0, 1.0, 0.0, 1.0], idx);
    idx += 4;

    //Bottom ace
    //UR
    this.positions.set([1.0, 0.0, 1.0, 1.0], idx);
    idx += 4;
    //LR
    this.positions.set([1.0, 0.0, 0.0, 1.0], idx);
    idx += 4;
    //LL
    this.positions.set([0.0, 0.0, 0.0, 1.0], idx);
    idx += 4;
    //UL
    this.positions.set([0.0, 0.0, 1.0, 1.0], idx);
  }

  centerCube() {
      for (let i = 0; i < 96; i++) {
          this.positions[i] -= 0.5;
      }
  }

  create() {

    this.indices = new Uint32Array(36);
    this.normals = new Float32Array(96);
    this.positions = new Float32Array(96);

    //1. Fill up this.indices, this.normals and this.positions
    this.createCubeIndices();
    this.createCubeVertexNormals();
    this.createCubeVertexPositions();
    // this.centerCube();
    
    //2. call generate for all 3
    this.generateIdx();
    this.generatePos();
    this.generateNor();

    //3. set count
    this.count = this.indices.length;

    //4. Send to GPU
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    console.log(`Created Cube`);
  }
};

export default Cube;

