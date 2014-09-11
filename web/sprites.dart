part of Dark;

class Sprites {
  // Vertex data:

  // x, y, z      0 + 3 = 3
  // subSectorId  3 + 1 = 4
  // xo, yo       4 + 2 = 6
  // u, v         6 + 2 = 8
  // br           8 + 1 = 9
  
  static const int BYTES_PER_FLOAT = 4;

  static const int FLOATS_PER_VERTEX = 9;
  static const int MAX_VERICES = 65536;
  static const int MAX_SPRITES = MAX_VERICES~/4;
  
//  Shader shader;
  GL.Texture texture;
  
  GL.Buffer vertexBuffer, indexBuffer;

  Float32List vertexData = new Float32List(MAX_VERICES*FLOATS_PER_VERTEX);
  int spriteCount = 0;
  
  Sprites(this.texture) {
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
    
    Int16List indexData = new Int16List(MAX_SPRITES*6);
    for (int i=0; i<MAX_SPRITES; i++) {
      int offs = i*4;
      indexData.setAll(i*6, [offs+0, offs+1, offs+2, offs+0, offs+2, offs+3]);
    }
    
    indexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);
    /*
    shader.use();
    subSectorIdLocation = gl.getAttribLocation(shader.program, "a_subSectorId");
    offsetLocation = gl.getAttribLocation(shader.program, "a_offs");
    uvLocation = gl.getAttribLocation(shader.program, "a_uv");
    brightnessLocation = gl.getAttribLocation(shader.program, "a_brightness");

    modelMatrixLocation = gl.getUniformLocation(shader.program, "u_modelMatrix");
    viewMatrixLocation = gl.getUniformLocation(shader.program, "u_viewMatrix");
    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
    texAtlasSizeLocation = gl.getUniformLocation(shader.program, "u_texAtlasSize");
    timeLocation = gl.getUniformLocation(shader.program, "u_time");
    
    viewportSizeLocation = gl.getUniformLocation(shader.program, "u_viewportSize");
    bufferSizeLocation = gl.getUniformLocation(shader.program, "u_bufferSize");
    
    GL.UniformLocation frameLocation = gl.getUniformLocation(shader.program, "u_frame");
    if (frameLocation!=null) gl.uniform1i(frameLocation, 1);
    if (frameLocation!=null) gl.uniform1i(gl.getUniformLocation(shader.program, "u_tex"), 0);
     */
  }
  
  void clear() {
    spriteCount = 0;
  }
  
  void insertSprite(double br, Vector3 p, SpriteTemplateRot str) {
    if (invulnerable) br = 1.0;
    
    vertexData.setAll(spriteCount*FLOATS_PER_VERTEX*4, [
        p.x, p.y, p.z, 0.0, str.xOffs0, str.yOffs0, str.u0, str.v0, br,
        p.x, p.y, p.z, 0.0, str.xOffs1, str.yOffs0, str.u1, str.v0, br,
        p.x, p.y, p.z, 0.0, str.xOffs1, str.yOffs1, str.u1, str.v1, br,
        p.x, p.y, p.z, 0.0, str.xOffs0, str.yOffs1, str.u0, str.v1, br,
    ]);
    
    spriteCount++;
  }
  
  void insertGuiSprite(int x, int y, int z, Image image) {
    double px = x+0.0;
    double py = y+0.0;
    double pz = 0.0-z*0.001;
    double br = 1.0;
    
    double xOffs0 = -image.xCenter+0.0;
    double yOffs0 = -image.yCenter+0.0;
    double xOffs1 = xOffs0+image.width;
    double yOffs1 = yOffs0+image.height;

    double u0 = image.xAtlasPos+0.0;
    double v0 = image.yAtlasPos+0.0;
    double u1 = u0+image.width;
    double v1 = v0+image.height;
    
    vertexData.setAll(spriteCount*FLOATS_PER_VERTEX*4, [
        px, py, pz, 0.0, xOffs0, yOffs0, u0, v0, br,
        px, py, pz, 0.0, xOffs1, yOffs0, u1, v0, br,
        px, py, pz, 0.0, xOffs1, yOffs1, u1, v1, br,
        px, py, pz, 0.0, xOffs0, yOffs1, u0, v1, br,
    ]);
    
    spriteCount++;
  }
    
  
  void render(Shader shader, GL.Texture segDistanceTexture, GL.Texture segNormalTexture, bool clipAgainstSegs) {
    if (spriteCount==0) return;
    shader.use();

    shader.uniform1i("u_distanceTex", 2);
    shader.uniform1i("u_normalTex", 1);
    shader.uniform1i("u_tex", 0);
    gl.activeTexture(GL.TEXTURE2);
    gl.bindTexture(GL.TEXTURE_2D, segDistanceTexture);
    gl.activeTexture(GL.TEXTURE1);
    gl.bindTexture(GL.TEXTURE_2D, segNormalTexture);
    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, spriteCount*FLOATS_PER_VERTEX*4) as Float32List);
    
    shader.uniformMatrix4fv("u_modelMatrix", false, modelMatrix.storage);
    shader.uniformMatrix4fv("u_viewMatrix", false, viewMatrix.storage);
    shader.uniformMatrix4fv("u_projectionMatrix", false, projectionMatrix.storage);
    shader.uniform1f("u_texAtlasSize", TEXTURE_ATLAS_SIZE+0.0);
    shader.uniform1f("u_time", transparentNoiseTime+0.0);
    shader.uniform2f("u_viewportSize", screenWidth+0.0, screenHeight+0.0);
    shader.uniform2f("u_bufferSize", frameBufferRes+0.0, frameBufferRes+0.0);
    if (clipAgainstSegs) {
      shader.uniform1f("u_clipSegs", 1.0);
    } else {
      shader.uniform1f("u_clipSegs", 0.0);
    }
    
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    shader.bindVertexData("a_pos", 3, 0, FLOATS_PER_VERTEX);
    shader.bindVertexData("a_subSectorId", 1, 3, FLOATS_PER_VERTEX);
    shader.bindVertexData("a_offs", 2, 4, FLOATS_PER_VERTEX);
    shader.bindVertexData("a_uv", 2, 6, FLOATS_PER_VERTEX);
    shader.bindVertexData("a_brightness", 1, 8, FLOATS_PER_VERTEX);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, spriteCount*6, GL.UNSIGNED_SHORT, 0);
  }
}

HashMap<String, SpriteTemplate> spriteTemplates = new HashMap<String, SpriteTemplate>();

class SpriteTemplateRot {
  Image image;
  bool mirror;
  double xOffs0;
  double yOffs0;
  double xOffs1;
  double yOffs1;
  
  double u0;
  double v0;
  double u1;
  double v1;  
  
  SpriteTemplateRot(this.image, this.mirror) {
    if (mirror) {
      int xc2 = image.width-image.xCenter;
      xOffs0 = (0.0-xc2);
      xOffs1 = (image.width+0.0-xc2);
      u0 = image.xAtlasPos+0.0;
      u1 = image.xAtlasPos+image.width+0.0;
    } else {
      xOffs0 = (0.0-image.xCenter);
      xOffs1 = (image.width+0.0-image.xCenter);
      u0 = image.xAtlasPos+image.width+0.0;
      u1 = image.xAtlasPos+0.0;
    }
    yOffs0 = -(0.0-image.yCenter);
    yOffs1 = -(image.height+0.0-image.yCenter);
    v0 = image.yAtlasPos+0.0;
    v1 = image.yAtlasPos+image.height+0.0;
  }
}

class SpriteTemplateFrame {
  List<SpriteTemplateRot> rots;
  
  void setRot(int rot, Image image, bool mirror) {
    if (rot==0) {
      if (rots==null) rots = new List<SpriteTemplateRot>(1);
      else if (rots.length!=1) throw "Tried to insert a 0 rot in a SpriteTemplateFrame";
      rots[0] = new SpriteTemplateRot(image, false);
    } else {
      if (rots==null) rots = new List<SpriteTemplateRot>(8);
      else if (rots.length!=8) throw "Tried to insert too many rots in a SpriteTemplateFrame";
      rots[rot-1] = new SpriteTemplateRot(image, mirror);
    }
  }
}

const String FRAME_NAMES = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

class SpriteTemplate {
  String name;
  List<SpriteTemplateFrame> frames = new List<SpriteTemplateFrame>();
  
  SpriteTemplate(this.name) {
  }
  
  void addFrame(Image image, int frame, int rot, bool mirror) {
    while (frames.length<=frame) frames.add(new SpriteTemplateFrame());
    frames[frame].setRot(rot, image, mirror);
  }
  
  static void addFrameFromLump(String pname, Image image) {
    String spriteName = pname.substring(0, 4);
    if (!spriteTemplates.containsKey(spriteName)) spriteTemplates[spriteName] = new SpriteTemplate(spriteName);
    SpriteTemplate template = spriteTemplates[spriteName];

    template.addFrame(image, FRAME_NAMES.indexOf(pname.substring(4, 5)), int.parse(pname.substring(5, 6)), false);
    if (pname.length==8) {
      template.addFrame(image, FRAME_NAMES.indexOf(pname.substring(6, 7)), int.parse(pname.substring(7, 8)), true);
    }
  }
}




class ScreenRenderer {
  // Vertex data:

  // x, y      0 + 2 = 2
  // u, v      2 + 2 = 4
  
  static const int BYTES_PER_FLOAT = 4;

  static const int FLOATS_PER_VERTEX = 4;
  
  Shader shader;
  GL.Texture texture;
  GL.Texture colorLookupTexture;
  
  GL.Buffer vertexBuffer, indexBuffer;
  
  int posLocation;
  int uvLocation;
  
  GL.UniformLocation projectionMatrixLocation;    
  GL.UniformLocation invulnerableLocation;    
  
  Float32List vertexData = new Float32List(4*FLOATS_PER_VERTEX);
  
  ScreenRenderer(this.shader, this.texture, this.colorLookupTexture) {
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
    
    Int16List indexData = new Int16List(6);
    indexData.setAll(0, [0, 1, 2, 0, 2, 3]);
    
    indexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);
    
    shader.use();
    posLocation = gl.getAttribLocation(shader.program, "a_pos");
    uvLocation = gl.getAttribLocation(shader.program, "a_uv");
    
    gl.uniform1i(gl.getUniformLocation(shader.program, "u_texture"), 0);
    gl.uniform1i(gl.getUniformLocation(shader.program, "u_colorLookup"), 1);
    invulnerableLocation = gl.getUniformLocation(shader.program, "u_invulnerable");
    

    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
  }

  void render() {
    shader.use();
    gl.activeTexture(GL.TEXTURE1);
    gl.bindTexture(GL.TEXTURE_2D, colorLookupTexture);
    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    double w = screenWidth.toDouble();
    double h = screenHeight.toDouble();
    double u = w/indexColorBuffer.width;
    double v = h/indexColorBuffer.height;
    vertexData.setAll(0, [
                              0.0, 0.0, 0.0,   v,
                              0.0,   h, 0.0, 0.0,
                                w,   h,   u, 0.0,
                                w, 0.0,   u,   v,
                         ]);
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData);
    
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    gl.uniform1f(invulnerableLocation, invulnerable?1.0:0.0);
    
    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(uvLocation);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(posLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(uvLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 2*BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0);
  }
}



class SkyRenderer {
  // Vertex data:

  // x, y      0 + 2 = 2
  // u, v, o   2 + 3 = 5
  
  static const int BYTES_PER_FLOAT = 4;

  static const int FLOATS_PER_VERTEX = 5;
  
  Shader shader;
  GL.Texture texture;
  GL.Texture colorLookupTexture;
  
  GL.Buffer vertexBuffer, indexBuffer;
  
  int posLocation;
  int uvLocation;
  
  GL.UniformLocation projectionMatrixLocation;    
  
  Float32List vertexData = new Float32List(4*FLOATS_PER_VERTEX);
  
  SkyRenderer(this.shader, this.texture) {
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
    
    Int16List indexData = new Int16List(6);
    indexData.setAll(0, [0, 1, 2, 0, 2, 3]);
    
    indexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);
    
    shader.use();
    posLocation = gl.getAttribLocation(shader.program, "a_pos");
    uvLocation = gl.getAttribLocation(shader.program, "a_uv");

    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
  }
  
  void render() {
    shader.use();
    gl.activeTexture(GL.TEXTURE0);
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    double w = screenWidth.toDouble();
    double h = screenHeight.toDouble();
    double uo = player.rot*1.0/(PI*2);
    double u = w/h*0.12*PI;
    double v = 200/128;
    vertexData.setAll(0, [
                              0.0, 0.0, -u, 0.0, uo,
                              0.0,   h, -u,   v, uo,
                                w,   h,  u,   v, uo,
                                w, 0.0,  u, 0.0, uo,
                         ]);
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData);
    
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    
    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(uvLocation);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(posLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(uvLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 2*BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, 6, GL.UNSIGNED_SHORT, 0);
  }
}
