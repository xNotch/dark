part of Dark;

HashMap<String, WAD_Image> wallTextureMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> spriteMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> patchMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> flatMap = new HashMap<String, WAD_Image>(); 

class WadFile {
  WAD_Header header;
  WAD_Playpal palette;
  ByteData data;
  
  List<WAD_Image> patchList = new List<WAD_Image>();
  List<WAD_Image> spriteList = new List<WAD_Image>();
  
  Level level;
  
  void load(String url, Function onDone) {
    var request = new HttpRequest();
    request.open("get",  url);
    request.responseType = "arraybuffer";
    request.onLoadEnd.listen((e) {
      print("${request.status}");
      print("${request.responseHeaders}");
      
      parse(new ByteData.view(request.response as ByteBuffer));
      onDone();
    });
    request.send("");
  }
  
  void parse(ByteData data) {
    this.data = data;
    header = new WAD_Header.parse(data);
    palette = new WAD_Playpal.parse(header.lumpInfoMap["PLAYPAL"].getByteData(data));

    bool foundSprites = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "S_START") foundSprites = true;
      else if (lump.name == "S_END") foundSprites = false;
      else if (foundSprites) {
        WAD_Image sprite = new WAD_Image.parse(lump.getByteData(data), palette.palettes[0]);
        spriteMap[lump.name] = sprite;
        spriteList.add(sprite);
      }
    }
    
    bool foundFlats = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "F_START") foundFlats = true;
      else if (lump.name == "F_END") foundFlats = false;
      else if (foundFlats) {
        if (lump.size==64*64) {
          flatMap[lump.name] = new WAD_Image.parseFlat(lump.getByteData(data), palette.palettes[0]);
        }
      }
    }
    
    int maxFlats = (TEXTURE_ATLAS_SIZE~/64)*(TEXTURE_ATLAS_SIZE~/64);
    if (flatMap.length > maxFlats) {
      throw "Too many flats, won't fit in a single atlas.";
    }
    
    
    ImageAtlas flatImageAtlas = new ImageAtlas(TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE);
    flatMap.values.forEach((flat) => flatImageAtlas.insert(flat)); 
    flatImageAtlas.render();    
    
    
    readPatches(header.lumpInfoMap["PNAMES"].getByteData(data));
    readAllWallTextures();
    readAllSpriteTextures();
    
    bool foundLevel = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "E1M1") loadLevel(lump.name, i);
    }    
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
      imageAtlases.add(imageAtlas);
    } while (toInsert.length>0);
    
    print("Wall texture atlas count: ${imageAtlases.length}");
  }
  
  void readAllSpriteTextures() {
    List<ImageAtlas> imageAtlases = new List<ImageAtlas>();

    List<WAD_Image> toInsert = new List<WAD_Image>.from(spriteList);
    toInsert.sort((i0, i1)=>(i1.width*i1.height)-(i0.width*i0.height));
    do {
      ImageAtlas imageAtlas = new ImageAtlas(TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE);
      for (int i=0; i<toInsert.length; i++) {
        if (imageAtlas.insert(toInsert[i])) {
          toInsert.removeAt(i--);
        }
      }
      imageAtlas.render();
      imageAtlases.add(imageAtlas);
    } while (toInsert.length>0);
    
    
    print("Sprite atlas count: ${imageAtlases.length}");
  }
  
  void readPatches(ByteData data) {
    int count = data.getInt32(0, Endianness.LITTLE_ENDIAN);
    for (int i=0; i<count; i++) {
      String pname = readString(data,  4+i*8, 8);
      
      WAD_Image patch = new WAD_Image.parse(header.lumpInfoMap[pname].getByteData(data), palette.palettes[0]);
      patchMap[pname] = patch;
      patchList.add(patch);
    }
  }
  
  void readWallTextures(List<WAD_Image> list, ByteData data) {
    int count = data.getInt32(0, Endianness.LITTLE_ENDIAN);
    for (int i=0; i<count; i++) {
      int offset = data.getInt32(4+i*4, Endianness.LITTLE_ENDIAN);
      list.add(readWallTexture(new ByteData.view(data.buffer, data.offsetInBytes+offset)));
    }
  }
  
  WAD_Image readWallTexture(ByteData data) {
    String name = readString(data,  0,  8);
    // Skip 4.
    int width = data.getInt16(12, Endianness.LITTLE_ENDIAN);
    int height = data.getInt16(14, Endianness.LITTLE_ENDIAN);
    // Skip 4
    int patchCount = data.getInt16(20, Endianness.LITTLE_ENDIAN);
    
    WAD_Image wallTexture = new WAD_Image.empty(width, height);
    for (int i=0; i<patchCount; i++) {
      int xOffs = data.getInt16(22+i*10, Endianness.LITTLE_ENDIAN); 
      int yOffs = data.getInt16(24+i*10, Endianness.LITTLE_ENDIAN); 
      int patchId = data.getInt16(26+i*10, Endianness.LITTLE_ENDIAN); 
      int stepDir = data.getInt16(28+i*10, Endianness.LITTLE_ENDIAN); 
      int colorMap = data.getInt16(30+i*10, Endianness.LITTLE_ENDIAN);
      wallTexture.draw(patchList[patchId], xOffs, yOffs);
    }
    
    wallTextureMap[name] = wallTexture;
    
    return wallTexture;
  }
  
  void loadLevel(String name, int lumpIndex) {
    level = new Level();
    
    while (true) {
      LumpInfo lump = header.lumpInfos[lumpIndex++];
      if (lump.name=="VERTEXES") level.vertices = WAD_Vertexes.parse(lump, lump.getByteData(data));
      if (lump.name=="LINEDEFS") level.linedefs = Linedef.parse(lump, lump.getByteData(data));
      if (lump.name=="SIDEDEFS") level.sidedefs = Sidedef.parse(lump, lump.getByteData(data));
      if (lump.name=="SEGS") level.segs = Seg.parse(lump, lump.getByteData(data));
      if (lump.name=="SSECTORS") level.sSectors = SSector.parse(lump, lump.getByteData(data));
      if (lump.name=="SECTORS") level.sectors = Sector.parse(lump, lump.getByteData(data));
      if (lump.name=="THINGS") level.things = Thing.parse(lump, lump.getByteData(data));
      if (lump.name=="NODES") level.nodes = Node.parse(lump, lump.getByteData(data));
      if (lump.name=="E1M2") break; // TODO: Check for end of level data in some good way instead.
    }
    
    level.build(this);
  }
}

class Level {
  List<Vector2> vertices;
  List<Linedef> linedefs;
  List<Sidedef> sidedefs;
  List<Seg> segs;
  List<SSector> sSectors;
  List<Sector> sectors;
  List<Thing> things;
  List<Node> nodes;
  
  BSP bsp;
  
  void build(WadFile wadFile) {
    bsp = new BSP(this);

    for (int i=0; i<things.length; i++) {
      Thing thing = things[i];
      Vector3 spritePos = new Vector3(thing.x.toDouble(), 20.0, thing.y.toDouble());
      Sector sector = bsp.findSector(spritePos.xz);
      spritePos.y = sector.floorHeight.toDouble();
      addSprite(spriteMap["SUITA0"].createSprite(spritePos));
    }
    
    for (int i=0; i<segs.length; i++) {
      Seg seg = segs[i];
      Linedef linedef = linedefs[seg.linedef];
      Sidedef sidedef = sidedefs[seg.direction==0?linedef.rightSidedef:linedef.leftSidedef];
      Sector sector = sectors[sidedef.sector];
      
      if (!linedef.twoSided) {
        addWall(new Wall(seg, linedef, sidedef, sector, null, vertices[seg.startVertex], vertices[seg.endVertex], WALL_TYPE_MIDDLE));
      } else {
        int backSidedefId = seg.direction!=0?linedef.rightSidedef:linedef.leftSidedef;
        if (backSidedefId!=-1) {
          Sidedef backSidedef = sidedefs[backSidedefId];
          Sector backSector = sectors[backSidedef.sector];
          if (sidedef.upperTexture!="-") addWall(new Wall(seg, linedef, sidedef, sector, backSector, vertices[seg.startVertex], vertices[seg.endVertex], WALL_TYPE_UPPER));
          if (sidedef.lowerTexture!="-") addWall(new Wall(seg, linedef, sidedef, sector, backSector, vertices[seg.startVertex], vertices[seg.endVertex], WALL_TYPE_LOWER));
        }
      }
    }
  }
}

class Palette {
  List<int> r = new List<int>(256);
  List<int> g = new List<int>(256);
  List<int> b = new List<int>(256);
}

class Node {
  int x;
  int y;
  int dx;
  int dy;
  int bb0y0;
  int bb0y1;
  int bb0x0;
  int bb0x1;
  int bb1y0;
  int bb1y1;
  int bb1x0;
  int bb1x1;
  int rightChild;
  int leftChild;
  
  static List<Node> parse(LumpInfo lump, ByteData data) {
    int nodeCount = lump.size~/28;
    List<Node> nodes = new List<Node>(nodeCount);
    for (int i=0; i<nodeCount; i++) {
      Node node = nodes[i] = new Node();
      node.x = data.getInt16(i*28+0, Endianness.LITTLE_ENDIAN);
      node.y = data.getInt16(i*28+2, Endianness.LITTLE_ENDIAN);
      node.dx = data.getInt16(i*28+4, Endianness.LITTLE_ENDIAN);
      node.dy = data.getInt16(i*28+6, Endianness.LITTLE_ENDIAN);
      node.bb0y0 = data.getInt16(i*28+8, Endianness.LITTLE_ENDIAN);
      node.bb0y1 = data.getInt16(i*28+10, Endianness.LITTLE_ENDIAN);
      node.bb0x0 = data.getInt16(i*28+12, Endianness.LITTLE_ENDIAN);
      node.bb0x1 = data.getInt16(i*28+14, Endianness.LITTLE_ENDIAN);
      node.bb1y0 = data.getInt16(i*28+16, Endianness.LITTLE_ENDIAN);
      node.bb1y1 = data.getInt16(i*28+18, Endianness.LITTLE_ENDIAN);
      node.bb1x0 = data.getInt16(i*28+20, Endianness.LITTLE_ENDIAN);
      node.bb1x1 = data.getInt16(i*28+22, Endianness.LITTLE_ENDIAN);
      node.rightChild = data.getUint16(i*28+24, Endianness.LITTLE_ENDIAN);
      node.leftChild = data.getUint16(i*28+26, Endianness.LITTLE_ENDIAN);
    }
    return nodes;
  }
}

class Thing {
  int x;
  int y;
  int angle;
  int type;
  int options;
  
  static List<Thing> parse(LumpInfo lump, ByteData data) {
    int thingCount = lump.size~/10;
    List<Thing> things = new List<Thing>(thingCount);
    for (int i=0; i<thingCount; i++) {
      Thing thing = things[i] = new Thing();
      thing.x = data.getInt16(i*10+0, Endianness.LITTLE_ENDIAN);
      thing.y = data.getInt16(i*10+2, Endianness.LITTLE_ENDIAN);
      thing.angle = data.getInt16(i*10+4, Endianness.LITTLE_ENDIAN);
      thing.type = data.getInt16(i*10+6, Endianness.LITTLE_ENDIAN);
      thing.options = data.getInt16(i*10+8, Endianness.LITTLE_ENDIAN);
    }
    return things;
  }
}

class Sector {
  int floorHeight;
  int ceilingHeight;
  String floorTexture;
  String ceilingTexture;
  int lightLevel;
  int special;
  int tag;
  
  static List<Sector> parse(LumpInfo lump, ByteData data) {
    int sectorCount = lump.size~/26;
    List<Sector> sectors = new List<Sector>(sectorCount);
    for (int i=0; i<sectorCount; i++) {
      Sector sector = sectors[i] = new Sector();
      sector.floorHeight = data.getInt16(i*26+0, Endianness.LITTLE_ENDIAN);
      sector.ceilingHeight = data.getInt16(i*26+2, Endianness.LITTLE_ENDIAN);
      sector.floorTexture = readString(data, i*26+4, 8);
      sector.ceilingTexture = readString(data, i*26+12, 8);
      sector.lightLevel = data.getInt16(i*26+20, Endianness.LITTLE_ENDIAN);
      sector.special = data.getInt16(i*26+22, Endianness.LITTLE_ENDIAN);
      sector.tag = data.getInt16(i*26+24, Endianness.LITTLE_ENDIAN);
    }
    return sectors;
  }
}

class SSector {
  int segCount;
  int segStart;
  
  static List<SSector> parse(LumpInfo lump, ByteData data) {
    int sSectorCount = lump.size~/4;
    List<SSector> sSectors = new List<SSector>(sSectorCount);
    for (int i=0; i<sSectorCount; i++) {
      SSector sSector = sSectors[i] = new SSector();
      sSector.segCount = data.getInt16(i*4+0, Endianness.LITTLE_ENDIAN);
      sSector.segStart = data.getInt16(i*4+2, Endianness.LITTLE_ENDIAN);
    }
    return sSectors;
  }
}

class Seg {
  int startVertex;
  int endVertex;
  int angle;
  int linedef;
  int direction;
  int offset;
  
  static List<Seg> parse(LumpInfo lump, ByteData data) {
    int segCount = lump.size~/12;
    List<Seg> segs = new List<Seg>(segCount);
    for (int i=0; i<segCount; i++) {
      Seg seg = segs[i] = new Seg();
      seg.startVertex = data.getInt16(i*12+0, Endianness.LITTLE_ENDIAN);
      seg.endVertex = data.getInt16(i*12+2, Endianness.LITTLE_ENDIAN);
      seg.angle = data.getInt16(i*12+4, Endianness.LITTLE_ENDIAN);
      seg.linedef = data.getInt16(i*12+6, Endianness.LITTLE_ENDIAN);
      seg.direction = data.getInt16(i*12+8, Endianness.LITTLE_ENDIAN);
      seg.offset = data.getInt16(i*12+10, Endianness.LITTLE_ENDIAN);
    }
    return segs;
  }
}


class Sidedef {
  int xTextureOffs;
  int yTextureOffs;
  String upperTexture;
  String lowerTexture;
  String middleTexture;
  int sector;
  
  static List<Sidedef> parse(LumpInfo lump, ByteData data) {
    int sidedefCount = lump.size~/30;
    List<Sidedef> sidedefs = new List<Sidedef>(sidedefCount);
    for (int i=0; i<sidedefCount; i++) {
      Sidedef sidedef = sidedefs[i] = new Sidedef();
      sidedef.xTextureOffs = data.getInt16(i*30+0, Endianness.LITTLE_ENDIAN);
      sidedef.yTextureOffs = data.getInt16(i*30+2, Endianness.LITTLE_ENDIAN);
      sidedef.upperTexture = readString(data, i*30+4, 8);
      sidedef.lowerTexture = readString(data, i*30+12, 8);
      sidedef.middleTexture = readString(data, i*30+20, 8);
      sidedef.sector = data.getInt16(i*30+28, Endianness.LITTLE_ENDIAN);
    }
    return sidedefs;
  }
}

String readString(ByteData data, int offs, int length) {
  List<int> stringValues = new List<int>(length);
  for (int i=0; i<length; i++) {
    int val = data.getUint8(offs+i);
    stringValues[i] = val==0?32:val; // Replace 0 with space (32) to make sure trim works
  }
  return new String.fromCharCodes(stringValues).trim().toUpperCase();
}

class Linedef {
  int fromVertex, toVertex;
  int flags;
  int types;
  int tag;
  int rightSidedef;
  int leftSidedef;
  
  bool impassable;
  bool blockMonsters;
  bool twoSided;
  bool upperUnpegged;
  bool lowerUnpegged;
  bool secret;
  bool blockSound;
  bool notOnMap;
  bool alreadyOnMap;
  
  void calcFlags() {
    impassable = (flags&0x0001)!=0;
    blockMonsters = (flags&0x0002)!=0;
    twoSided = (flags&0x0004)!=0;
    upperUnpegged = (flags&0x0008)!=0;
    lowerUnpegged = (flags&0x0010)!=0;
    secret = (flags&0x0020)!=0;
    blockSound = (flags&0x0040)!=0;
    notOnMap = (flags&0x0080)!=0;
    alreadyOnMap = (flags&0x0100)!=0;
  }
  
  static List<Linedef> parse(LumpInfo lump, ByteData data) {
    int linedefCount = lump.size~/14;
    List<Linedef> linedefs = new List<Linedef>(linedefCount);
    for (int i=0; i<linedefCount; i++) {
      Linedef linedef = linedefs[i] = new Linedef();
      linedef.fromVertex = data.getInt16(i*14+0, Endianness.LITTLE_ENDIAN);
      linedef.toVertex = data.getInt16(i*14+2, Endianness.LITTLE_ENDIAN);
      linedef.flags = data.getInt16(i*14+4, Endianness.LITTLE_ENDIAN);
      linedef.types = data.getInt16(i*14+6, Endianness.LITTLE_ENDIAN);
      linedef.tag = data.getInt16(i*14+8, Endianness.LITTLE_ENDIAN);
      linedef.rightSidedef = data.getInt16(i*14+10, Endianness.LITTLE_ENDIAN);
      linedef.leftSidedef = data.getInt16(i*14+12, Endianness.LITTLE_ENDIAN);
      
      linedef.calcFlags();
    }
    return linedefs;
  }
}

class WAD_Vertexes {
  static List<Vector2> parse(LumpInfo lump, ByteData data) {
    int vertexCount = lump.size~/4;
    List<Vector2> vertices = new List<Vector2>(vertexCount);
    for (int i=0; i<vertexCount; i++) {
      double x = data.getInt16(i*4+0, Endianness.LITTLE_ENDIAN).toDouble(); 
      double y = data.getInt16(i*4+2, Endianness.LITTLE_ENDIAN).toDouble(); 
      vertices[i] = new Vector2(x, y);
    }
    return vertices;
  }
}

class WAD_Playpal {
  List<Palette> palettes = new List<Palette>(14);
  
  WAD_Playpal.parse(ByteData data) {
    int pos = 0;
    for (int i=0; i<14; i++) {
      palettes[i] = new Palette();
      for (int c=0; c<256; c++) {
        palettes[i].r[c] = data.getUint8(pos++);
        palettes[i].g[c] = data.getUint8(pos++);
        palettes[i].b[c] = data.getUint8(pos++);
      }
    }
  }
}

class WAD_Image {
  int width, height;
  int xCenter;
  int yCenter;
  int xAtlasPos, yAtlasPos;
  Uint8List pixels;
  Uint8List pixelData;
  ImageAtlas imageAtlas;
  
  WAD_Image.empty(this.width, this.height) {
    this.xCenter = 0;
    this.yCenter = 0;
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);
    for (int i=0; i<pixelData.length; i++) {
      pixelData[i] = 0xff;
    }
  }
  
  void draw(WAD_Image source, int xp, int yp) {
    for (int y=0; y<source.height; y++) {
      int dy = yp+y;
      if (dy<0 || dy>=height) continue;
      for (int x=0; x<source.width; x++) {
        int dx = xp+x;
        if (dx<0 || dx>=width) continue;
        int sp = (x+y*source.width);
        int srcA = source.pixelData[sp*4+3];
        if (srcA>0) {
          int dp = (dx+dy*width);
          pixelData[dp*4+0] = source.pixelData[sp*4+0];
          pixelData[dp*4+1] = source.pixelData[sp*4+1];
          pixelData[dp*4+2] = source.pixelData[sp*4+2];
          pixelData[dp*4+3] = source.pixelData[sp*4+3];
          pixels[dp] = source.pixels[sp];
        }
      }
    }
  }
  
  WAD_Image.parseFlat(ByteData data, Palette palette) {
    width = 64;
    height = 64;
    xCenter = 0;
    yCenter = 0;
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);

    for (int i=0; i<64*64; i++) {
      pixels[i] = data.getUint8(i);
      pixelData[i*4+0] = palette.r[pixels[i]]; 
      pixelData[i*4+1] = palette.g[pixels[i]]; 
      pixelData[i*4+2] = palette.b[pixels[i]]; 
      pixelData[i*4+3] = 255; 
    }
  }
  
  WAD_Image.parse(ByteData data, Palette palette) {
    width = data.getInt16(0x00, Endianness.LITTLE_ENDIAN);
    height = data.getInt16(0x02, Endianness.LITTLE_ENDIAN);
    xCenter = data.getInt16(0x04, Endianness.LITTLE_ENDIAN);
    yCenter = data.getInt16(0x06, Endianness.LITTLE_ENDIAN);
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);
    
    var columns = new List<int>(width);
    for (int x=0; x<width; x++) {
      columns[x] = data.getUint32(0x08+x*4, Endianness.LITTLE_ENDIAN);
    }

    for (int x=0; x<width; x++) {
      int pos = columns[x];
      while (true) {
        int rowStart = data.getUint8(pos++);
        if (rowStart==255) break;
        int count = data.getUint8(pos++);
        data.getUint8(pos++); // Skip first byte in a column
        for (int i=0; i<count; i++) {
          int pp = x+(rowStart+i)*width;
          pixels[pp] = data.getUint8(pos++);
          pixelData[pp*4+0] = palette.r[pixels[pp]]; 
          pixelData[pp*4+1] = palette.g[pixels[pp]]; 
          pixelData[pp*4+2] = palette.b[pixels[pp]]; 
          pixelData[pp*4+3] = 255; 
        }
        data.getUint8(pos++); // Also skip the last byte
      }
    }
  }
  
  void render(ImageAtlas atlas, Uint8List pixels, int xOffset, int yOffset) {
    this.imageAtlas = atlas;
    this.xAtlasPos = xOffset;
    this.yAtlasPos = yOffset;
    for (int y=0; y<height; y++) {
      int start = (xOffset+(yOffset+y)*atlas.width)*4;
      int end = start+width*4;
      pixels.setRange(start, end, pixelData, y*width*4);
    }
  }
  
  Sprite createSprite(Vector3 pos) {
    return new Sprite(imageAtlas.texture, pos, -xCenter, -yCenter, width, height, xAtlasPos, yAtlasPos);
  }
}

class LumpInfo {
  int filePos, size;
  String name;
  
  LumpInfo(this.name, this.filePos, this.size);
  
  ByteData getByteData(ByteData file) {
    return new ByteData.view(file.buffer, filePos, size);
  }
}

class WAD_Header {
  String identification;
  int numLumps;
  int infoTableOffs;
  
  List<LumpInfo> lumpInfos = new List<LumpInfo>();
  HashMap<String, LumpInfo> lumpInfoMap = new HashMap<String, LumpInfo>();
  
  WAD_Header.parse(ByteData data) {
    identification = new String.fromCharCodes([data.getUint8(0), data.getUint8(1), data.getUint8(2), data.getUint8(3)]);
    numLumps = data.getInt32(0x04, Endianness.LITTLE_ENDIAN);
    infoTableOffs = data.getInt32(0x08, Endianness.LITTLE_ENDIAN);
    
    for (int i=0; i<numLumps; i++) {
      int o = infoTableOffs+16*i;
      int pos = data.getInt32(o+0x00, Endianness.LITTLE_ENDIAN);
      int size = data.getInt32(o+0x04, Endianness.LITTLE_ENDIAN);
      String name = readString(data, o+0x08, 8);
      
      LumpInfo lumpInfo = new LumpInfo(name, pos, size);
      lumpInfos.add(lumpInfo);
      lumpInfoMap[name] = lumpInfo;
    }
  }
}


class BSP {
  Level level;
  BSPNode root;
  
  BSP(this.level) {
    root = new BSPNode(level, level.nodes.last);
  }
  
  Sector findSector(Vector2 pos) {
    return root.findSubSector(pos).sector;
  }
  
  List<SubSector> findSortedSubSectors(Vector2 pos) {
    List<SubSector> result = new List<SubSector>();
    root.findSortedSubSectors(pos, result);
    return result;
  }
}

class SubSector {
  Sector sector;
  int segCount;
  List<Vector2> segFrom;
  List<Vector2> segTo;
  List<Sector> backSectors;
  
  SubSector(Level level, SSector sSector) {
    Seg seg = level.segs[sSector.segStart];
    Linedef linedef = level.linedefs[seg.linedef];
    Sidedef sidedef = level.sidedefs[seg.direction==0?linedef.rightSidedef:linedef.leftSidedef];
    sector = level.sectors[sidedef.sector];
    
    segCount = sSector.segCount;
    segFrom = new List<Vector2>(segCount);
    segTo = new List<Vector2>(segCount);
    backSectors = new List<Sector>(segCount);
    
    for (int i=0; i<sSector.segCount; i++) {
      Seg seg = level.segs[sSector.segStart+i];
      segFrom[i]=level.vertices[seg.startVertex];
      segTo[i]=level.vertices[seg.endVertex];

      Linedef linedef = level.linedefs[seg.linedef];
      int backSidedef = seg.direction!=0?linedef.rightSidedef:linedef.leftSidedef;
      if (backSidedef!=-1) {
        backSectors[i] = level.sectors[level.sidedefs[backSidedef].sector]; 
      }
    }
  }
}

class BSPNode {
  BSP bsp;
  Vector2 pos;
  Vector2 dir;
  double d;
  
  BSPNode leftChild, rightChild;
  SubSector leftSubSector, rightSubSector;
  
  BSPNode(Level level, Node node) {
    pos = new Vector2(node.x.toDouble(), node.y.toDouble());
    dir = new Vector2(-node.dy.toDouble(), node.dx.toDouble()).normalize();
    d = pos.dot(dir);
    
    if (node.leftChild&0x8000==0) {
      leftChild = new BSPNode(level, level.nodes[node.leftChild]);
    } else {
      leftSubSector = new SubSector(level, level.sSectors[node.leftChild&0x7fff]);
    }
    if (node.rightChild&0x8000==0) {
      rightChild = new BSPNode(level, level.nodes[node.rightChild]);
    } else {
      rightSubSector = new SubSector(level, level.sSectors[node.rightChild&0x7fff]);
    }
  }
  
  void findSortedSubSectors(Vector2 p, List<SubSector> result) {
    if (p.dot(dir)<d) {
      if (leftChild!=null) leftChild.findSortedSubSectors(p, result);
      else result.add(leftSubSector);
      
      if (rightChild!=null) rightChild.findSortedSubSectors(p, result);
      else result.add(rightSubSector);
    } else {
      if (rightChild!=null) rightChild.findSortedSubSectors(p, result);
      else result.add(rightSubSector);
      
      if (leftChild!=null) leftChild.findSortedSubSectors(p, result);
      else result.add(leftSubSector);
    }
  }
  
  SubSector findSubSector(Vector2 p) {
    if (p.dot(dir)>d) {
      if (leftChild!=null) return leftChild.findSubSector(p);
      else return leftSubSector;
    } else {
      if (rightChild!=null) return rightChild.findSubSector(p);
      else return rightSubSector;
    }
  }
}