part of Dark;

class Shader {
  String vertexShaderSource, fragmentShaderSource;
  GL.Program program;
  
  Shader(this.vertexShaderSource, this.fragmentShaderSource);
  
  void create() {
    GL.Shader vertexShader = compile(vertexShaderSource, GL.VERTEX_SHADER);
    GL.Shader fragmentShader = compile(fragmentShaderSource, GL.FRAGMENT_SHADER);
    program = link(vertexShader, fragmentShader);
  }
  
  void use() {
    gl.useProgram(program);
  }
  
  GL.Program link(GL.Shader vertexShader, GL.Shader fragmentShader) {
    GL.Program program = gl.createProgram();
    gl.attachShader(program, vertexShader);
    gl.attachShader(program, fragmentShader);
    gl.linkProgram(program);
    
    if (!gl.getProgramParameter(program,  GL.LINK_STATUS)) {
      throw gl.getProgramInfoLog(program);
    }
    
    return program;
  }
  
  GL.Shader compile(String source, int type) {
    GL.Shader shader = gl.createShader(type);
    gl.shaderSource(shader,  source);
    gl.compileShader(shader);
    
    if  (!gl.getShaderParameter(shader,  GL.COMPILE_STATUS)) {
      throw gl.getShaderInfoLog(shader);
    }
    
    return shader;
  }
}

Shader spriteShader = new Shader(
/* Vertex Shader */ """
  precision highp float;

  attribute vec3 a_pos;
  attribute vec2 a_offs;
  attribute vec2 a_uv;

  uniform mat4 u_modelMatrix;
  uniform mat4 u_viewMatrix;
  uniform mat4 u_projectionMatrix;

  varying vec2 v_uv;
  varying float v_br;

  void main() {
    v_uv = a_uv/2048.0;
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos, 1.0)+vec4(a_offs, 0.0, 0.0);
//  v_br = 1.0/(length(pos.xyz)*0.01+1.0);
    v_br = 1.0;
    gl_Position = u_projectionMatrix*pos;
  }
""",/* Fragment Shader */  """
  precision highp float;

  varying vec2 v_uv;
  varying float v_br;

  uniform sampler2D u_tex;
  
  void main() {
    vec4 col = texture2D(u_tex, v_uv);
    if (col.a<0.9) discard;
    gl_FragColor = vec4(col.rgb*v_br, 1.0);
  }
""");

Shader floorShader = new Shader(
/* Vertex Shader */ """
  precision highp float;

  attribute vec3 a_pos;
  attribute vec2 a_texOffs;

  uniform mat4 u_modelMatrix;
  uniform mat4 u_viewMatrix;
  uniform mat4 u_projectionMatrix;

  varying vec3 v_brp;
  varying vec2 v_texOffs;


  void main() {
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos, 1.0);
    v_brp = a_pos.xyz;
    v_texOffs = a_texOffs;
    gl_Position = u_projectionMatrix*pos;
  }
""",/* Fragment Shader */  """
  precision highp float;

  varying vec3 v_brp;
  varying vec2 v_texOffs;

  uniform sampler2D u_tex;
  
  void main() {
      vec2 uv = fract(v_brp.xz/64.0)*64.0;
      gl_FragColor = texture2D(u_tex, (uv+v_texOffs)/2048.0);

//    gl_FragColor = vec4(fract((v_brp+vec3(0.05, 0.05, 0.05))/64.0), 1.0);
//    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
  }
""");

Shader wallShader = new Shader(
/* Vertex Shader */ """
  precision highp float;

  attribute vec3 a_pos;
  attribute vec2 a_uv;
  attribute vec2 a_texOffs;
  attribute float a_texWidth;

  uniform mat4 u_modelMatrix;
  uniform mat4 u_viewMatrix;
  uniform mat4 u_projectionMatrix;

  varying float v_br;
  varying vec2 v_uv;
  varying vec2 v_texOffs;
  varying float v_texWidth;

  void main() {
    vec4 pos = u_modelMatrix*u_viewMatrix*vec4(a_pos, 1.0);
    v_br = 1.0/(length(pos.xyz)*0.001+1.0);
    v_uv = a_uv;
    v_texOffs = a_texOffs;
    v_texWidth = a_texWidth;
    gl_Position = u_projectionMatrix*pos;
  }
""",/* Fragment Shader */  """
  precision highp float;

  varying float v_br;
  varying vec2 v_uv;
  varying vec2 v_texOffs;
  varying float v_texWidth;

  uniform sampler2D u_tex;
  
  void main() {

//    256
//    0.25*4 = 1024/256 
    
    float u = fract(v_uv.x/v_texWidth)*v_texWidth;
    float v = fract(v_uv.y/128.0)*128.0;
   
    gl_FragColor = vec4(texture2D(u_tex, (vec2(u,v)+v_texOffs)/2048.0).rgb*v_br, 1.0);
//    gl_FragColor = vec4(v_uv, 1.0, 1.0);
  }
""");


//vec4 col = texture2D(u_tex, v_uv);
//if (col.a<0.5) discard;
//gl_FragColor = col*vec4(v_col, 1.0);









