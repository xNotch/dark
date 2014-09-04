precision mediump float;

attribute vec4 a_pos;
attribute vec2 a_texOffs;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;

varying vec3 v_col;


void main() {
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos.xyz, 1.0);
    float steps = 64.0;
    v_col = vec3(fract(floor(a_pos.w/steps/steps)/steps), fract(floor(a_pos.w/steps)/steps), fract(a_pos.w/steps))+(0.5/steps);
    gl_Position = u_projectionMatrix*pos;
}