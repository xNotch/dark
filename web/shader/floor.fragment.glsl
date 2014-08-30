 precision highp float;

varying vec2 v_uv;
varying vec3 v_pos;
varying vec2 v_texOffs;
varying float v_brightness;

uniform float u_texAtlasSize;
uniform sampler2D u_tex;

void main() {
    float ib = 1.0-v_brightness;
    ib = ib*ib*ib;
    ib = ib*ib;
    float brightness = ((v_brightness+1.0)/(length(v_pos.z)*ib+v_brightness+1.0));
    vec2 uv = clamp(fract(v_uv/64.0)*64.0, 0.5, 63.5);
    vec4 texCol = texture2D(u_tex, (uv+v_texOffs)/u_texAtlasSize);
    gl_FragColor = vec4(texCol.rg, brightness, texCol.a);
}