precision mediump float;

varying vec2 v_uv;
varying vec3 v_pos;
varying float v_brightness;
varying vec2 v_real_screenPos;
varying float v_ssectorId;

uniform sampler2D u_tex;
uniform sampler2D u_backTex;

void main() {
    vec4 col = texture2D(u_tex, v_uv);
    if (col.a<0.9) discard;

    vec3 bgSsectorCol = texture2D(u_backTex, v_real_screenPos).rgb;
    float steps = 64.0;
    float bgSsector = floor(bgSsectorCol.r*steps);
    bgSsector = bgSsector*steps+floor(bgSsectorCol.g*steps);
    bgSsector = bgSsector*steps+floor(bgSsectorCol.b*steps);
    
    if (bgSsector<v_ssectorId) discard;
    
    float ib = 1.0-v_brightness;
    ib = ib*ib*ib;
    ib = ib*ib;
    float brightness = ((v_brightness+1.0)/(length(v_pos.z)*ib+v_brightness+1.0));
    gl_FragColor = vec4(col.rg, brightness, 1.0);
}
