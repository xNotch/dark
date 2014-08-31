precision mediump float;

attribute vec3 a_pos;
attribute vec2 a_uv;
attribute vec2 a_texOffs;
attribute float a_texWidth;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;

varying vec3 v_pos;
varying vec2 v_uv;
varying vec2 v_texOffs;
varying float v_texWidth;
varying float v_brightness;

void main() {
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos, 1.0);
    v_pos = pos.xyz;
    v_uv = a_uv;
    v_brightness = a_brightness;
    v_texOffs = a_texOffs;
    v_texWidth = a_texWidth;
    gl_Position = u_projectionMatrix*pos;
}
