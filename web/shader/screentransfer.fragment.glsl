precision mediump float;

varying vec2 v_uv;

uniform sampler2D u_texture;
uniform sampler2D u_colorLookup;
uniform float u_invulnerable;

void main() {
    vec2 texOffset = vec2(0.2/512.0, 0.0/512.0);
    vec4 inputSample = texture2D(u_texture, v_uv+texOffset);
    gl_FragColor = inputSample;
}
