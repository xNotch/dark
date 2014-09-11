precision mediump float;

attribute vec4 a_pos;
attribute vec2 a_texOffs;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;

varying vec4 v_col;

#define M_PI 3.1415926535897932384626433832795

void main() {
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos.xyz, 1.0);
    
    float xn = sin(a_pos.w);
    float zn = cos(a_pos.w);
    v_col.r = (xn)*0.5+0.5;
    v_col.b = (zn)*0.5+0.5;
    v_col.g = (0.5);
    v_col.a = (0.5);
    
    float dist = floor(pos.x*xn+pos.z*zn);
    
    float steps = 128.0;
    v_col.r = fract(floor(dist/steps/steps)/steps)+(0.5/steps);
    v_col.g = fract(floor(dist/steps)/steps)+(0.5/steps);
    v_col.b = fract(dist/steps)+(0.5/steps);
    v_col.a = fract(a_pos.w/(M_PI*2.0));
    
    gl_Position = u_projectionMatrix*pos;
}