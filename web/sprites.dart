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
//    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
//    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, offset*BYTES_PER_FLOAT, sprite.data);
    
    gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
    gl.uniformMatrix4fv(viewMatrixLocation, false, viewMatrix.storage);
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    
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