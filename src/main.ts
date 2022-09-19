import {vec3} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Quad from './geometry/Quad';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import Planet from './geometry/Planet';
import * as rng from './random'
import Icosphere from './geometry/Icosphere';
import Ring from './geometry/Ring';

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

// ================================

// planets

let sun: Planet;
let earth: Planet;
let moon: Planet;
let jupiter: Planet;
let saturn: Planet;

let sunShader: ShaderProgram;
let earthShader: ShaderProgram;
let moonShader: ShaderProgram;
let jupiterShader: ShaderProgram;
let saturnShader: ShaderProgram;

let earthCloudsShader: ShaderProgram;
let saturnRingsShader: ShaderProgram;

let planets: Array<Planet> = [];

// asteroids

let asteroids: Array<Planet> = [];
let numAsteroids = 2000;
let asteroidShader: ShaderProgram;

// sky

let skyQuad: Quad;

// ================================

let loadSceneCallback: Function;

function loadScene(gl: WebGL2RenderingContext) {
  for (let planet of [...planets, ...asteroids]) {
    if (planet != null) {
      planet.destroy();
    }
  }

  sun = new Planet([0, 0, 0], 3.0, 10.0, null, 15.0).setShaderProgram(sunShader);
  earth = new Planet([14, 1, 0], 0.4, 1.0, sun, -2.0).setShaderProgram(earthShader);
  moon = new Planet([15, 1, 0], 0.1, 0.0123, earth, 1.5).setShaderProgram(moonShader);
  jupiter = new Planet([100, -3, 0], 1.3, 3.5, sun, 0.8).setShaderProgram(jupiterShader);
  saturn = new Planet([-90, 4, -70], 1.15, 2.2, sun, 0.9).setShaderProgram(saturnShader);

  planets = [sun, earth, moon, jupiter, saturn];

  earth.addAccessory().setDrawable(new Icosphere([0, 0, 0], 0.45, 4))
    .setShaderProgram(earthCloudsShader);
  saturn.addAccessory().setDrawable(new Ring(1.5, 3.0, 96))
    .setShaderProgram(saturnRingsShader);

  asteroids = [];
  for (let i = 0; i < numAsteroids; ++i) {
    let angle = Math.random() * 2.0 * Math.PI;
    let distance = 45.0;
    let position = vec3.fromValues(Math.cos(angle) * distance, 0.0, Math.sin(angle) * distance);
    vec3.add(position, position, vec3.fromValues(
      2.0 * rng.randomGaussian(),
      0.5 * rng.randomGaussian(),
      2.0 * rng.randomGaussian()
    ));

    let radius = rng.random(0.008, 0.012);
    let mass = 0.0001 * Math.pow((radius / 0.01), 3.0);
    let secondsPerAxisRotation = rng.random(1.0, 2.0) * rng.randomSign();

    asteroids.push(new Planet(position, radius * 4.0, mass, sun, secondsPerAxisRotation, 1).setShaderProgram(asteroidShader));
  }

  skyQuad = new Quad();
  skyQuad.create();

  loadSceneCallback();
}

function createShader(gl: WebGL2RenderingContext, prefixVert: string, prefixFrag: string) {
  return new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/' + prefixVert + '-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/' + prefixFrag + '-frag.glsl')),
  ]);
}

function createPlanetShader(gl: WebGL2RenderingContext, prefix: string) {
  return createShader(gl, prefix, prefix);
}

function createNoDisplacementShader(gl: WebGL2RenderingContext, prefixFrag: string) {
  return createShader(gl, 'no-displacement', prefixFrag);
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
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2', {
    premultipliedAlpha: false
  });
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  gl.enable(gl.BLEND)
  gl.blendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

  sunShader = createPlanetShader(gl, 'sun');
  earthShader = createPlanetShader(gl, 'earth');
  moonShader = createPlanetShader(gl, 'moon');
  jupiterShader = createNoDisplacementShader(gl, 'jupiter');
  saturnShader = createNoDisplacementShader(gl, 'saturn');

  earthCloudsShader = createNoDisplacementShader(gl, 'earth-clouds');
  saturnRingsShader = createNoDisplacementShader(gl, 'saturn-rings');

  asteroidShader = createPlanetShader(gl, 'asteroid');

  // Add controls to the gui
  const gui = new DAT.GUI({ width: 400 });

  let gController = gui.add(controls, 'G', 0, 100).onChange((newG: number) => {
    Planet.G = newG;
  });

  let sunDispHeightController = gui.add(controls, 'Sun Displacement Height', 0, 20).onChange((newDispHeight: number) => {
    sunShader.setDisplacementHeight(newDispHeight);
  });

  let sunTimeScaleController = gui.add(controls, 'Sun Time Scale', 0, 20).onChange((newTimeScale: number) => {
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

    prevTime = new Date().getTime();
  }

  gui.add(controls, 'Load Scene');

  const camera = new Camera(vec3.fromValues(0, 0, 10), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(1.0, 0, 0, 1);
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
    for (let planet of [...planets, ...asteroids]) {
      planet.updateVelocity(dtS, planets);
    }
    for (let planet of [...planets, ...asteroids]) {
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
