part of Dark;

List<Shader> allShaders = new List<Shader>();

Shaders shaders = new Shaders();

class Shaders {
  Shader spriteShader = new Shader("sprite");
  Shader transparentSpriteShader = new Shader("transparentsprite");
  Shader wallShader = new Shader("wall");
  Shader floorShader = new Shader("floor");
  Shader screenBlitShader = new Shader("screenblit");
  Shader screenTransferShader = new Shader("screentransfer");
  Shader skyShader = new Shader("sky");
  Shader segNormalShader = new Shader("segnormal");
  Shader segDistanceShader = new Shader("segdist");
  
  Future loadAndCompileAll() {
    List<Future> allFutures = new List<Future>();
    
    for (int i=0; i<allShaders.length; i++) {
      allFutures.add(allShaders[i].loadAndCompile());
    }

    return Future.wait(allFutures);
  }
}

class Shader {
  static const int BYTES_PER_FLOAT = 4;

  String name;
  GL.Program program;
  HashMap<String, int> attribs = new HashMap<String, int>();
  HashMap<String, GL.UniformLocation> uniforms = new HashMap<String, GL.UniformLocation>();
  

  Shader(this.name) {
    allShaders.add(this);
  }
  
  void uniformMatrix4fv(String name, bool transpose, Float32List data) {
    if (!uniforms.containsKey(name)) return;
    gl.uniformMatrix4fv(uniforms[name], transpose, data);
  }

  void uniform1f(String name, double data) {
    if (!uniforms.containsKey(name)) return;
    gl.uniform1f(uniforms[name], data);
  }

  void uniform2f(String name, double d0, double d1) {
    if (!uniforms.containsKey(name)) return;
    gl.uniform2f(uniforms[name], d0, d1);
  }
  
  void uniform1i(String name, int data) {
    if (!uniforms.containsKey(name)) return;
    gl.uniform1i(uniforms[name], data);
  }  
  
  void bindVertexData(String name, int length, int offs, int floatsPerVertex) {
    if (!attribs.containsKey(name)) return;
    int location = attribs[name]; 
    gl.enableVertexAttribArray(location);
    gl.vertexAttribPointer(location, length, GL.FLOAT, false, floatsPerVertex * BYTES_PER_FLOAT, offs * BYTES_PER_FLOAT);
  }
  
/*
 *   int posLocation;
  int texOffsLocation;
  int brightnessLocation;

  GL.UniformLocation modelMatrixLocation;
  GL.UniformLocation projectionMatrixLocation;
  GL.UniformLocation viewMatrixLocation;
  GL.UniformLocation texAtlasSizeLocation;
 */  

  Future loadAndCompile() {
    String shaderRootUrl = "shader/$name"; 
    Completer completer = new Completer();
    Shader _this = this;
    
    loadStringFromUrl("$shaderRootUrl.vertex.glsl").then((vertexShaderSource) {
      loadStringFromUrl("$shaderRootUrl.fragment.glsl").then((fragmentShaderSource) {
        try {
          create(vertexShaderSource, fragmentShaderSource);
          completer.complete(_this);
        } catch (e) {
          completer.completeError("Failed to create shader $name\r$e");
        }
      }).catchError((e)=>completer.completeError(e));
    }).catchError((e)=>completer.completeError(e));
    return completer.future;
  }

  void create(String vertexShaderSource, String fragmentShaderSource) {
    GL.Shader vertexShader = compile(vertexShaderSource, GL.VERTEX_SHADER);
    GL.Shader fragmentShader = compile(fragmentShaderSource, GL.FRAGMENT_SHADER);
    program = link(vertexShader, fragmentShader);
    
    gl.useProgram(program);
    
    int uniformCount = gl.getProgramParameter(program,  GL.ACTIVE_UNIFORMS);
    for (int i=0; i<uniformCount; i++) {
      String name = gl.getActiveUniform(program,  i).name;
      uniforms[name] = gl.getUniformLocation(program,  name);
    }
    
    int attributeCount = gl.getProgramParameter(program, GL.ACTIVE_ATTRIBUTES);
    for (int i=0; i<attributeCount; i++) {
      String name = gl.getActiveAttrib(program,  i).name;
      attribs[name] = gl.getAttribLocation(program,  name);
    }
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
      throw "Failed to link\r${gl.getProgramInfoLog(program)}";
    }
    
    return program;
  }
  
  GL.Shader compile(String source, int type) {
    GL.Shader shader = gl.createShader(type);
    gl.shaderSource(shader,  source);
    gl.compileShader(shader);
    
    if  (!gl.getShaderParameter(shader,  GL.COMPILE_STATUS)) {
      throw "Failed to compile ${type==GL.VERTEX_SHADER?"vertex":"fragment"} shader\r${gl.getShaderInfoLog(shader)}";
    }
    
    return shader;
  }
}
