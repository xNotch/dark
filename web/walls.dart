part of Dark;

class Floors {
  static const int BYTES_PER_FLOAT = 4;

  // x, y, z        0 + 3 = 3
  // subSectorId    3 + 1 = 4
  // uo, vo         4 + 2 = 6
  // br             6 + 1 = 7

  static const int FLOATS_PER_VERTEX = 7;
  static const int MAX_VERICES = 65536;
  static const int MAX_SPRITES = MAX_VERICES ~/ 3;

  GL.Buffer vertexBuffer, indexBuffer;

/*  int posLocation;
  int texOffsLocation;
  int brightnessLocation;

  GL.UniformLocation modelMatrixLocation;
  GL.UniformLocation projectionMatrixLocation;
  GL.UniformLocation viewMatrixLocation;
  GL.UniformLocation texAtlasSizeLocation;*/
  
  Float32List vertexData = new Float32List(MAX_VERICES * FLOATS_PER_VERTEX);

//  Floors(this.shader, this.texture, this.sectorDepthRender) {
  Floors() {
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);

    Int16List indexData = new Int16List(MAX_SPRITES * 3);
    for (int i = 0; i < MAX_SPRITES; i++) {
      int offs = i * 3;
      indexData.setAll(i * 3, [offs + 0, offs + 1, offs + 2]);
    }

    indexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(GL.ELEMENT_ARRAY_BUFFER, indexData, GL.STATIC_DRAW);

    //shader.use();
/*  posLocation = gl.getAttribLocation(shader.program, "a_pos");
    texOffsLocation = gl.getAttribLocation(shader.program, "a_texOffs");
    brightnessLocation = gl.getAttribLocation(shader.program, "a_brightness");

    modelMatrixLocation = gl.getUniformLocation(shader.program, "u_modelMatrix");
    viewMatrixLocation = gl.getUniformLocation(shader.program, "u_viewMatrix");
    projectionMatrixLocation = gl.getUniformLocation(shader.program, "u_projectionMatrix");
    texAtlasSizeLocation = gl.getUniformLocation(shader.program, "u_texAtlasSize");*/
  }

  int pp = 0;
  void buildData(List<Segment> visibleSegs, Vector3 pos) {
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);

    int ip = 0;
    pp = 0;

    double xSkyTexOffs = resources.flats["_sky_"].xAtlasPos.toDouble();
    double ySkyTexOffs = resources.flats["_sky_"].yAtlasPos.toDouble();

    for (int i = visibleSegs.length - 1; i >= 0; i--) {
      Segment ss = visibleSegs[i];
      double floor = ss.sector.floorHeight.toDouble();
      double ceiling = ss.sector.ceilingHeight.toDouble();

      double br = ss.sector.lightLevel;
      if (invulnerable) br = 1.0;

      double fromx = ss.x0;
      double fromy = ss.y0;
      double tox = ss.x1;
      double toy = ss.y1;

      double dd = 0.0;
      if (ss.backSector == null) {
        double xTexOffs = 0.0;
        double yTexOffs = 0.0;

        vertexData.setAll(pp * FLOATS_PER_VERTEX, [
            tox, ceiling, toy, dd, xTexOffs, yTexOffs, 1.0,
            fromx, ceiling, fromy, dd, xTexOffs, yTexOffs, 1.0,
            fromx, floor, fromy, dd, xTexOffs, yTexOffs, 1.0,
            
            tox, ceiling, toy, dd, xTexOffs, yTexOffs, 1.0,
            fromx, floor, fromy, dd, xTexOffs, yTexOffs, 1.0,
            tox, floor, toy, dd, xTexOffs, yTexOffs, 1.0]);
        
        pp+=6;
      } else {
        if (ss.backSector.floorHeight > ss.sector.floorHeight) {
          double xTexOffs = 0.0;
          double yTexOffs = 0.0;
          if (ss.backSector!=null && ss.backSector.floorTexture.isSky) {
             xTexOffs = xSkyTexOffs;
             yTexOffs = ySkyTexOffs;
           }

          double backFloor = ss.backSector.floorHeight.toDouble();

          vertexData.setAll(pp * FLOATS_PER_VERTEX, [
              tox, backFloor, toy, dd, xTexOffs, yTexOffs, 1.0,
              fromx, backFloor, fromy, dd, xTexOffs, yTexOffs, 1.0,
              fromx, floor, fromy, dd, xTexOffs, yTexOffs, 1.0,
        
              tox, backFloor, toy, dd, xTexOffs, yTexOffs, 1.0,
              fromx, floor, fromy, dd, xTexOffs, yTexOffs, 1.0,
              tox, floor, toy, dd, xTexOffs, yTexOffs, 1.0]);
          
          pp+=6;
        }
        if (ss.backSector.ceilingHeight < ss.sector.ceilingHeight) {
          double xTexOffs = 0.0;
          double yTexOffs = 0.0;
          if (ss.backSector!=null && ss.backSector.ceilingTexture.isSky) {
            xTexOffs = xSkyTexOffs;
            yTexOffs = ySkyTexOffs;
          }
          if (ss.backSector!=null && ss.backSector.ceilingTexture.isSky)
          {
          } else {
            double backCeiling = ss.backSector.ceilingHeight.toDouble();
            vertexData.setAll(pp * FLOATS_PER_VERTEX, [
                tox, ceiling, toy, dd, xTexOffs, yTexOffs, 1.0,
                fromx, ceiling, fromy, dd, xTexOffs, yTexOffs, 1.0,
                fromx, backCeiling, fromy, dd, xTexOffs, yTexOffs, 1.0,
      
                tox, ceiling, toy, dd, xTexOffs, yTexOffs, 1.0,
                fromx, backCeiling, fromy, dd, xTexOffs, yTexOffs, 1.0,
                tox, backCeiling, toy, dd, xTexOffs, yTexOffs, 1.0]);
            
            pp+=6;
          }
        }
      }
      if (floor < pos.y) {
        double xTexOffs = ss.sector.floorTexture.xAtlasPos;
        double yTexOffs = ss.sector.floorTexture.yAtlasPos;
        double sbr = br;
        if (ss.sector.floorTexture.isSky) {
          xTexOffs = xSkyTexOffs;
          yTexOffs = ySkyTexOffs;
          sbr = 1.0;
        } else {
          vertexData.setAll(pp * FLOATS_PER_VERTEX, [
              tox, floor, toy, dd, xTexOffs, yTexOffs, sbr,
              fromx, floor, fromy, dd, xTexOffs, yTexOffs, sbr,
              pos.x, floor, pos.z, dd, xTexOffs, yTexOffs, sbr]);
  
          pp+=3;
        }
      }
      if (ss.sector.ceilingTexture.isSky) {
        double xTexOffs = xSkyTexOffs;
        double yTexOffs = ySkyTexOffs;
        double sbr = 1.0;
        if (ss.backSector!=null && (ss.backSector.ceilingTexture=="F_SKY1" && ss.backSector.ceilingHeight>ss.sector.ceilingHeight)) {
        } else {
          vertexData.setAll(pp * FLOATS_PER_VERTEX, [
              fromx, ceiling, fromy, dd, xTexOffs, yTexOffs, sbr,
              tox, ceiling, toy, dd, xTexOffs, yTexOffs, sbr,
              tox, 100000.0, toy, dd, xTexOffs, yTexOffs, sbr,
  
              fromx, ceiling, fromy, dd, xTexOffs, yTexOffs, sbr,
              tox, 100000.0, toy, dd, xTexOffs, yTexOffs, sbr,
              fromx, 100000.0, fromy, dd, xTexOffs, yTexOffs, sbr
          ]);
          pp+=6;
        }
      } else if (ceiling > pos.y) {
        double xTexOffs = ss.sector.ceilingTexture.xAtlasPos;
        double yTexOffs = ss.sector.ceilingTexture.yAtlasPos;
        double sbr = br;
        vertexData.setAll(pp * FLOATS_PER_VERTEX, [
            fromx, ceiling, fromy, dd, xTexOffs, yTexOffs, sbr,
            tox, ceiling, toy, dd, xTexOffs, yTexOffs, sbr,
            pos.x, ceiling, pos.z, dd, xTexOffs, yTexOffs, sbr]);
        pp+=3;
      }
    }
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, pp * FLOATS_PER_VERTEX) as Float32List);
  }
  
  void render(Shader shader, GL.Texture texture) {
    shader.use();
    gl.bindTexture(GL.TEXTURE_2D, texture);

    shader.uniformMatrix4fv("u_modelMatrix", false, modelMatrix.storage);
    shader.uniformMatrix4fv("u_viewMatrix", false, viewMatrix.storage);
    shader.uniformMatrix4fv("u_projectionMatrix", false, projectionMatrix.storage);
    shader.uniform1f("u_texAtlasSize", TEXTURE_ATLAS_SIZE+0.0);

    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    
    shader.bindVertexData("a_pos", 4, 0, FLOATS_PER_VERTEX);
    shader.bindVertexData("a_texOffs", 2, 4, FLOATS_PER_VERTEX);
    shader.bindVertexData("a_brightness", 1, 6, FLOATS_PER_VERTEX);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, pp, GL.UNSIGNED_SHORT, 0);
  }


  void buildBackWallHackData(List<Segment> visibleSegs, Vector3 pos) {
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);

    pp = 0;
    int ip = 0;

    double xSkyTexOffs = -10.0;
    double ySkyTexOffs = resources.flats["_sky_"].yAtlasPos.toDouble();

    double floorDepth = 8.0;
    
    for (int i = visibleSegs.length - 1; i >= 0; i--) {
      Segment ss = visibleSegs[i];
      double dd = ss.dir-player.rot;
      double lowDist = ss.lowDistance;
      double highDist = ss.highDistance;

      double orgFloor = ss.sector.floorHeight.toDouble();
      double orgCeiling = ss.sector.ceilingHeight.toDouble();
      double floor = -10000000.0;
      double ceiling = 10000000.0;

      double br = ss.sector.lightLevel;
      if (invulnerable) br = 1.0;

      double fromx = ss.x0;
      double fromy = ss.y0;
      double tox = ss.x1;
      double toy = ss.y1;

      if (ss.backSector == null || ss.backSector.floorHeight >= ss.backSector.ceilingHeight) {
        vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, ceiling, toy, dd, lowDist, highDist]);
        vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, ceiling, fromy, dd, lowDist, highDist]);
        vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, floor, fromy, dd, lowDist, highDist]);

        vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, ceiling, toy, dd, lowDist, highDist]);
        vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, floor, fromy, dd, lowDist, highDist]);
        vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, floor, toy, dd, lowDist, highDist]);
      } else {
        if (ss.backSector.floorHeight > ss.sector.floorHeight) {
          double backFloor = ss.backSector.floorHeight.toDouble();

          if (ss.backSector.floorHeight > pos.y) {
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, backFloor, toy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, backFloor, fromy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, floor, fromy, dd, lowDist, highDist]);

            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, backFloor, toy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, floor, fromy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, floor, toy, dd, lowDist, highDist]);
          }
        }
        if (ss.backSector.ceilingHeight < ss.sector.ceilingHeight) {
          double backCeiling = ss.backSector.ceilingHeight.toDouble();

          if (ss.backSector.ceilingHeight < pos.y) {
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, ceiling, toy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, ceiling, fromy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, backCeiling, fromy, dd, lowDist, highDist]);

            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, ceiling, toy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, backCeiling, fromy, dd, lowDist, highDist]);
            vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, backCeiling, toy, dd, lowDist, highDist]);
          }
        }
      }
      if (orgFloor < pos.y) {
        if (ss.backSector != null && ss.backSector.floorHeight < ss.sector.floorHeight) {
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, orgFloor, toy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, orgFloor, fromy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, floor, fromy, dd, lowDist, highDist]);

          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, orgFloor, toy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, floor, fromy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, floor, toy, dd, lowDist, highDist]);
        }
        if (false) { 
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, orgFloor-floorDepth, toy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, orgFloor-floorDepth, fromy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [pos.x, orgFloor-floorDepth, pos.z, dd, lowDist, highDist]);
        }
      }
      if (orgCeiling > pos.y) {
        if (ss.backSector != null && ss.backSector.ceilingHeight > ss.sector.ceilingHeight) {
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, orgCeiling, fromy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, orgCeiling, toy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, ceiling, toy, dd, lowDist, highDist]);

          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, orgCeiling, fromy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, ceiling, toy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, ceiling, fromy, dd, lowDist, highDist]);
        }
        if (false) {
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [fromx, orgCeiling, fromy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [tox, orgCeiling, toy, dd, lowDist, highDist]);
          vertexData.setAll((pp++) * FLOATS_PER_VERTEX, [pos.x, orgCeiling+floorDepth, pos.z, dd, lowDist, highDist]);
        }
      }
    }

    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, pp * FLOATS_PER_VERTEX) as Float32List);
  }
}

typedef bool InsertWallFunction(Float32List, int); 

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
  static const int MAX_SPRITES = MAX_VERICES ~/ 4;

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

  Float32List vertexData = new Float32List(MAX_VERICES * FLOATS_PER_VERTEX);
  int wallCount = 0;

  Walls(this.shader, this.texture) {
    vertexBuffer = gl.createBuffer();
    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    gl.bufferDataTyped(GL.ARRAY_BUFFER, vertexData, GL.DYNAMIC_DRAW);

    Int16List indexData = new Int16List(MAX_SPRITES * 6);
    for (int i = 0; i < MAX_SPRITES; i++) {
      int offs = i * 4;
      indexData.setAll(i * 6, [offs + 0, offs + 1, offs + 2, offs + 0, offs + 2, offs + 3]);
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
    texAtlasSizeLocation = gl.getUniformLocation(shader.program, "u_texAtlasSize");
  }

  void clear() {
    wallCount = 0;
  }

  void insertWall(InsertWallFunction wallBuilderFunc) {
    if (wallBuilderFunc(vertexData, wallCount * FLOATS_PER_VERTEX * 4)) {
      wallCount++;
    }
    /*    double br = sector.lightLevel/255.0;
    
    vertexData.setAll(spriteCount*FLOATS_PER_VERTEX*4, [
        p.x, p.y, p.z, str.xOffs0, str.yOffs0, str.u0, str.v0, br,
        p.x, p.y, p.z, str.xOffs1, str.yOffs0, str.u1, str.v0, br,
        p.x, p.y, p.z, str.xOffs1, str.yOffs1, str.u1, str.v1, br,
        p.x, p.y, p.z, str.xOffs0, str.yOffs1, str.u0, str.v1, br,
    ]);*/

//    wallCount++;
  }

  void render() {
    shader.use();
    gl.bindTexture(GL.TEXTURE_2D, texture);

    gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
    int toReplace = wallCount;
    /*    int pp = 0;
    for (int i=0; i<toReplace; i++) {
      if (walls[i].set(vertexData, pp*FLOATS_PER_VERTEX*4)) {
        pp++;
      }
    }*/
    gl.bufferSubDataTyped(GL.ARRAY_BUFFER, 0, vertexData.sublist(0, wallCount * FLOATS_PER_VERTEX * 4) as Float32List);

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
    gl.vertexAttribPointer(posLocation, 3, GL.FLOAT, false, FLOATS_PER_VERTEX * BYTES_PER_FLOAT, 0 * BYTES_PER_FLOAT);
    gl.vertexAttribPointer(uvLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX * BYTES_PER_FLOAT, 3 * BYTES_PER_FLOAT);
    gl.vertexAttribPointer(texOffsLocation, 2, GL.FLOAT, false, FLOATS_PER_VERTEX * BYTES_PER_FLOAT, 5 * BYTES_PER_FLOAT);
    gl.vertexAttribPointer(texWidthLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX * BYTES_PER_FLOAT, 7 * BYTES_PER_FLOAT);
    gl.vertexAttribPointer(brightnessLocation, 1, GL.FLOAT, false, FLOATS_PER_VERTEX * BYTES_PER_FLOAT, 8 * BYTES_PER_FLOAT);

    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(GL.TRIANGLES, wallCount * 6, GL.UNSIGNED_SHORT, 0);
  }
}

const int WALL_TYPE_MIDDLE = 0;
const int WALL_TYPE_UPPER = 1;
const int WALL_TYPE_LOWER = 2;
const int WALL_TYPE_MIDDLE_TRANSPARENT = 3;

class WallRenderer {
/*  Image textureImage;
  GL.Texture texture;
  Segment seg;
  Sidedef sidedef;
  Wall linedef;
  Sector frontSector, backSector;
  Vector2 v0, v1; // Vertices
  int type;*/

  //  Float32List data = new Float32List(Sprites.FLOATS_PER_VERTEX*4);

  static void render(Segment seg, int type) {
    Wall linedef = seg.wall;
    Sidedef sidedef = seg.sidedef;
    Sector frontSector = seg.sector;
    Sector backSector = seg.backSector;
    Vector2 v0 = seg.startVertex;
    Vector2 v1 = seg.endVertex;

    Image textureImage;
    GL.Texture texture;

    if (type == WALL_TYPE_MIDDLE) textureImage = sidedef.middleTexture;
    if (type == WALL_TYPE_MIDDLE_TRANSPARENT) textureImage = sidedef.middleTexture;
    if (type == WALL_TYPE_UPPER) textureImage = sidedef.upperTexture;
    if (type == WALL_TYPE_LOWER) textureImage = sidedef.lowerTexture;

    if (textureImage != null) texture = textureImage.imageAtlas.texture;
    if (texture==null) return;
    
    InsertWallFunction iwf = (Float32List data, int offset) {
      double floor, ceiling;
      if (type == WALL_TYPE_MIDDLE || type == WALL_TYPE_MIDDLE_TRANSPARENT) {
        floor = frontSector.floorHeight;
        ceiling = frontSector.ceilingHeight;
        if (backSector!=null) {
          if (backSector.floorHeight>floor) floor = backSector.floorHeight;
          if (backSector.ceilingHeight<ceiling) ceiling = backSector.ceilingHeight;
        }
      }
      if (type == WALL_TYPE_UPPER) {
        floor = backSector.ceilingHeight;
        ceiling = frontSector.ceilingHeight;
      }
      if (type == WALL_TYPE_LOWER) {
        floor = frontSector.floorHeight;
        ceiling = backSector.floorHeight;
      }
      if (floor >= ceiling) return false;
  
      double texPosOffset = seg.offset+0.0;
      if (seg.wall.data.type == 0x30) { // Special type for scrolling textures
        texPosOffset += textureScrollOffset%textureImage.width;
      }
  
      double texCoordx0 = texPosOffset + sidedef.xTextureOffs;
      double texCoordx1 = texCoordx0 + seg.length;
      double texCoordy0;
      double texCoordy1;
  
      // Check if the texture is pegged up or down
      bool pegTextureDown = false;
      if (type == WALL_TYPE_UPPER) {
        if (!linedef.data.upperUnpegged) pegTextureDown = true;
      } else {
        if (linedef.data.lowerUnpegged) pegTextureDown = true;
      }
  
      if (type == WALL_TYPE_MIDDLE_TRANSPARENT) {
        // Middle transparent walls are only rendered one patch high
        double newFloor, newCeiling;
        texCoordy0 = 0.0;
        texCoordy1 = textureImage.height + 0.0;
        if (pegTextureDown) {
          newFloor = floor + sidedef.yTextureOffs;
          newCeiling = newFloor + textureImage.height;
        } else {
          newCeiling = ceiling + sidedef.yTextureOffs;
          newFloor = newCeiling - textureImage.height;
        }
  
        // Clamp within the sector height
        if (newCeiling > ceiling) {
          texCoordy0 += newCeiling - ceiling;
          newCeiling = ceiling;
        }
        if (newFloor < floor) {
          texCoordy1 += newFloor - floor;
          newFloor = floor;
        }
        floor = newFloor;
        ceiling = newCeiling;
      } else if (pegTextureDown) {
        // Textures pegged down have lower texture edge along bottom of sector
        texCoordy1 = sidedef.yTextureOffs + textureImage.height + 0.0;
        if (type == WALL_TYPE_LOWER) {
          // Except lower textures that have a special case for some reason
          texCoordy1 = sidedef.yTextureOffs + (frontSector.ceilingHeight - frontSector.floorHeight) - textureImage.height + 0.0;
        }
        texCoordy0 = texCoordy1 - (ceiling - floor) + 0.0;
      } else {
        // Textures pegged up have upper texture edge along top of sector
        texCoordy0 = sidedef.yTextureOffs + 0.0;
        texCoordy1 = texCoordy0 + (ceiling - floor) + 0.0;
      }
  
      double texCoordxOffs = textureImage.xAtlasPos.toDouble();
      double texCoordyOffs = textureImage.yAtlasPos.toDouble();
      double texWidth = textureImage.width.toDouble();
      double br = frontSector.lightLevel*seg.brightness;
      if (invulnerable) br = 1.0;
  
      data.setAll(offset, [v1.x, ceiling.toDouble(), v1.y, texCoordx1, texCoordy0, texCoordxOffs, texCoordyOffs, texWidth, br, v0.x, ceiling.toDouble(), v0.y, texCoordx0, texCoordy0, texCoordxOffs, texCoordyOffs, texWidth, br, v0.x, floor.toDouble(), v0.y, texCoordx0, texCoordy1, texCoordxOffs, texCoordyOffs, texWidth, br, v1.x, floor.toDouble(), v1.y, texCoordx1, texCoordy1, texCoordxOffs, texCoordyOffs, texWidth, br,]);
      return true;
    };

    if (type==WALL_TYPE_MIDDLE_TRANSPARENT) {
      renderers.addMiddleTransparentWall(texture, iwf);
    } else {
      renderers.addWall(texture, iwf);
    }
  }

  static void addWallsForSubSector(SubSector subSector) {
    subSector.segs.forEach((seg) => WallRenderer.addWallsForSeg(seg));
  }

  static void addWallsForSeg(Segment seg) {
//    Level level = wadFile.level;

    if (!seg.wall.data.twoSided) {
      WallRenderer.render(seg, WALL_TYPE_MIDDLE);
    }

    if (seg.backSector != null) {
      if (seg.sidedef.middleTexture != "-") WallRenderer.render(seg, WALL_TYPE_MIDDLE_TRANSPARENT);

      if (seg.sidedef.upperTexture != "-" && !seg.backSector.ceilingTexture.isSky) WallRenderer.render(seg, WALL_TYPE_UPPER);
      if (seg.sidedef.lowerTexture != "-" && !seg.backSector.floorTexture.isSky) WallRenderer.render(seg, WALL_TYPE_LOWER);
    }
  }
}