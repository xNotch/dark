part of Dark;

List<Shader> allShaders = new List<Shader>();

class Shader {

  String name;
  GL.Program program;

  Shader(this.name) {
    print("Adding shader $name");
    allShaders.add(this);
  }

  static void loadAndCompileAll(onLoad, onFail) {
    print("Trying to load ${allShaders.length} shaders");
    Function functionQueue = (){onLoad();};
    for (int i=0; i<allShaders.length; i++) {
      Shader s = allShaders[i];
      Function previous = functionQueue;
      functionQueue = (){s.loadAndCompile(()=>previous(), onFail);};
    }
    functionQueue();
  }

  void loadAndCompile(onLoad, onFail) {
    String shaderRootUrl = "shader/"+name;
    print("Trying to load $shaderRootUrl");
    loadString(shaderRootUrl+".vertex.glsl", (vertexString) {
      loadString(shaderRootUrl+".fragment.glsl", (fragmentString) {
        create(vertexString, fragmentString);
        onLoad();
      }, onFail);
    }, onFail);
  }

  void create(vertexShaderSource, fragmentShaderSource) {
    print("$vertexShaderSource, $fragmentShaderSource");
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

void loadString(String url, Function onLoaded, Function onFail) {
  var request = new HttpRequest();
  request.open("get",  url);
  request.responseType = "text";
  request.onLoadEnd.listen((e) {
    print("${request.status}");
    if (request.status~/100==2) {
      onLoaded(request.response as String);
    } else {
      onFail();
    }
  });
  request.send("");
}
