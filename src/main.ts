import {vec4, vec3} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

let icosphere: Icosphere;
let prevTesselations: number = 5;
let square: Square;
let cube: Cube;
let time: number = 0;
let updateProperties = true;

enum shaders {
  lambert,
  flat,
  fireball,
  bg,
}
const vertShaders: string[] = [
  "./shaders/lambert-vert.glsl",
  "./shaders/flat-vert.glsl",
  "./shaders/fireball-vert.glsl",
  "./shaders/bg-vert.glsl",
];
const fragShaders: string[] = [
 "./shaders/lambert-frag.glsl",
 "./shaders/flat-frag.glsl",
 "./shaders/fireball-frag.glsl",
 "./shaders/bg-frag.glsl",
];

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  timeScale: 12.0,
  rotationRate: 3.0,
  frequency: 0.05,
  persistence: 0.7,
  octaves: 6,
  bloom: true,
  shader: shaders.fireball,
  color: [255, 255, 255, 1],
  'Load Scene': loadScene, // A function pointer, essentially
};

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, 5);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0), 8.0);
  square.create();
  cube = new Cube(vec3.fromValues(2, 0, 0));
  cube.create();
  console.log(square.positions);
  time = 0;

  updateProperties = true;
}

function main() {
  window.addEventListener('keypress', function (e) {
    // console.log(e.key);
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  window.addEventListener('keyup', function (e) {
    switch(e.key) {
      // Use this if you wish
    }
  }, false);

  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

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

  const camera = new Camera(vec3.fromValues(0, 0, 10), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(164.0 / 255.0, 233.0 / 255.0, 1.0, 1);
  renderer.setClearColor(0.1, 0.1, 0.1, 1);
  gl.enable(gl.DEPTH_TEST);

  const fireballShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('' + vertShaders[controls.shader] + '')),
    new Shader(gl.FRAGMENT_SHADER, require('' + fragShaders[controls.shader] + '')),
  ]);

  const bgShader = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('' + vertShaders[shaders.bg] + '')),
    new Shader(gl.FRAGMENT_SHADER, require('' + fragShaders[shaders.bg] + '')),
  ]);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'timeScale', 0, 50).onChange((amp: number) => {
    fireballShader.setTimeScale(amp);
    bgShader.setTimeScale(controls.timeScale);
  });
  gui.add(controls, 'rotationRate', 1, 10).step(1).onChange((amp: number) => {
    fireballShader.setRotationRate(amp);
  });
  gui.add(controls, 'frequency', 0, 1.0).onChange((amp: number) => {
    fireballShader.setPerlinFreq(amp);
  });
  gui.add(controls, 'persistence', 0.0, 1.5).onChange((amp: number) => {
    fireballShader.setPersistence(amp);
    bgShader.setPersistence(amp);
  });
  gui.add(controls, 'octaves', 0, 15).step(1).onChange((amp: number) => {
    fireballShader.setOctaves(amp);
    bgShader.setOctaves(amp);
  });
  gui.add(controls, 'bloom').onChange((amp: boolean) => {
    fireballShader.setBloom(amp);
  });
  // gui.add(controls, "shader", {Custom: shaders.custom, Lambert: shaders.lambert, Flat: shaders.flat}).onChange(() => updateShader = true);
  gui.addColor(controls,'color');
  gui.add(controls, 'Load Scene');

  function processKeyPresses() {
    // Use this if you wish
  }

  // This function will be called every frame
  function tick() {
    camera.update();
    // stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    processKeyPresses();

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    if (updateProperties) {
      fireballShader.setTimeScale(controls.timeScale);
      fireballShader.setRotationRate(controls.rotationRate);
      fireballShader.setPerlinFreq(controls.frequency);
      fireballShader.setPersistence(controls.persistence);
      fireballShader.setOctaves(controls.octaves);
      fireballShader.setBloom(controls.bloom);

      bgShader.setTimeScale(controls.timeScale);
      bgShader.setPersistence(controls.persistence);
      bgShader.setOctaves(controls.octaves);

      updateProperties = false;
    }

    const newColor = vec4.fromValues(controls.color[0]/255, controls.color[1]/255, controls.color[2]/255, controls.color[3]);
    
    gl.disable(gl.DEPTH_TEST);
    renderer.render(camera, bgShader, [square], time, newColor);

    gl.enable(gl.DEPTH_TEST);
    renderer.render(camera, fireballShader, [icosphere], time, newColor);

    time++;
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
    fireballShader.setDimensions(window.innerWidth, window.innerHeight);
    bgShader.setDimensions(window.innerWidth, window.innerHeight);
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();
  fireballShader.setDimensions(window.innerWidth, window.innerHeight);
  bgShader.setDimensions(window.innerWidth, window.innerHeight);

  // Start the render loop
  tick();
}

main();
