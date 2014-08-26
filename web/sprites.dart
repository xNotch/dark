part of Dark;

class Sprites {
  // Vertex data:

  // x, y, z      0 + 3 = 3
  // xo, yo       3 + 2 = 5
  // u, v         5 + 2 = 7
  // br           7 + 1 = 8
  
  static const int BYTES_PER_FLOAT = 4;

  static const int FLOATS_PER_VERTEX = 8;
  static const int MAX_VERICES = 65536;
  static const int MAX_SPRITES = MAX_VERICES~/4;
  
  List<Sprite> sprites = new List<Sprite>();
  Shader shader;
  
  GL.Texture texture;
  GL.Buffer vertexBuffer, indexBuffer;
  
  int posLocation;
  int offsetLocation;
  int uvLocation;
  int brightnessLocation;
  
  GL.UniformLocation modelMatrixLocation;    
  GL.UniformLocation projectionMatrixLocation;    
  GL.UniformLocation viewMatrixLocation;
  GL.UniformLocation texAtlasSizeLocation;
  
  Float32List vertexData = new Float32List(MAX_VERICES*FLOATS_PER_VERTEX);
  
  Sprites(this.shader, this.texture) {
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
    
    shader.use();
    posLocation = gl.getAttribLocation(shader.program, "a_pos");
    offsetLocation = gl.getAttribLocation(shader.program, "a_offs");
    uvLocation = gl.getAttribLocation(shader.program, "a_uv");
    brightnessLocation = gl.getAttribLocation(shader.program, "a_brightness");

    modelMatrixLocation = gl.getUniformLocation(shader.program, "u_modelMatrix");
    viewMatrixLocation = gl.getUniformLocation(shader.program, "u_viewMatrix");
    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
    texAtlasSizeLocation = gl.getUniformLocation(shader.program, "u_texAtlasSize");
  }
  
  void addSprite(Sprite sprite) {
    sprites.add(sprite);
  }
  
  void render() {
    shader.use();
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    int toReplace = sprites.length;
    if (toReplace>MAX_SPRITES) toReplace=MAX_SPRITES;
    for (int i=0; i<toReplace; i++) {
      sprites[i].set(vertexData,  i*FLOATS_PER_VERTEX*4);
    }
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, toReplace*FLOATS_PER_VERTEX*4) as Float32List);
    
    gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
    gl.uniformMatrix4fv(viewMatrixLocation, false, viewMatrix.storage);
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    gl.uniform1f(texAtlasSizeLocation, TEXTURE_ATLAS_SIZE);
    
    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(offsetLocation);
    gl.enableVertexAttribArray(uvLocation);
    gl.enableVertexAttribArray(brightnessLocation);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(offsetLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 3*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(uvLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 5*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(brightnessLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 7*BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, sprites.length*6, GL.UNSIGNED_SHORT, 0);
  }
}

class Sprite {
  GL.Texture texture;
  Vector3 pos;
  double xOffs, yOffs;
  double w, h;
  double u, v;
  Sector sector;
  
//  Float32List data = new Float32List(Sprites.FLOATS_PER_VERTEX*4);
  
  Sprite(this.texture, this.sector, this.pos, int xOffs, int yOffs, int w, int h, int u, int v) {
    this.xOffs = xOffs.toDouble();
    this.yOffs = yOffs.toDouble();
    this.w = w.toDouble();
    this.h = h.toDouble();
    this.u = u.toDouble();
    this.v = v.toDouble();
  }
  
  void set(Float32List data, int offset) {
    double br = sector.lightLevel/255.0;
    data.setAll(offset, [
        pos.x, pos.y, pos.z, xOffs+0, -yOffs+0, u+0, v+0, br,
        pos.x, pos.y, pos.z, xOffs+w, -yOffs+0, u+w, v+0, br,
        pos.x, pos.y, pos.z, xOffs+w, -yOffs-h, u+w, v+h, br,
        pos.x, pos.y, pos.z, xOffs+0, -yOffs-h, u+0, v+h, br,
    ]);
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
    double u = w/512;
    double v = h/512;
    vertexData.setAll(0, [
                              0.0, 0.0, 0.0,   v,
                              0.0,   h, 0.0, 0.0,
                                w,   h,   u, 0.0,
                                w, 0.0,   u,   v,
                         ]);
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData);
    
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    
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
    double uo = playerRot*1.0/(PI*2);
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
