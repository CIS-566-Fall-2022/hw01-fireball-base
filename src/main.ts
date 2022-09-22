import {vec2, vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Cube from './geometry/cube';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  color: [ 242, 206, 33, 255 ], // RGB with alpha
  intensity: 2.2,
  speed: 2,
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;
let preGeoColor: number[] = [ 242, 206, 33, 255 ];
let cube: Cube;
let time: number = 0;
let prevPerlinScale: number = 1.8;
let prevFreq: number = 3;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
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
  gui.addColor(controls, 'color');
  gui.add(controls, 'intensity', 1, 10).step(0.2);
  gui.add(controls, 'speed', 1, 10).step(1);

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

  // --------- load texture -----------
  function loadTexture(url: string) {
    const texture = gl.createTexture();
  
    const image = new Image();
  
    image.onload = function() {
      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA,gl.UNSIGNED_BYTE, image);
      gl.generateMipmap(gl.TEXTURE_2D);
    };
    image.src = url;
  
    return texture;
  }

  const surfaceTex = loadTexture('../texture/surface.png');
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, surfaceTex);
  // -----------------------------------


  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const bkg = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/bkg-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/bkg-frag.glsl')),
  ]);

  lambert.setTexture(0);

  // This function will be called every frame
  function tick() {
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      // icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      // icosphere.create();
    }
    if (controls.color != preGeoColor) {
      preGeoColor = controls.color;
      renderer.setGeoColor(preGeoColor[0], preGeoColor[1], preGeoColor[2], preGeoColor[3]);
    }
    if (controls.speed != prevFreq) {
      prevFreq = controls.speed;
    }
    if (controls.intensity != prevPerlinScale) {
      prevPerlinScale = controls.intensity;
    }

    renderer.render(camera, lambert, [
      icosphere,
    ]);

    renderer.render(camera, bkg, [
      square,
    ]);
    
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
    bkg.setTime(++time);

    lambert.setTime(time);
    lambert.setResolution(vec2.fromValues(window.innerWidth, window.innerHeight));
    lambert.setFreq(prevFreq);
    lambert.setPerlinScale(prevPerlinScale);
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
