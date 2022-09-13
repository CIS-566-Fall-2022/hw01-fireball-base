import {vec3} from 'gl-matrix';
import ShaderProgram from '../rendering/gl/ShaderProgram';
import Icosphere from "./Icosphere";

// const G = 6.67430e-11;
const G = 1.0;

const subdivisions = 6;

class Planet extends Icosphere {
  public shaderProgram: ShaderProgram
  public velocity = vec3.create();

  constructor(public position: vec3, radius: number, public mass: number, 
      public parent: Planet, private invertVelocity: boolean = false) {
    super([0, 0, 0], radius, subdivisions);

    this.create();

    if (this.parent != null) {
      this.setInitialVelocity();
    }
  }

  private setInitialVelocity() {
    let v = Math.sqrt(G * this.parent.mass / vec3.distance(this.position, this.parent.position)); // sqrt((G * m_2) / r)
    let vecToParent = vec3.create();
    vec3.subtract(vecToParent, this.parent.position, this.position)
    vec3.normalize(vecToParent, vecToParent);
    vec3.cross(this.velocity, vecToParent, vec3.fromValues(0, 1, 0));
    vec3.scale(this.velocity, this.velocity, v);
    vec3.add(this.velocity, this.velocity, this.parent.velocity);
  }

  public updateVelocity(dt: number, planets: Array<Planet>) {
    if (this.parent == null) {
      return;
    }

    let a = vec3.create();

    for (let planet of planets) {
      if (planet == this) {
        continue;
      }

      let a2 = vec3.create();
      let magnitude = G * planet.mass / vec3.squaredDistance(this.position, planet.position);
      vec3.subtract(a2, planet.position, this.position);
      vec3.normalize(a2, a2);
      vec3.scale(a2, a2, magnitude);
      vec3.add(a, a, a2);
    }

    let dv = vec3.create();
    vec3.scale(dv, a, dt);
    vec3.add(this.velocity, this.velocity, dv);
  }

  public updatePosition(dt: number) {
    if (this.parent == null) {
      return;
    }

    let dx = vec3.create();
    vec3.scale(dx, this.velocity, dt);
    vec3.add(this.position, this.position, dx);
  }
}

export default Planet;