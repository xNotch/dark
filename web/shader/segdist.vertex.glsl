precision mediump float;

attribute vec4 a_pos;
attribute vec2 a_texOffs;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;

varying vec4 v_col;

void main() {
    float steps = 128.0;
    float lowDist = floor((steps*steps-1.0)*8.0/(a_texOffs.x));
    float highDist = floor((steps*steps-1.0)*8.0/(a_texOffs.y));
    
    v_col.r = fract(floor(lowDist/steps)/steps)+(0.5/steps);
    v_col.g = fract(lowDist/steps)+(0.5/steps);
    v_col.b = fract(floor(highDist/steps)/steps)+(0.5/steps);
    v_col.a = fract(highDist/steps)+(0.5/steps);
    
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos.xyz, 1.0);
    gl_Position = u_projectionMatrix*pos;
}