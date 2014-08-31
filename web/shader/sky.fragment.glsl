precision mediump float;

varying vec3 v_uv;

uniform sampler2D u_texture;

void main() {
    float u = atan(v_uv.x)/4.0;
    u += v_uv.z;
    float v = v_uv.y;

    gl_FragColor = texture2D(u_texture, vec2(u, v));
}