import { gl } from '../src/globals';
//Sources:
//https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/Tutorial/Using_textures_in_WebGL
//https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/Image
function isPowerOf2(v) {
    return v && !(v & (v - 1));
}
class Texture {
    constructor() {
        this.m_textureHandle = -1;
    }
    initializeTexture(texturePath) {
        this.m_textureHandle = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, this.m_textureHandle);
        // Because images have to be downloaded over the internet
        // they might take a moment until they are ready.
        // Until then put a single pixel in the texture so we can
        // use it immediately. When the image has finished downloading
        // we'll update the texture with the contents of the image.
        const level = 0;
        const internalFormat = gl.RGBA;
        const width = 1;
        const height = 1;
        const border = 0;
        const srcFormat = gl.RGBA;
        const srcType = gl.UNSIGNED_BYTE;
        const pixel = new Uint8Array([0, 0, 255, 255]); // opaque blue
        gl.texImage2D(gl.TEXTURE_2D, level, internalFormat, width, height, border, srcFormat, srcType, pixel);
        this.m_textureImage = new Image();
        // this.m_textureImage.onload = () => {
        //     const pixel2 = new Uint8Array([255, 0, 0, 255]);  // opaque blue
        //     gl.bindTexture(gl.TEXTURE_2D, this.m_textureHandle);
        //     gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
        //         width, height, border, srcFormat, srcType,
        //         pixel2);
        //     // gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
        //     //             srcFormat, srcType, this.m_textureImage);
        //     // WebGL1 has different requirements for power of 2 images
        //     // vs non power of 2 images so check if the image is a
        //     // power of 2 in both dimensions.
        //     if (isPowerOf2(this.m_textureImage.width) && isPowerOf2(this.m_textureImage.height)) {
        //     // Yes, it's a power of 2. Generate mips.
        //     gl.generateMipmap(gl.TEXTURE_2D);
        //     } else {
        //     // No, it's not a power of 2. Turn off mips and set
        //     // wrapping to clamp to edge
        //     gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        //     gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        //     gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        //     }
        // };
        // texturePath;
        this.m_textureImage.src = texturePath;
        return this.m_textureHandle;
    }
    load() {
        const level = 0;
        const internalFormat = gl.RGBA;
        const width = 1;
        const height = 1;
        const border = 0;
        const srcFormat = gl.RGBA;
        const srcType = gl.UNSIGNED_BYTE;
        const pixel2 = new Uint8Array([255, 0, 0, 255]); // opaque blue
        gl.bindTexture(gl.TEXTURE_2D, this.m_textureHandle);
        if (this.m_textureImage.src == 'src/ExampleTexture.jpg') {
            gl.texImage2D(gl.TEXTURE_2D, level, internalFormat, width, height, border, srcFormat, srcType, pixel2);
        }
        console.log("huh??");
        // gl.texImage2D(gl.TEXTURE_2D, level, internalFormat,
        //             srcFormat, srcType, this.m_textureImage);
        // WebGL1 has different requirements for power of 2 images
        // vs non power of 2 images so check if the image is a
        // power of 2 in both dimensions.
        if (isPowerOf2(this.m_textureImage.width) && isPowerOf2(this.m_textureImage.height)) {
            // Yes, it's a power of 2. Generate mips.
            gl.generateMipmap(gl.TEXTURE_2D);
        }
        else {
            // No, it's not a power of 2. Turn off mips and set
            // wrapping to clamp to edge
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        }
    }
    bind(texSlot) {
        gl.activeTexture(gl.TEXTURE0 + texSlot);
        gl.bindTexture(gl.TEXTURE_2D, this.m_textureHandle);
    }
}
;
export default Texture;
//# sourceMappingURL=Texture.js.map