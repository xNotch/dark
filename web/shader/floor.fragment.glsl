 precision mediump float;

varying vec2 v_uv;
varying vec3 v_pos;
varying vec2 v_texOffs;
varying float v_brightness;

uniform float u_texAtlasSize;
uniform sampler2D u_tex;

void main() {
    float dist = length(v_pos.z);
    float scale = 1.0-120.0/(dist+120.0);
    float brightness = clamp(0.0, v_brightness*2.0, v_brightness*2.0-clamp(0.0, 1.0, scale));
    
    vec2 uv = clamp(fract(v_uv/64.0)*64.0, 0.5, 63.5);
    vec4 texCol = texture2D(u_tex, (uv+v_texOffs)/u_texAtlasSize);
    gl_FragColor = vec4(texCol.rg, brightness, texCol.a);
}