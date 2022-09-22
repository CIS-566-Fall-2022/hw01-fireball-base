import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  surfaceOffset: 1.0,
  coronaScale: 0.1,
  starDensity: 20.0,
  cloudColor: [ 51, 77, 204, 255 ],
  starColor: [ 51, 77, 204, 255 ],
  'restoreDefaults': restoreDefaults
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let cloudColor = vec4.fromValues(0.2, 0.3, 0.8, 1);
let starColor = vec4.fromValues(0.2, 0.3, 0.8, 1);
let geometryColor = vec4.fromValues(1, 1, 1, 1);
let prevNoiseScale: number = 1.0;
let time = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function restoreDefaults() {
  controls.tesselations = 5;
  controls.surfaceOffset = 1.0;
  controls.coronaScale = 0.1;
  controls.starDensity = 20.0;
  controls.cloudColor = [ 51, 77, 204, 255 ];
  controls.starColor = [ 51, 77, 204, 255 ];
  cloudColor = vec4.fromValues(0.2, 0.3, 0.8, 1);
  starColor = vec4.fromValues(0.2, 0.3, 0.8, 1);
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
  gui.add(controls, 'tesselations', 0, 6).step(1).listen();
  gui.add(controls, 'surfaceOffset', 0.1, 1.0).step(0.1).listen(); 
  gui.add(controls, 'coronaScale', 0.05, 0.15).step(0.01).listen();   
  gui.add(controls, 'starDensity', 10.0, 50.0).step(1.0).listen();
  gui.addColor(controls, 'cloudColor').onChange(function() { 
                                                cloudColor = vec4.fromValues(
                                                  controls.cloudColor[0] / 255, 
                                                  controls.cloudColor[1] / 255, 
                                                  controls.cloudColor[2] / 255, 
                                                  controls.cloudColor[3] / 255); 
                                                }).listen();
  gui.addColor(controls, 'starColor').onChange(function() { 
                                               starColor = vec4.fromValues(
                                                controls.starColor[0] / 255, 
                                                controls.starColor[1] / 255, 
                                                controls.starColor[2] / 255, 
                                                controls.starColor[3] / 255); 
                                              }).listen();
  gui.add(controls, 'restoreDefaults').listen();

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
  renderer.setClearColor(1.0, 0.0, 1.0, 1);
  gl.enable(gl.DEPTH_TEST);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/background-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/background-frag.glsl')),
  ]);

  const fireball = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),
  ]);

  //fireball.setNoiseScale(controls.surfaceOffset);
  //background.setNoiseScale(controls.surfaceOffset);

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
    //if (controls.surfaceOffset != prevNoiseScale)
    //{
      //prevNoiseScale = controls.surfaceOffset;
      fireball.setNoiseScale(controls.surfaceOffset);
      background.setNoiseScale(controls.surfaceOffset);
    //}

    background.setCoronaScale(controls.coronaScale);
    background.setStarDensity(controls.starDensity);
    background.setCloudColor(cloudColor);
    background.setStarColor(starColor);

    time++;

    // Render background first, then star
    gl.disable(gl.DEPTH_TEST);

    renderer.render(camera, background, geometryColor, time, [square]);

    gl.enable(gl.DEPTH_TEST);

    renderer.render(camera, fireball, geometryColor, time, [icosphere]);
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
