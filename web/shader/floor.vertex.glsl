precision mediump float;

attribute vec4 a_pos;
attribute vec2 a_texOffs;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;

varying vec2 v_uv;
varying vec3 v_pos;
varying vec2 v_texOffs;
varying float v_brightness;


void main() {
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos.xyz, 1.0);
    v_pos = pos.xyz;
    v_uv = a_pos.xz*vec2(1.0, -1.0);
    v_texOffs = a_texOffs;
    v_brightness = a_brightness;
    vec4 projectedPos = u_projectionMatrix*pos;
    gl_Position = projectedPos;
}