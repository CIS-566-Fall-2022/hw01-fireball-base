import {vec3} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Quad from './geometry/Quad';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Planet from './geometry/Planet';

const controls = {
  G: 1.0,
  'Sun Displacement Height': 1.0,
  'Sun Time Scale': 1.0,
  'Sun Temperature (K)': 5778,
  'Load Scene': loadScene,
};

let defaultControls = {
  ...controls
}

let sun: Planet;
let earth: Planet;
let moon: Planet;

let sunShader: ShaderProgram;
let earthShader: ShaderProgram;
let moonShader: ShaderProgram;

let planets: Array<Planet>;

let skyQuad: Quad;

let loadSceneCallback: Function;

function loadScene(gl: WebGL2RenderingContext) {
  sun = new Planet([0, 0, 0], 1.4, 5.0, null, 15.0);
  earth = new Planet([10, 0, 0], 0.4, 1.0, sun, -2.0);
  moon = new Planet([10.9, 0, 0], 0.1, 0.0123, earth, 1.5);
  
  planets = [sun, earth, moon];

  sun.shaderProgram = sunShader;
  earth.shaderProgram = earthShader;
  moon.shaderProgram = moonShader;

  skyQuad = new Quad();
  skyQuad.create();

  loadSceneCallback();
}

function createPlanetShader(gl: WebGL2RenderingContext, prefix: string) {
  return new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/' + prefix + '-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/' + prefix + '-frag.glsl')),
  ]);
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

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  sunShader = createPlanetShader(gl, 'sun');
  earthShader = createPlanetShader(gl, 'earth');
  moonShader = createPlanetShader(gl, 'moon');

  // Add controls to the gui
  const gui = new DAT.GUI({ width: 400 });

  let gController = gui.add(controls, 'G', 0.2, 5.0).onChange((newG: number) => {
    Planet.G = newG;
  });

  let sunDispHeightController = gui.add(controls, 'Sun Displacement Height', 0, 20.0).onChange((newDispHeight: number) => {
    sunShader.setDisplacementHeight(newDispHeight);
  });

  let sunTimeScaleController = gui.add(controls, 'Sun Time Scale', 0, 20.0).onChange((newTimeScale: number) => {
    sunShader.setTimeScale(newTimeScale);
  });

  let sunTemperatureController = gui.add(controls, 'Sun Temperature (K)', 2000, 28000, 1).onChange((newTemperature: number) => {
    sunShader.setTemperature(newTemperature);
  });

  controls['Load Scene'] = function() { 
    loadScene(gl);
  };

  loadSceneCallback = function() {
    gController.setValue(defaultControls.G);
    sunDispHeightController.setValue(defaultControls['Sun Displacement Height']);
    sunTimeScaleController.setValue(defaultControls['Sun Time Scale']);
    sunTemperatureController.setValue(defaultControls['Sun Temperature (K)']);

    for (let planet of planets) {
      planet.setInitialVelocity();
    }
  }

  gui.add(controls, 'Load Scene');

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  // Initial call to load scene
  loadScene(gl);

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

  addEventListener('visibilitychange', (event) => {
    if (document.visibilityState === 'visible') {
      prevTime = new Date().getTime();
    }
  });

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
