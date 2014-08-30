precision highp float;

varying vec2 v_uv;

uniform sampler2D u_texture;
uniform sampler2D u_colorLookup;

void main() {
    vec2 texOffset = vec2(0.2/512.0, 0.0/512.0);
    vec4 inputSample = texture2D(u_texture, v_uv+texOffset);
    vec2 colorIndex = inputSample.rg;
    float brightnessIndex = floor((1.0-inputSample.b)*32.0+0.5)/32.0; // 0-1, in 32 steps?
    float xBrightness = fract(brightnessIndex*2.0); // 0-1, 0-1 in 16 steps each.
    float yBrightness = floor(brightnessIndex*2.0+1.0)/16.0; // 0 or 1
    vec2 brightnessPos = vec2(xBrightness, yBrightness);

    vec2 colorMappedColorIndex = texture2D(u_colorLookup, colorIndex/16.0+brightnessPos).rg;

    gl_FragColor = vec4(texture2D(u_colorLookup, colorMappedColorIndex/16.0).rgb, inputSample.a);
}
