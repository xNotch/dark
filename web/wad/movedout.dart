/*    
    int maxFlats = (TEXTURE_ATLAS_SIZE~/64)*(TEXTURE_ATLAS_SIZE~/64);
    if (flatMap.length > maxFlats) {
      throw "Too many flats, won't fit in a single atlas.";
    }

    WAD_Image skyFlat = new WAD_Image.empty("_sky_", 64,  64);

    ImageAtlas flatImageAtlas = new ImageAtlas(TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE);
    flatImageAtlas.insert(skyFlat);
    flatMap.values.forEach((flat) => flatImageAtlas.insert(flat)); 
    flatImageAtlas.render();
    flatMap["_sky_"] = skyFlat;
    

    
    
    void readAllSpriteTextures() {
      List<ImageAtlas> imageAtlases = new List<ImageAtlas>();

      List<WAD_Image> toInsert = new List<WAD_Image>.from(spriteMap.values);
      toInsert.sort((i0, i1)=>(i1.width*i1.height)-(i0.width*i0.height));
      do {
        print("New image atlas");
        ImageAtlas imageAtlas = new ImageAtlas(TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE);
        for (int i=0; i<toInsert.length; i++) {
          if (imageAtlas.insert(toInsert[i])) {
            toInsert.removeAt(i--);
          }
        }
        imageAtlas.render();
        addSpriteMap(imageAtlas.texture);
        imageAtlases.add(imageAtlas);
      } while (toInsert.length>0);
      
      
      spriteList.forEach((sprite) {
        SpriteTemplate.addFrameFromLump(sprite.name, sprite);
      });
      print("Sprite atlas count: ${imageAtlases.length}");
    }
    
    
    void readAllWallTextures() {
      List<ImageAtlas> imageAtlases = new List<ImageAtlas>();
      
      List<WAD_Image> toInsert = new List<WAD_Image>();
      if (header.lumpInfoMap.containsKey("TEXTURE1")) readWallTextures(toInsert, header.lumpInfoMap["TEXTURE1"].getByteData(data));
      if (header.lumpInfoMap.containsKey("TEXTURE2")) readWallTextures(toInsert, header.lumpInfoMap["TEXTURE2"].getByteData(data));
      toInsert.sort((i0, i1)=>(i1.width*i1.height)-(i0.width*i0.height));
      print("Wall textures: ${toInsert.length}");
      
      do {
        ImageAtlas imageAtlas = new ImageAtlas(TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE);
        for (int i=0; i<toInsert.length; i++) {
          if (imageAtlas.insert(toInsert[i])) {
            toInsert.removeAt(i--);
          }
        }
        imageAtlas.render();
        addWallMap(imageAtlas.texture);

        imageAtlases.add(imageAtlas);
      } while (toInsert.length>0);
      
      print("Wall texture atlas count: ${imageAtlases.length}");
    }
    
    
    
    
    
    void load(String url, Function onDone, Function onFail) {
      var request = new HttpRequest();
      request.open("get",  url);
      request.responseType = "arraybuffer";
      request.onLoadEnd.listen((e) {
        if (request.status~/100==2) {
          parse(new ByteData.view(request.response as ByteBuffer));
          onDone();
        } else {
          onFail();
        }
      });
      request.send("");
    }


    
    
    
    
    
    void getBlockCellsRadius(double x, double y, double radius, List<BlockCell> result) {
      getBlockCells(x-radius, y-radius, x+radius, y+radius, result);
    }
    
    BlockCell getBlockCell(double xp, double yp) {
      int xc = (xp.floor()-x)~/128;
      int yc = (yp.floor()-y)~/128;
      if (xc<0 || yc<0 || xc>=width || yc>=height) return null;
      return blockCells[xc+yc*width];
    }

    void getBlockCells(double x0, double y0, double x1, double y1, List<BlockCell> result) {
      result.clear();
      int xc0 = (x0.floor()-x)~/128;
      int yc0 = (y0.floor()-y)~/128;
      int xc1 = (x1.floor()-x)~/128;
      int yc1 = (y1.floor()-y)~/128;
      if (xc0<0) xc0 = 0;
      if (yc0<0) yc0 = 0;
      if (xc1>=width) xc1 = width-1;
      if (yc1>=height) yc1 = height-1;
      for (int y=yc0; y<=yc1; y++) {
        for (int x=xc0; x<=xc1; x++) {
          result.add(blockCells[x+y*width]);
        }
      }
    }
*/