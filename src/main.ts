import {vec2, vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Cube from './geometry/Cube';
import Background from './geometry/Background';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  Blob: 0.4,
  Warmth: 1.0,
  Transparency: 1.0,
  Lights: true, 
  'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let uniftime: number;
let background: Background;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, 4.0);
  icosphere.create();
  square = new Square(vec3.fromValues(0.0, 0.0, 0.0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
  background = new Background();
  background.create();
}

function main() {
  // Initial display for framerate
  uniftime = 0;
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'Blob', 0, 1).step(0.01);
  gui.add(controls, 'Warmth', 0, 1).step(0.01);
  gui.add(controls, 'Transparency', 0.2, 1).step(0.01);
  gui.add(controls, 'Lights').listen().onChange(function() {});
  gui.add(controls, 'Load Scene');

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

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  // renderer.setClearColor(1.0, 0.5, 0.6, 1);
  renderer.setClearColor(0.0, 0.0, 0.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const noise = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/noise-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/noise-frag.glsl')),
  ]);

  const back = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/background-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/background-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    uniftime ++;
    noise.setDimensions(vec2.fromValues(window.innerWidth * window.devicePixelRatio, window.innerHeight * window.devicePixelRatio));
    
    renderer.render(camera, noise, [
      icosphere
      // square,
      // cube,
    ], uniftime,
    controls.Blob,
    controls.Warmth,
    controls.Transparency,
    controls.Lights);
    stats.end();

    renderer.render(camera, back, [
      background
    ], uniftime,
    controls.Blob,
    controls.Warmth,
    controls.Transparency,
    controls.Lights);
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
