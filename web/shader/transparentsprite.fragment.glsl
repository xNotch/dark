precision highp float;

varying vec2 v_uv;
varying vec3 v_pos;
varying vec2 v_screenPos;
varying float v_brightness;

uniform sampler2D u_tex;
uniform float u_time;

void main() {
    vec4 col = texture2D(u_tex, v_uv);
    if (col.a<0.9) discard;
    float ib = 1.0-v_brightness;
    ib = ib*ib*ib;
    ib = ib*ib;
    float brightness = ((v_brightness+1.0)/(length(v_pos.z)*ib+v_brightness+1.0));

    float x = floor(v_screenPos.x);
    float y = floor(v_screenPos.y);
    x = -x*1197.0+(x/64.0)*(x/64.0)*8617.0;
    x+=u_time*63.231312;
    y+=u_time*14.34234;
    float transparentBrightness = 0.9-fract((x+y)/8.0)/2.0;
    gl_FragColor = vec4(col.rg, transparentBrightness, 1.0);
}
