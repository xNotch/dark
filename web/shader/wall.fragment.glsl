precision highp float;

varying vec3 v_pos;
varying vec2 v_uv;
varying vec2 v_texOffs;
varying float v_texWidth;
varying float v_brightness;

uniform float u_texAtlasSize;
uniform sampler2D u_tex;

void main() {
    float u = clamp(fract(v_uv.x/v_texWidth)*v_texWidth, 0.5, v_texWidth-0.5);
    float v = clamp(fract(v_uv.y/128.0)*128.0, 0.5, 127.5);

    vec4 texCol = texture2D(u_tex, (vec2(u,v)+v_texOffs)/u_texAtlasSize);
    if (texCol.a<1.0) discard;

    float ib = 1.0-v_brightness;
    ib = ib*ib*ib;
    ib = ib*ib;
    float brightness = ((v_brightness+1.0)/(length(v_pos.z)*ib+v_brightness+1.0));

    gl_FragColor = vec4(texCol.rg, brightness, 1.0);
    //    gl_FragColor = vec4(v_uv, 1.0, 1.0);
}
