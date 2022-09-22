import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  red: 255,
  green: 0,
  blue: 0,
  amp: 0.5,
  freq: 5.0,
  oct: 8,
  'Earth Config': earth, // Function to change to earth
  'Fireball': fireball, // Function to change to efireball
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let m_time: number = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function earth() {
  controls.tesselations = 8;
  controls.red = 0;
  controls.green = 200;
  controls.blue = 150;
  controls.amp = 0.5;
  controls.freq = 3.0;
  controls.oct = 8;
}

function fireball() {
  controls.tesselations = 5;
  controls.red = 190;
  controls.green = 20;
  controls.blue = 15;
  controls.amp = 0.5;
  controls.freq = 4.0;
  controls.oct = 8;
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
  gui.add(controls, 'red', 0, 255).step(1);
  gui.add(controls, 'green', 0, 255).step(1);
  gui.add(controls, 'blue', 0, 255).step(1);
  gui.add(controls, 'amp', 0.0, 1.0).step(0.1);
  gui.add(controls, 'freq', 0.0, 20.0).step(1.0);
  gui.add(controls, 'oct', 0, 16).step(1);
  gui.add(controls, 'Earth Config');
  gui.add(controls, 'Fireball');

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
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  // const lambert = new ShaderProgram([
  //   new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
  //   new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  // ]);

  const custom1 = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/custom-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/custom-frag.glsl')),
  ]);

  const flat = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    
    // set Color
    // lambert.setGeometryColor(vec4.fromValues(controls.red/255., controls.green/255., controls.blue/255., 1));
    custom1.setGeometryColor(vec4.fromValues(controls.red/255., controls.green/255., controls.blue/255., 1));
    flat.setGeometryColor(vec4.fromValues(0.0,0.0,0.0,1.0));

    // set time
    custom1.setTime(m_time);
    m_time++;

    // set amp
    custom1.setAmp(controls.amp);

    // set freq
    custom1.setFreq(controls.freq);

    // set oct
    custom1.setOct(controls.oct);

    // render
    renderer.render(camera, flat, [
      square,
    ]);

    gl.clear(gl.DEPTH_BUFFER_BIT);
    
    renderer.render(camera, custom1, [
      icosphere,
      // cube,
    ]);
    
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
