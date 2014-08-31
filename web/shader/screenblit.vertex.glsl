precision mediump float;

attribute vec2 a_pos;
attribute vec2 a_uv;

uniform mat4 u_projectionMatrix;

varying vec2 v_uv;

void main() {
    v_uv = a_uv;
    gl_Position = u_projectionMatrix*vec4(a_pos, 0.0, 1.0);
}
