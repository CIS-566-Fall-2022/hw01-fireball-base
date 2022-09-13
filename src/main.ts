import {vec3} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Quad from './geometry/Quad';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Planet from './geometry/Planet';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  'Load Scene': loadScene, // A function pointer, essentially
};

let sun: Planet;
let earth: Planet;
let moon: Planet;

let planets: Array<Planet>;

let skyQuad: Quad;

function loadScene() {
  sun = new Planet([0, 0, 0], 1.0, 5.0, null);
  earth = new Planet([10, 0, 0], 0.4, 1.0, sun);
  moon = new Planet([10.7, 0, 0], 0.1, 0.0123, earth);
  
  planets = [sun, earth, moon];

  skyQuad = new Quad();
  skyQuad.create();
}

let prevTime: number = new Date().getTime();

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

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  // Initial call to load scene
  loadScene();

  sun.shaderProgram = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/sun-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/sun-frag.glsl')),
  ]);

  earth.shaderProgram = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/earth-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/earth-frag.glsl')),
  ]);

  moon.shaderProgram = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/moon-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/moon-frag.glsl')),
  ]);

  const skyShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/passthrough-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/sky-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    let currentTime = new Date().getTime();
    let dtMs = currentTime - prevTime;
    renderer.addTime(dtMs);
    prevTime = currentTime;

    let dtS = dtMs / 1000.0;
    for (let planet of planets) {
      planet.updateVelocity(dtS, planets);
    }

    for (let planet of planets) {
      planet.updatePosition(dtS);
    }
    
    for (let planet of planets) {
      renderer.renderPlanet(camera, planet);
    }

    renderer.render(camera, skyShader, [
      skyQuad,
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
