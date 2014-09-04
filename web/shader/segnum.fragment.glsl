 precision mediump float;

varying vec3 v_col;

uniform float u_texAtlasSize;
uniform sampler2D u_tex;

void main() {
    gl_FragColor = vec4(v_col, 1.0);
}