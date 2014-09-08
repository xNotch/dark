precision mediump float;

varying vec2 v_uv;
varying vec3 v_pos;
varying float v_brightness;
varying vec2 v_real_screenPos;
varying float v_zDistance;
varying float v_ssectorId;

uniform sampler2D u_tex;
uniform sampler2D u_distanceTex;
uniform sampler2D u_normalTex;

#define M_PI 3.1415926535897932384626433832795

void main() {
    vec4 col = texture2D(u_tex, v_uv);
    if (col.a<0.9) discard;
    float steps = 128.0;

    vec4 bgSegDistanceLimits = texture2D(u_distanceTex, v_real_screenPos);
    float bgSegDistanceLow = floor(bgSegDistanceLimits.r*steps);
    bgSegDistanceLow = bgSegDistanceLow*steps+floor(bgSegDistanceLimits.g*steps);
    float bgSegDistanceHigh = floor(bgSegDistanceLimits.b*steps);
    bgSegDistanceHigh = bgSegDistanceHigh*steps+floor(bgSegDistanceLimits.a*steps);
    
    if (v_zDistance<=bgSegDistanceHigh*v_ssectorId) discard;
    if (v_zDistance<=bgSegDistanceLow*v_ssectorId) {
      vec4 bgSegNormal = texture2D(u_normalTex, v_real_screenPos);
      float bgSegNormalDist = floor(bgSegNormal.r*steps);
      bgSegNormalDist = bgSegNormalDist*steps+floor(bgSegNormal.g*steps);
      bgSegNormalDist = bgSegNormalDist*steps+floor(bgSegNormal.b*steps);
  
      float dir = bgSegNormal.a*M_PI*2.0;
      float xn = sin(dir);
      float zn = cos(dir);
      
      float myDist = (v_pos.x*xn+v_pos.z*zn)*v_ssectorId;
      
      if (myDist>bgSegNormalDist) discard;
    }
    
    
    
    float ib = 1.0-v_brightness;
    ib = ib*ib*ib;
    ib = ib*ib;
    float brightness = ((v_brightness+1.0)/(length(v_pos.z)*ib+v_brightness+1.0));
    gl_FragColor = vec4(col.rg, brightness, 1.0);
}
