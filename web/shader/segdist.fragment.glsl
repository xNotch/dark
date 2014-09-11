 precision mediump float;

varying vec4 v_col;

uniform float u_texAtlasSize;
uniform sampler2D u_tex;

#define M_PI 3.1415926535897932384626433832795

void main() {
  gl_FragColor = v_col;
}