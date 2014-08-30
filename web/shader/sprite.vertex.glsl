precision highp float;

attribute vec3 a_pos;
attribute vec2 a_offs;
attribute vec2 a_uv;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;
uniform float u_texAtlasSize;

varying vec2 v_uv;
varying vec3 v_pos;
varying float v_brightness;

void main() {
    v_uv = a_uv/u_texAtlasSize;
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos, 1.0)+vec4(a_offs, 0.0, 0.0);
    v_pos = pos.xyz;
    v_brightness = a_brightness;
    gl_Position = u_projectionMatrix*pos;
}
