precision highp float;

varying vec2 v_uv;
varying vec3 v_pos;
varying float v_brightness;

uniform sampler2D u_tex;

void main() {
    vec4 col = texture2D(u_tex, v_uv);
    if (col.a<0.9) discard;
    float ib = 1.0-v_brightness;
    ib = ib*ib*ib;
    ib = ib*ib;
    float brightness = ((v_brightness+1.0)/(length(v_pos.z)*ib+v_brightness+1.0));
    gl_FragColor = vec4(col.rg, brightness, 1.0);
}
