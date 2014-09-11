precision mediump float;

attribute vec3 a_pos;
attribute float a_subSectorId;
attribute vec2 a_offs;
attribute vec2 a_uv;
attribute float a_brightness;

uniform mat4 u_modelMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_projectionMatrix;
uniform float u_texAtlasSize;
uniform vec2 u_viewportSize;
uniform vec2 u_bufferSize;
uniform float u_clipSegs;

varying vec2 v_uv;
varying vec3 v_pos;
varying vec2 v_real_screenPos;
varying float v_brightness;
varying float v_ssectorId;
varying float v_zDistance;

void main() {
    v_uv = a_uv/u_texAtlasSize;
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos, 1.0);
    v_pos = pos.xyz;
    pos+=vec4(a_offs, 0.0, 0.0);
    v_brightness = a_brightness;
    vec4 projectedPos = u_projectionMatrix*pos;
    
    v_ssectorId = u_clipSegs;
    float steps = 128.0;
    v_zDistance = floor((steps*steps-1.0)*8.0/-pos.z);
    
    vec4 screenCoord = projectedPos;    
    screenCoord /= screenCoord.w; // perspective divide
    screenCoord.x = (screenCoord.x+1.)*u_viewportSize.x/2./u_bufferSize.x + 0.0; // viewport transformation
    screenCoord.y = (screenCoord.y+1.)*u_viewportSize.y/2./u_bufferSize.y + (u_bufferSize.y-u_viewportSize.y); // viewport transformation    
    v_real_screenPos = screenCoord.xy;

    gl_Position = projectedPos;
}