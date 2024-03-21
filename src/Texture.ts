import {gl} from '../src/globals';

//Sources:
//https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/Tutorial/Using_textures_in_WebGL
//https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/Image

function isPowerOf2(v: number) {
    return v && !(v & (v - 1));
}

class Texture {
    m_textureImage: HTMLImageElement;
    m_textureHandle: WebGLTexture = -1;

    constructor() {
    }

    loadTexture(url: string) {
        const texture = gl.createTexture();
        const image = new Image();
      
        image.onload = e => {
            alert('huh');
            gl.bindTexture(gl.TEXTURE_2D, texture);
            
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
      
            gl.generateMipmap(gl.TEXTURE_2D);
        };
        image.src = url;
        return texture;
    }
    bind(texSlot: number) {
    }
};

export default Texture;