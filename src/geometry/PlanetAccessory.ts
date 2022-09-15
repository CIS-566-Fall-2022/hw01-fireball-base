import Drawable from "../rendering/gl/Drawable";
import ShaderProgram from "../rendering/gl/ShaderProgram";

class PlanetAccessory {
  private drawable: Drawable;
  private shaderProgram: ShaderProgram;

  public setDrawable(drawable: Drawable) {
    this.drawable = drawable;
    this.drawable.create();
    return this;
  }

  public setShaderProgram(shaderProgram: ShaderProgram) {
    this.shaderProgram = shaderProgram;
    return this;
  }
  
  public getDrawable(): Drawable {
    return this.drawable;
  }

  public getShaderProgram(): ShaderProgram {
    return this.shaderProgram;
  }
}

export default PlanetAccessory;