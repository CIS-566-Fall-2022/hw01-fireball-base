import {vec3, mat4, mat3} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Texture from './Texture'
import {gl} from './globals';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  // default_color: vec3.fromValues(1, 0, 0)
  // R: 1.0,
  // G: 0.0,
  // B: 0.0,
  FireRoughness: 0.75,
  Speed: 1.0,
  Happy: true,
};

let icosphere: Icosphere;
let leftEye: Icosphere;
let leftIris: Icosphere;
let rightEye: Icosphere;
let rightIris: Icosphere;
let mouth: Icosphere;

let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let prevR: number = 1;
let prevG: number = 0.0;
let prevB: number = 0.0;
let prevFireRoughness: number = 0.0;
let prevSpeed: number = 1.0;
let prevHappy: boolean = true;


let leftEyeCenter: vec3 = vec3.fromValues(0.74, 0.0, -1.2);
let rightEyeCenter: vec3 = vec3.fromValues(-0.74, 0.0, -1.2);
let mouthPos: vec3 = vec3.fromValues(0.0, -0.3, -1.2);

//time:

let time: number = 0.0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  leftEye = new Icosphere(leftEyeCenter, 0.2, controls.tesselations);
  leftEye.create();
  rightEye = new Icosphere(rightEyeCenter, 0.2, controls.tesselations);
  rightEye.create();
  leftIris = new Icosphere(vec3.fromValues(0.74, 0.0, -1.276), 0.13, controls.tesselations);
  leftIris.create();
  rightIris = new Icosphere(vec3.fromValues(-0.74, 0.0, -1.276), 0.13, controls.tesselations);
  rightIris.create();
  mouth = new Icosphere(mouthPos, 0.13, controls.tesselations);
  mouth.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  //Cube:
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

//Update the existing GUI in main.ts with:
//    a parameter to alter the color passed to u_Color in the Lambert shader. 
function loadTexture(url: string) {
  console.log('loadtexture called');
  const texture = gl.createTexture();
  const image = new Image();

  image.onload = e => {
      console.log('Image onload called');
      // alert('Onload');
      gl.bindTexture(gl.TEXTURE_2D, texture);

      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
      gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA,
                            image.width, image.height,
                            0, gl.RGBA, gl.UNSIGNED_BYTE, image);
      // gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  };
  image.src = 'Texture.jpg';
  return texture;
}

function loadTexture2(image: HTMLImageElement, i: WebGLTexture) {
  // alert('bruh');
  gl.bindTexture(gl.TEXTURE_2D, i);
      
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  gl.generateMipmap(gl.TEXTURE_2D);
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  // gui.add(controls, 'R', 0.0, 1.0).step(0.01);
  // gui.add(controls, 'G', 0.0, 1.0).step(0.01);
  // gui.add(controls, 'B', 0.0, 1.0).step(0.01);
  gui.add(controls, 'FireRoughness', 0.0, 1.0).step(0.01);
  gui.add(controls, 'Speed', 0.0, 5.0).step(0.5);
  gui.add(controls, 'Happy');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  // const camera = new Camera(vec3.fromValues(0.0, 0.0, -15.0), vec3.fromValues(0.0, 0.0, 0.0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.0, 0.0, 0.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const custom_perlin = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/customPerlin-frag.glsl')),
  ]);

  const fireBall = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireBall-vert.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireBall-frag.glsl')),
  ]);

  const fireBallEye = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireBallEye-vert.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireBallEye-frag.glsl')),
  ]);

  const fireBallIris = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireBallIris-frag.glsl')),
  ]);

  const fireBallMouth = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireBallMouth-vert.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireBallMouth-frag.glsl')),
  ]);

  const textureTest = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/textureShader-vert.glsl')),
    // new Shader(gl.VERTEX_SHADER, require('./shaders/trig-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/textureShader-frag.glsl')),
  ]);

  //Initialize Texture
  // ---- load texture
  // const texture1 = new Texture();
  const textur = loadTexture('src\ExampleTexture.jpg');

  
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, textur);

 const camera = new Camera(vec3.fromValues(0.0, 0.0, -15.0), vec3.fromValues(0.0, 0.0, 0.0));
  // var texture_1 = loadTexture('src\ExampleTexture.jpg');
  // texture_1.initializeTexture('./bruh.png');
  // texture_1.load();
  // texture_1.bind(0);
  gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
  textureTest.setTextureSampler(0);

  // This function will be called every frame
  function tick() {
    time++;
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();

      leftEye = new Icosphere(vec3.fromValues(0.65, 0.1, -0.8), 0.2, controls.tesselations);
      leftEye.create();
      rightEye = new Icosphere(vec3.fromValues(-0.65, 0.1, -0.8), 0.2, controls.tesselations);
      rightEye.create();
    }

    if (controls.FireRoughness != prevFireRoughness) {
      prevFireRoughness = controls.FireRoughness;
    }
    if (controls.Speed != prevSpeed) {
      prevSpeed = controls.Speed;
    }
    if (controls.Happy != prevHappy) {
      prevHappy = controls.Happy;
    }
    //Add time input into this call!!!
    // gl.disable(gl.DEPTH_TEST);

    //refresh texture:
    gl.activeTexture(gl.TEXTURE0);
    gl.bindTexture(gl.TEXTURE_2D, textur);
    textureTest.setTextureSampler(0);
  
    let id: mat4 = mat4.create();
    mat4.identity(id);
    renderer.render(camera, fireBall, [
      icosphere,
      // leftEye,
      // square,
      // cube,
      ],
      // vec3.fromValues(controls.R, controls.G, controls.B),
      // camera.position,
      time * controls.Speed, controls.FireRoughness, controls.Happy, [id,]
    );
    renderer.render(camera, fireBallEye, [
      // icosphere,
      leftEye,
      rightEye,
      // square,
      // square,
      // cube,
      ],
      // vec3.fromValues(controls.R, controls.G, controls.B),
      time * controls.Speed, controls.FireRoughness, controls.Happy, [id, ]
    );
    renderer.render(camera, fireBallIris, [
      // icosphere,
      leftIris,
      rightIris,
      // square,
      // square,
      // cube,
      ],
      // vec3.fromValues(controls.R, controls.G, controls.B),
      time * controls.Speed, controls.FireRoughness, controls.Happy, [id, ]
    );
    //Transformations for 3D mouth (redacted):
      // let mouthScale: mat4 = mat4.create();
      // mat4.fromScaling(mouthScale, vec3.fromValues(2.0, 0.8, 1.2));
      // let mouthTrans: mat4 = mat4.create();
      // mat4.fromTranslation(mouthTrans, mouthPos);
      // mat4.invert(mouthTrans, mouthTrans);
      // let mouthModel: mat4 = mat4.create();
      // mat4.multiply(mouthModel, mouthScale, mouthTrans);
      // mat4.invert(mouthTrans, mouthTrans);
      // mat4.multiply(mouthModel, mouthTrans, mouthModel);
    // renderer.render(camera, fireBallMouth, [
    //   // icosphere,
    //   mouth,
    //   // square,
    //   // square,
    //   // cube,
    //   ],
    //   vec3.fromValues(controls.R, controls.G, controls.B),
    //   time, [mouthModel,]
    // );

    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();