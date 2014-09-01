part of Dark;

List<Shader> allShaders = new List<Shader>();

class Shader {
  String name;
  GL.Program program;

  Shader(this.name) {
    allShaders.add(this);
  }

  static Future loadAndCompileAll() {
    List<Future> allFutures = new List<Future>();
    
    for (int i=0; i<allShaders.length; i++) {
      allFutures.add(allShaders[i].loadAndCompile());
    }

    return Future.wait(allFutures);
  }

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
