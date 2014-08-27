part of Dark;

class Floors {
  static const int BYTES_PER_FLOAT = 4;

  // x, y, z        0 + 3 = 3
  // uo, vo         3 + 2 = 5
  // br             5 + 1 = 6
  
  static const int FLOATS_PER_VERTEX = 6;
  static const int MAX_VERICES = 65536;
  static const int MAX_SPRITES = MAX_VERICES~/3;

  Shader shader;
  
  GL.Texture texture;
  GL.Buffer vertexBuffer, indexBuffer;
  
  int posLocation;
  int texOffsLocation;
  int brightnessLocation;
  
  GL.UniformLocation modelMatrixLocation;    
  GL.UniformLocation projectionMatrixLocation;    
  GL.UniformLocation viewMatrixLocation;
  GL.UniformLocation texAtlasSizeLocation;
  
  Float32List vertexData = new Float32List(MAX_VERICES*FLOATS_PER_VERTEX);
  
  Floors(this.shader, this.texture) {
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);
    
    Int16List indexData = new Int16List(MAX_SPRITES*3);
    for (int i=0; i<MAX_SPRITES; i++) {
      int offs = i*3;
      indexData.setAll(i*3, [offs+0, offs+1, offs+2]);
    }
    
    indexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);
    
    shader.use();
    posLocation = gl.getAttribLocation(shader.program, "a_pos");
    texOffsLocation = gl.getAttribLocation(shader.program, "a_texOffs");
    brightnessLocation = gl.getAttribLocation(shader.program, "a_brightness");

    modelMatrixLocation = gl.getUniformLocation(shader.program, "u_modelMatrix");
    viewMatrixLocation = gl.getUniformLocation(shader.program, "u_viewMatrix");
    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
    texAtlasSizeLocation  = gl.getUniformLocation(shader.program, "u_texAtlasSize");
  }
  
  void render(BSP bsp, Vector3 pos) {
    shader.use();
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    List<SubSector> subSectors = bsp.findSortedSubSectors(pos.xz);
    
    int pp = 0;
    int ip = 0;
    
    double xSkyTexOffs = flatMap["_sky_"].xAtlasPos.toDouble();
    double ySkyTexOffs = flatMap["_sky_"].yAtlasPos.toDouble();

    for (int i=0; i<subSectors.length; i++) {
      SubSector ss = subSectors[i];
      double floor = ss.sector.floorHeight.toDouble();
      double ceiling = ss.sector.ceilingHeight.toDouble();
      
      double br = ss.sector.lightLevel/255.0;

      for (int j=0; j<ss.segCount; j++) {
        Vector2 from = ss.segFrom[j]; 
        Vector2 to = ss.segTo[j];
        if (ss.backSectors[j]==null) {
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, ceiling, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);

          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, floor, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
        } else {
          if (ss.backSectors[j].floorHeight>ss.sector.floorHeight) {
            double backFloor = ss.backSectors[j].floorHeight.toDouble();
            
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, backFloor, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, backFloor, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, backFloor, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, floor, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
          }
          if (ss.backSectors[j].ceilingHeight<ss.sector.ceilingHeight) {
            double backCeiling = ss.backSectors[j].ceilingHeight.toDouble();
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, ceiling, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, backCeiling, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
  
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, backCeiling, from.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, backCeiling, to.y, xSkyTexOffs, ySkyTexOffs, 1.0]);
          }
        }
      }
      if (floor<pos.y) {
        double xTexOffs = flatMap[ss.sector.floorTexture].xAtlasPos.toDouble();
        double yTexOffs = flatMap[ss.sector.floorTexture].yAtlasPos.toDouble();
        double sbr = br;
        if (ss.sector.floorTexture=="F_SKY1") {
          xTexOffs = flatMap["_sky_"].xAtlasPos.toDouble();
          yTexOffs = flatMap["_sky_"].yAtlasPos.toDouble();
          sbr = 1.0;
        }
        for (int j=0; j<ss.segCount; j++) {
          Vector2 from = ss.segFrom[j]; 
          Vector2 to = ss.segTo[j];
          
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, floor, to.y, xTexOffs, yTexOffs, sbr]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y, xTexOffs, yTexOffs, sbr]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [pos.x, floor, pos.z, xTexOffs, yTexOffs, sbr]);
        }
      }
      if (ceiling>pos.y) {
        double xTexOffs = flatMap[ss.sector.ceilingTexture].xAtlasPos.toDouble();
        double yTexOffs = flatMap[ss.sector.ceilingTexture].yAtlasPos.toDouble();
        double sbr = br;
        if (ss.sector.ceilingTexture=="F_SKY1") {
          xTexOffs = flatMap["_sky_"].xAtlasPos.toDouble();
          yTexOffs = flatMap["_sky_"].yAtlasPos.toDouble();
          sbr = 1.0;
        }
        for (int j=0; j<ss.segCount; j++) {
          Vector2 from = ss.segFrom[j]; 
          Vector2 to = ss.segTo[j];
          
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, ceiling, from.y, xTexOffs, yTexOffs, sbr]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y, xTexOffs, yTexOffs, sbr]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [pos.x, ceiling, pos.z, xTexOffs, yTexOffs, sbr]);
        }
      }                 
    }
    
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, pp*FLOATS_PER_VERTEX) as Float32List);
    
    gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
    gl.uniformMatrix4fv(viewMatrixLocation, false, viewMatrix.storage);
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    gl.uniform1f(texAtlasSizeLocation, TEXTURE_ATLAS_SIZE);

    
    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(texOffsLocation);
    gl.enableVertexAttribArray(brightnessLocation);
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(texOffsLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 3*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(brightnessLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 5*BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, pp, GL.UNSIGNED_SHORT, 0);
  }

  
  void renderBackWallHack(BSP bsp, Vector3 pos) {
    shader.use();
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    List<SubSector> subSectors = bsp.findSortedSubSectors(pos.xz);
    
    int pp = 0;
    int ip = 0;
    
    double xSkyTexOffs = flatMap["_sky_"].xAtlasPos.toDouble();
    double ySkyTexOffs = flatMap["_sky_"].yAtlasPos.toDouble();

    for (int i=0; i<subSectors.length; i++) {
      SubSector ss = subSectors[i];
      double orgFloor = ss.sector.floorHeight.toDouble();
      double orgCeiling = ss.sector.ceilingHeight.toDouble();
      double floor = -10000000.0;
      double ceiling = 10000000.0;
      
      double br = ss.sector.lightLevel/255.0;

      for (int j=0; j<ss.segCount; j++) {
        Vector2 from = ss.segFrom[j]; 
        Vector2 to = ss.segTo[j];
        if (ss.backSectors[j]==null || ss.backSectors[j].floorHeight>=ss.backSectors[j].ceilingHeight) {
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, ceiling, from.y]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y]);

          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y]);
          vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, floor, to.y]);
        } else {
          if (ss.backSectors[j].floorHeight>ss.sector.floorHeight) {
            double backFloor = ss.backSectors[j].floorHeight.toDouble();
            
            if (ss.backSectors[j].floorHeight>pos.y) {
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, backFloor, to.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, backFloor, from.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y]);
              
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, backFloor, to.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, floor, to.y]);              
            } 
          }
          if (ss.backSectors[j].ceilingHeight<ss.sector.ceilingHeight) {
            double backCeiling = ss.backSectors[j].ceilingHeight.toDouble();
            
            if (ss.backSectors[j].ceilingHeight<pos.y) {
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, ceiling, from.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, backCeiling, from.y]);
    
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, backCeiling, from.y]);
              vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, backCeiling, to.y]);
            } 
          }
        }
      }
      if (orgFloor<pos.y) {
        for (int j=0; j<ss.segCount; j++) {
          Vector2 from = ss.segFrom[j]; 
          Vector2 to = ss.segTo[j];
          if (ss.backSectors[j]!=null && ss.backSectors[j].floorHeight<ss.sector.floorHeight) {
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, orgFloor, to.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, orgFloor, from.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y]);

            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, orgFloor, to.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, floor, from.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, floor, to.y]);
          }
        }
      }
      if (orgCeiling>pos.y) {
        for (int j=0; j<ss.segCount; j++) {
          Vector2 from = ss.segFrom[j]; 
          Vector2 to = ss.segTo[j];
          if (ss.backSectors[j]!=null && ss.backSectors[j].ceilingHeight>ss.sector.ceilingHeight) {
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, orgCeiling, from.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, orgCeiling, to.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y]);

            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, orgCeiling, from.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [to.x, ceiling, to.y]);
            vertexData.setAll((pp++)*FLOATS_PER_VERTEX, [from.x, ceiling, from.y]);
          }
        }
      }         
    }
    
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, pp*FLOATS_PER_VERTEX) as Float32List);
    
    gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
    gl.uniformMatrix4fv(viewMatrixLocation, false, viewMatrix.storage);
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    gl.uniform1f(texAtlasSizeLocation, TEXTURE_ATLAS_SIZE);

    
    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(texOffsLocation);
    gl.enableVertexAttribArray(brightnessLocation);
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(texOffsLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 3*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(brightnessLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 5*BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, pp, GL.UNSIGNED_SHORT, 0);
  }  
}

class Walls {
  // Vertex data:

  // x, y, z      0 + 3 = 3  // Pos
  // u, v         3 + 2 = 5  // UV
  // uo, vo       5 + 2 = 7  // Offset in atlas
  // us           7 + 1 = 8  // Width of image in atlas (Height 128 is implied)
  // br           8 + 1 = 9  // Brightness
  
  static const int BYTES_PER_FLOAT = 4;

  static const int FLOATS_PER_VERTEX = 9;
  static const int MAX_VERICES = 65536;
  static const int MAX_SPRITES = MAX_VERICES~/4;
  
  List<Wall> walls = new List<Wall>();
  Shader shader;
  
  GL.Texture texture;
  GL.Buffer vertexBuffer, indexBuffer;
  
  int posLocation;
  int uvLocation;
  int texOffsLocation;
  int texWidthLocation;
  int brightnessLocation;
  
  GL.UniformLocation modelMatrixLocation;    
  GL.UniformLocation projectionMatrixLocation;    
  GL.UniformLocation viewMatrixLocation;
  GL.UniformLocation texAtlasSizeLocation;
  
  Float32List vertexData = new Float32List(MAX_VERICES*FLOATS_PER_VERTEX);
  
  Walls(this.shader, this.texture) {
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
    uvLocation = gl.getAttribLocation(shader.program, "a_uv");
    texOffsLocation = gl.getAttribLocation(shader.program, "a_texOffs");
    texWidthLocation = gl.getAttribLocation(shader.program, "a_texWidth");
    brightnessLocation = gl.getAttribLocation(shader.program, "a_brightness");

    modelMatrixLocation = gl.getUniformLocation(shader.program, "u_modelMatrix");
    viewMatrixLocation = gl.getUniformLocation(shader.program, "u_viewMatrix");
    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
    texAtlasSizeLocation  = gl.getUniformLocation(shader.program, "u_texAtlasSize");
  }
  
  void addWall(Wall wall) {
    walls.add(wall);
  }
  
  void render() {
    shader.use();
    gl.bindTexture(GL.TEXTURE_2D, texture);
    
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    int toReplace = walls.length;
    if (toReplace>MAX_SPRITES) toReplace=MAX_SPRITES;
    int pp = 0;
    for (int i=0; i<toReplace; i++) {
      if (walls[i].set(vertexData, pp*FLOATS_PER_VERTEX*4)) {
        pp++;
      }
    }
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, pp*FLOATS_PER_VERTEX*4) as Float32List);
    
    gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
    gl.uniformMatrix4fv(viewMatrixLocation, false, viewMatrix.storage);
    gl.uniformMatrix4fv(projectionMatrixLocation, false, projectionMatrix.storage);
    gl.uniform1f(texAtlasSizeLocation, TEXTURE_ATLAS_SIZE);

    gl.enableVertexAttribArray(posLocation);
    gl.enableVertexAttribArray(uvLocation);
    gl.enableVertexAttribArray(texOffsLocation);
    gl.enableVertexAttribArray(texWidthLocation);
    gl.enableVertexAttribArray(brightnessLocation);
        
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 0*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(uvLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 3*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(texOffsLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 5*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(texWidthLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 7*BYTES_PER_FLOAT);
    gl.vertexAttribPointer(brightnessLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX*BYTES_PER_FLOAT, 8*BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, pp*6, GL.UNSIGNED_SHORT, 0);
  }
}

const int WALL_TYPE_MIDDLE = 0;
const int WALL_TYPE_UPPER = 1;
const int WALL_TYPE_LOWER = 2;
const int WALL_TYPE_MIDDLE_TRANSPARENT = 3;

class Wall {
  WAD_Image textureImage;
  GL.Texture texture;
  Seg seg;
  Sidedef sidedef;
  Linedef linedef;
  Sector frontSector, backSector;
  Vector2 v0, v1; // Vertices
  int type;
  
//  Float32List data = new Float32List(Sprites.FLOATS_PER_VERTEX*4);
  
  Wall(this.seg, this.linedef, this.sidedef, this.frontSector, this.backSector, this.v0, this.v1, this.type) {
    if (type==WALL_TYPE_MIDDLE) textureImage = wallTextureMap[sidedef.middleTexture];
    if (type==WALL_TYPE_MIDDLE_TRANSPARENT) textureImage = wallTextureMap[sidedef.middleTexture];
    if (type==WALL_TYPE_UPPER) textureImage = wallTextureMap[sidedef.upperTexture];
    if (type==WALL_TYPE_LOWER) textureImage = wallTextureMap[sidedef.lowerTexture];
    if (textureImage!=null) texture = textureImage.imageAtlas.texture;
  }
  
  bool set(Float32List data, int offset) {
    int floor, ceiling;
    if (type==WALL_TYPE_MIDDLE) {floor = frontSector.floorHeight; ceiling = frontSector.ceilingHeight;}
    if (type==WALL_TYPE_MIDDLE_TRANSPARENT) {floor = frontSector.floorHeight; ceiling = frontSector.ceilingHeight;}
    if (type==WALL_TYPE_UPPER) {floor = backSector.ceilingHeight; ceiling = frontSector.ceilingHeight;}
    if (type==WALL_TYPE_LOWER) {floor = frontSector.floorHeight; ceiling = backSector.floorHeight;}
    if (floor>=ceiling) return false;

    double texCoordx0 = seg.offset+sidedef.xTextureOffs+0.0;
    double texCoordx1 = texCoordx0+v1.distanceTo(v0);
    double texCoordy0;
    double texCoordy1;
    
    // Check if the texture is pegged up or down
    bool pegTextureDown = false;
    if (type==WALL_TYPE_UPPER) {
      if (!linedef.upperUnpegged) pegTextureDown = true;
    } else {
      if (linedef.lowerUnpegged) pegTextureDown = true;
    }
    
    if (type==WALL_TYPE_MIDDLE_TRANSPARENT) {
      // Middle transparent walls are only rendered one patch high
      int newFloor, newCeiling;
      texCoordy0 = 0.0;
      texCoordy1 = textureImage.height+0.0;
      if (pegTextureDown) {
        newFloor = floor+sidedef.yTextureOffs;
        newCeiling = newFloor+textureImage.height;
      } else {
        newCeiling = ceiling+sidedef.yTextureOffs;
        newFloor = newCeiling-textureImage.height;
      }
      
      // Clamp within the sector height
      if (newCeiling>ceiling) {
        texCoordy0+=newCeiling-ceiling;
        newCeiling=ceiling;
      }
      if (newFloor<floor) {
        texCoordy1+=newFloor-floor;
        newFloor=floor;
      }
      floor = newFloor;
      ceiling = newCeiling;
    } else if (pegTextureDown) {
      // Textures pegged down have lower texture edge along bottom of sector
      texCoordy1 = sidedef.yTextureOffs+textureImage.height+0.0;
      if (type==WALL_TYPE_LOWER) {
        // Except lower textures that have a special case for some reason
        texCoordy1 = sidedef.yTextureOffs+(frontSector.ceilingHeight-frontSector.floorHeight)-textureImage.height+0.0;
      }
      texCoordy0 = texCoordy1-(ceiling-floor)+0.0;
    } else {
      // Textures pegged up have upper texture edge along top of sector
      texCoordy0 = sidedef.yTextureOffs+0.0;
      texCoordy1 = texCoordy0+(ceiling-floor)+0.0;
    }
    
    double texCoordxOffs = textureImage.xAtlasPos.toDouble();
    double texCoordyOffs = textureImage.yAtlasPos.toDouble();
    double texWidth = textureImage.width.toDouble();
    double br = frontSector.lightLevel/255.0;
    
    data.setAll(offset, [
        v1.x, ceiling.toDouble(), v1.y, texCoordx1, texCoordy0, texCoordxOffs, texCoordyOffs, texWidth, br,
        v0.x, ceiling.toDouble(), v0.y, texCoordx0, texCoordy0, texCoordxOffs, texCoordyOffs, texWidth, br,
        
        v0.x, floor.toDouble(), v0.y, texCoordx0, texCoordy1, texCoordxOffs, texCoordyOffs, texWidth, br,
        v1.x, floor.toDouble(), v1.y, texCoordx1, texCoordy1, texCoordxOffs, texCoordyOffs, texWidth, br,
    ]);
    return true;
  }
}