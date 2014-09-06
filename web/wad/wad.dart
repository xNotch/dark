library wad;

import "dart:collection";
import "dart:typed_data";

part "wadbytedata.dart";

/**
 * Represents a WAD file and its contents.
 * This was all figured out with the help of The Unofficial DOOM Specs (http://www.gamers.org/dhs/helpdocs/dmsp1666.html)
 */
class WadFile {
  static HashSet<String> _ABSOLUTELY_NOT_IMAGE_LUMPS_ = new HashSet<String>.from(["THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SEGS", "SSECTORS", "NODES", "SECTORS", "REJECT", "BLOCKMAP", "GENMIDI", "DMXGUS", "PLAYPAL", "COLORMAP", "ENDOOM", "TEXTURE1", "TEXTURE2", "PNAMES"]);
  
  Playpal palette;
  Colormap colormap;
  WadByteData data;

  List<LumpInfo> lumpInfos = new List<LumpInfo>();
  HashMap<String, LumpInfo> lumpInfoMap = new HashMap<String, LumpInfo>();

  List<Image> patchList = new List<Image>();
  
  HashMap<String, Image> wallTextures = new HashMap<String, Image>();
  HashMap<String, Image> patches = new HashMap<String, Image>();
  HashMap<String, Image> flats = new HashMap<String, Image>();
  HashMap<String, Image> sprites = new HashMap<String, Image>();
  HashMap<String, Image> images = new HashMap<String, Image>();
  
  HashMap<String, Sample> samples = new HashMap<String, Sample>();
  
  List<Animation> flatAnimations = new List<Animation>();
  List<Animation> wallAnimations = new List<Animation>();

  /**
   * Reads a wad file from a ByteData
   */
  WadFile.read(ByteData data) {
    this.data = new WadByteData(data);

    setupAnimations();
    readHeader();
    readPaletteAndColor();
    readSprites();
    readFlats();
    readSamplesAndImages();
    readPatches();
    readAllWallTextures();
  }
  
  void setupAnimations() {
    // Set up the flat animations
    flatAnimations.add(new Animation("NUKAGE1", "NUKAGE3"));
    flatAnimations.add(new Animation("FWATER1", "FWATER4"));
    flatAnimations.add(new Animation("SWATER1", "SWATER4"));
    flatAnimations.add(new Animation("LAVA1", "LAVA4"));
    flatAnimations.add(new Animation("BLOOD1", "BLOOD3"));
    flatAnimations.add(new Animation("RROCK05", "RROCK08"));
    flatAnimations.add(new Animation("SLIME01", "SLIME04"));
    flatAnimations.add(new Animation("SLIME05", "SLIME08"));
    flatAnimations.add(new Animation("SLIME09", "SLIME12"));

    // Set up the wall animations
    wallAnimations.add(new Animation("BLODGR1", "BLODGR4"));
    wallAnimations.add(new Animation("BLODRIP1", "BLODRIP4"));
    wallAnimations.add(new Animation("FIREBLU1", "FIREBLU2"));
    wallAnimations.add(new Animation("FIRELAV3", "FIRELAVA"));
    wallAnimations.add(new Animation("FIREMAG1", "FIREMAG3"));
    wallAnimations.add(new Animation("FIREWALA", "FIREWALL"));
    wallAnimations.add(new Animation("GSTFONT1", "GSTFONT3"));
    wallAnimations.add(new Animation("ROCKRED1", "ROCKRED3"));
    wallAnimations.add(new Animation("SLADRIP1", "SLADRIP3"));
    wallAnimations.add(new Animation("BFALL1", "BFALL4"));
    wallAnimations.add(new Animation("WFALL1", "WFALL4"));
    wallAnimations.add(new Animation("SFALL1", "SFALL4"));
    wallAnimations.add(new Animation("DBRAIN1", "DBRAIN4"));
  }
  
  
  void readHeader() {
    String identification = data.getString( 0,  4);
    if (identification!="IWAD") throw new FormatException("Not a PWAD");
    int numLumps = data.getUint32(0x04);
    int infoTableOffs = data.getUint32(0x08);
    if (infoTableOffs+numLumps*16>data.lengthInBytes) throw new FormatException("Can't contain lump table");

    for (int i = 0; i < numLumps; i++) {
      int o = infoTableOffs + 16 * i;
      int pos = data.getInt32(o + 0x00);
      int size = data.getInt32(o + 0x04);
      String name = data.getString(o + 0x08, 8);

      if (pos+size>data.lengthInBytes) throw new FormatException("Can't contain lump \"$name\"");
      
      LumpInfo lumpInfo = new LumpInfo(name, pos, size, i);
      lumpInfos.add(lumpInfo);
      lumpInfoMap[name] = lumpInfo;
    }
  }
  
  void readPaletteAndColor() {
    palette = new Playpal.read(lumpInfoMap["PLAYPAL"].getByteData(data));
    colormap = new Colormap.read(lumpInfoMap["COLORMAP"].getByteData(data));
  }
  
  void readSprites() {
    for (int i = lumpInfoMap["S_START"].index+1; i < lumpInfoMap["S_END"].index; i++) {
      LumpInfo lump = lumpInfos[i];
      sprites[lump.name] = new Image.read(lump.name, lump.getByteData(data));
    }
  }
  
  void readFlats() {
    for (int i = lumpInfoMap["F_START"].index+1; i < lumpInfoMap["F_END"].index; i++) {
      LumpInfo lump = lumpInfos[i];
      flats[lump.name] = new Image.readFlat(lump.name, lump.getByteData(data));
      Animation.check(flatAnimations, lump.name, flats[lump.name]);
    }
  }
  
  void readSamplesAndImages() {
    int depthCount = 0;
    for (int i = 0; i < lumpInfos.length; i++) {
      LumpInfo lump = lumpInfos[i];
      
      if (["F_START", "P_START"].contains(lump.name)) depthCount++;
      else if (["F_END", "P_END"].contains(lump.name)) depthCount--;
      else if (depthCount==0) {
        if (lump.name.startsWith("DS") && Sample.canBeRead(lump.name, lump.getByteData(data))) {
          samples[lump.name] = new Sample.read(lump.name, lump.getByteData(data));
        } else {
          
          if (lump.name=="SHTGA0") {
            print("Found SHTGA0");
          }
          if (Image.canBeRead(lump.name, lump.getByteData(data))) {
  //          print(lump.name);
            images[lump.name] = new Image.read(lump.name, lump.getByteData(data));
          }
        }
      }
    }
  }

  void readPatches() {
    WadByteData data = lumpInfoMap["PNAMES"].getByteData(this.data);
    int count = data.getInt32(0);
    for (int i = 0; i < count; i++) {
      String pname = data.getString(4 + i * 8, 8);

      if (lumpInfoMap.containsKey(pname)) {
        Image patch = new Image.read(pname, lumpInfoMap[pname].getByteData(data));
        patches[pname] = patch;
        patchList.add(patch);
      } else {
        patchList.add(null);
      }
    }
  }
  
  void readAllWallTextures() {
    if (lumpInfoMap.containsKey("TEXTURE1")) readWallTextures(lumpInfoMap["TEXTURE1"].getByteData(data));
    if (lumpInfoMap.containsKey("TEXTURE2")) readWallTextures(lumpInfoMap["TEXTURE2"].getByteData(data));
  }  

  void readWallTextures(WadByteData data) {
    int count = data.getInt32(0);
    for (int i = 0; i < count; i++) {
      int offset = data.getInt32(4 + i * 4);
      readWallTexture(new WadByteData.view(data.data, data.offsetInBytes + offset));
    }
  }

  void readWallTexture(WadByteData data) {
    String name = data.getString(0, 8);
    int width = data.getInt16(12);
    int height = data.getInt16(14);
    int patchCount = data.getInt16(20);

    Image wallTexture = new Image.tuttiFruttiEmpty(name, width, height);
    for (int i = 0; i < patchCount; i++) {
      int xOffs = data.getInt16(22 + i * 10);
      int yOffs = data.getInt16(24 + i * 10);
      int patchId = data.getInt16(26 + i * 10);
      int stepDir = data.getInt16(28 + i * 10);
      int colorMap = data.getInt16(30 + i * 10);
      if (yOffs < 0) yOffs = 0; // Original doom didn't support negative y offsets
      wallTexture.draw(patchList[patchId], xOffs, yOffs, i == 0);
    }

    Animation.check(wallAnimations, name, wallTexture);
    wallTextures[name] = wallTexture;
  }

  Level loadLevel(String name) {
    if (!lumpInfoMap.containsKey(name)) throw new FormatException("No level called $name found in wad file");
    int lumpIndex = lumpInfoMap[name].index+1;
    
    Level level = new Level();
    while (true) {
      if (lumpIndex==lumpInfos.length) throw new FormatException("Level lumps led past end of file"); 

      LumpInfo lump = lumpInfos[lumpIndex++];
      
      if (lump.name == "VERTEXES") level.vertices = Vertex.read(lump, lump.getByteData(data));
      if (lump.name == "LINEDEFS") level.linedefs = Linedef.read(lump, lump.getByteData(data));
      if (lump.name == "SIDEDEFS") level.sidedefs = Sidedef.read(lump, lump.getByteData(data));
      if (lump.name == "SEGS") level.segs = Seg.read(lump, lump.getByteData(data));
      if (lump.name == "SSECTORS") level.sSectors = SSector.read(lump, lump.getByteData(data));
      if (lump.name == "SECTORS") level.sectors = Sector.read(lump, lump.getByteData(data));
      if (lump.name == "THINGS") level.things = Thing.read(lump, lump.getByteData(data));
      if (lump.name == "NODES") level.nodes = Node.read(lump, lump.getByteData(data));
      if (lump.name == "BLOCKMAP") level.blockmap = new Blockmap.read(lump, lump.getByteData(data));

      if (lump.name.length == 4 && lump.name.substring(0, 1) == "E" && lump.name.substring(2, 3) == "M") break;
      if (lump.name.length == 5 && lump.name.substring(0, 3) == "MAP") break;
    }

    level.compile(this);
    return level;
  }
}

class Animation {
  String startFlatName;
  String endFlatName;

  List<String> flatNames = new List<String>();
  List<Image> images = new List<Image>();

  int frame = 0;
  int size = 0;

  Animation(this.startFlatName, this.endFlatName) {
  }

  void add(String flatName, Image image) {
    flatNames.add(flatName);
    images.add(image);
    size++;
  }

  static Animation currentAnimation = null;

  static void check(List<Animation> flatAnimations, String name, Image image) {
    for (int i = 0; i < flatAnimations.length; i++) {
      if (flatAnimations[i].startFlatName == name) currentAnimation = flatAnimations[i];
    }
    if (currentAnimation != null) {
      currentAnimation.add(name, image);
      if (currentAnimation.endFlatName == name) currentAnimation = null;
    }
  }
}

class Vertex {
  int x, y;

  Vertex(this.x, this.y);

  static List<Vertex> read(LumpInfo lump, WadByteData data) {
    int vertexCount = lump.size ~/ 4;
    List<Vertex> vertices = new List<Vertex>(vertexCount);
    for (int i = 0; i < vertexCount; i++) {
      int x = data.getInt16(i * 4 + 0);
      int y = data.getInt16(i * 4 + 2);
      vertices[i] = new Vertex(x, y);
    }
    return vertices;
  }
}

class Level {
  List<Thing> playerSpawns = new List<Thing>(4);
  List<Thing> deathmatchSpawns = new List<Thing>();
  List<Vertex> vertices;
  List<Linedef> linedefs;
  List<Sidedef> sidedefs;
  List<Seg> segs;
  List<SSector> sSectors;
  List<Sector> sectors;
  List<Thing> things;
  List<Node> nodes;
  Blockmap blockmap;

  void compile(WadFile wadFile) {
    linedefs.forEach((l) => l.compile(this));
    sidedefs.forEach((s) => s.compile(this));
    sSectors.forEach((s) => s.compile(this));
    segs.forEach((s) => s.compile(this));
    blockmap.compile(this);
  }
}

class Palette {
  Uint8List r = new Uint8List(256);
  Uint8List g = new Uint8List(256);
  Uint8List b = new Uint8List(256);
}

class BlockCell {
  List<int> linedefIds = new List<int>();
  List<Linedef> linedefs;

  void compile(Level level) {
    linedefs = new List<Linedef>.from(linedefIds.map((id) => level.linedefs[id]), growable: false);
  }
}

class Blockmap {
  int x;
  int y;
  int width;
  int height;

  List<BlockCell> blockCells;

  Blockmap.read(LumpInfo lump, WadByteData data) {
    x = data.getInt16(0);
    y = data.getInt16(2);
    width = data.getInt16(4);
    height = data.getInt16(6);

    blockCells = new List<BlockCell>(width * height);
    for (int i = 0; i < width * height; i++) {
      BlockCell bc = blockCells[i] = new BlockCell();
      int offset = data.getUint16(8 + i * 2) * 2;
      
      int pp = 0;
      while (true) {
        int linedefId = data.getInt16(offset + (pp + 1) * 2);
        if (linedefId == -1) break;
        bc.linedefIds.add(linedefId);
        pp++;
      }
    }
  }

  void compile(Level level) {
    for (int i = 0; i < width * height; i++) {
      blockCells[i].compile(level);
    }
  }
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

  static List<Node> read(LumpInfo lump, WadByteData data) {
    int nodeCount = lump.size ~/ 28;
    List<Node> nodes = new List<Node>(nodeCount);
    for (int i = 0; i < nodeCount; i++) {
      Node node = nodes[i] = new Node();
      node.x = data.getInt16(i * 28 + 0);
      node.y = data.getInt16(i * 28 + 2);
      node.dx = data.getInt16(i * 28 + 4);
      node.dy = data.getInt16(i * 28 + 6);
      node.bb0y0 = data.getInt16(i * 28 + 8);
      node.bb0y1 = data.getInt16(i * 28 + 10);
      node.bb0x0 = data.getInt16(i * 28 + 12);
      node.bb0x1 = data.getInt16(i * 28 + 14);
      node.bb1y0 = data.getInt16(i * 28 + 16);
      node.bb1y1 = data.getInt16(i * 28 + 18);
      node.bb1x0 = data.getInt16(i * 28 + 20);
      node.bb1x1 = data.getInt16(i * 28 + 22);
      node.rightChild = data.getUint16(i * 28 + 24);
      node.leftChild = data.getUint16(i * 28 + 26);
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

  static List<Thing> read(LumpInfo lump, WadByteData data) {
    int thingCount = lump.size ~/ 10;
    List<Thing> things = new List<Thing>(thingCount);
    for (int i = 0; i < thingCount; i++) {
      Thing thing = things[i] = new Thing();
      thing.x = data.getInt16(i * 10 + 0);
      thing.y = data.getInt16(i * 10 + 2);
      thing.angle = data.getInt16(i * 10 + 4);
      thing.type = data.getInt16(i * 10 + 6);
      thing.options = data.getInt16(i * 10 + 8);
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

  static List<Sector> read(LumpInfo lump, WadByteData data) {
    int sectorCount = lump.size ~/ 26;
    List<Sector> sectors = new List<Sector>(sectorCount);
    for (int i = 0; i < sectorCount; i++) {
      Sector sector = sectors[i] = new Sector();
      sector.floorHeight = data.getInt16(i * 26 + 0);
      sector.ceilingHeight = data.getInt16(i * 26 + 2);
      sector.floorTexture = data.getString(i * 26 + 4, 8);
      sector.ceilingTexture = data.getString(i * 26 + 12, 8);
      sector.lightLevel = data.getInt16(i * 26 + 20);
      sector.special = data.getInt16(i * 26 + 22);
      sector.tag = data.getInt16(i * 26 + 24);
    }
    return sectors;
  }
}

class SSector {
  int segCount;
  int segStart;

  List<Seg> segs;

  void compile(Level level) {
    segs = new List<Seg>(segCount);
    for (int i = 0; i < segCount; i++) {
      segs[i] = level.segs[segStart + i];
    }
  }

  static List<SSector> read(LumpInfo lump, WadByteData data) {
    int sSectorCount = lump.size ~/ 4;
    List<SSector> sSectors = new List<SSector>(sSectorCount);
    for (int i = 0; i < sSectorCount; i++) {
      SSector sSector = sSectors[i] = new SSector();
      sSector.segCount = data.getInt16(i * 4 + 0);
      sSector.segStart = data.getInt16(i * 4 + 2);
    }
    return sSectors;
  }
}

class Seg {
  int startVertexId;
  int endVertexId;
  int angle;
  int linedefId;
  int direction;
  int offset;
  int brightness;

  int frontSidedefId;
  int backSidedefId;

  Vertex startVertex;
  Vertex endVertex;
  Linedef linedef;
  Sector sector;
  Sector backSector;
  Sidedef sidedef;
  Sidedef backSidedef;

  void compile(Level level) {
    startVertex = level.vertices[startVertexId];
    endVertex = level.vertices[endVertexId];

    linedef = level.linedefs[linedefId];
    frontSidedefId = direction == 0 ? linedef.rightSidedefId : linedef.leftSidedefId;
    backSidedefId = direction != 0 ? linedef.rightSidedefId : linedef.leftSidedefId;
    sidedef = level.sidedefs[frontSidedefId];
    sector = level.sectors[sidedef.sectorId];
    if (backSidedefId != -1) {
      backSidedef = level.sidedefs[backSidedefId];
      backSector = level.sectors[backSidedef.sectorId];
    }
  }

  static List<Seg> read(LumpInfo lump, WadByteData data) {
    int segCount = lump.size ~/ 12;
    List<Seg> segs = new List<Seg>(segCount);
    for (int i = 0; i < segCount; i++) {
      Seg seg = segs[i] = new Seg();
      seg.startVertexId = data.getInt16(i * 12 + 0);
      seg.endVertexId = data.getInt16(i * 12 + 2);
      seg.angle = data.getInt16(i * 12 + 4);
      seg.linedefId = data.getInt16(i * 12 + 6);
      seg.direction = data.getInt16(i * 12 + 8);
      seg.offset = data.getInt16(i * 12 + 10);
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
  int sectorId;

  Sector sector;

  static List<Sidedef> read(LumpInfo lump, WadByteData data) {
    int sidedefCount = lump.size ~/ 30;
    List<Sidedef> sidedefs = new List<Sidedef>(sidedefCount);
    for (int i = 0; i < sidedefCount; i++) {
      Sidedef sidedef = sidedefs[i] = new Sidedef();
      sidedef.xTextureOffs = data.getInt16(i * 30 + 0);
      sidedef.yTextureOffs = data.getInt16(i * 30 + 2);
      sidedef.upperTexture = data.getString(i * 30 + 4, 8);
      sidedef.lowerTexture = data.getString(i * 30 + 12, 8);
      sidedef.middleTexture = data.getString(i * 30 + 20, 8);
      sidedef.sectorId = data.getInt16(i * 30 + 28);
    }
    return sidedefs;
  }

  void compile(Level level) {
    sector = level.sectors[sectorId];
  }
}

class Linedef {
  int fromVertexId, toVertexId;
  int flags;
  int type;
  int tag;
  int rightSidedefId;
  int leftSidedefId;

  Vertex fromVertex, toVertex;

  Sidedef rightSidedef;
  Sidedef leftSidedef;

  int leftSectorId = -1;
  int rightSectorId = -1;
  
  Sector rightSector;
  Sector leftSector;

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
    impassable = (flags & 0x0001) != 0;
    blockMonsters = (flags & 0x0002) != 0;
    twoSided = (flags & 0x0004) != 0;
    upperUnpegged = (flags & 0x0008) != 0;
    lowerUnpegged = (flags & 0x0010) != 0;
    secret = (flags & 0x0020) != 0;
    blockSound = (flags & 0x0040) != 0;
    notOnMap = (flags & 0x0080) != 0;
    alreadyOnMap = (flags & 0x0100) != 0;
  }

  static List<Linedef> read(LumpInfo lump, WadByteData data) {
    int linedefCount = lump.size ~/ 14;
    List<Linedef> linedefs = new List<Linedef>(linedefCount);
    for (int i = 0; i < linedefCount; i++) {
      Linedef linedef = linedefs[i] = new Linedef();
      linedef.fromVertexId = data.getInt16(i * 14 + 0);
      linedef.toVertexId = data.getInt16(i * 14 + 2);
      linedef.flags = data.getInt16(i * 14 + 4);
      linedef.type = data.getInt16(i * 14 + 6);
      linedef.tag = data.getInt16(i * 14 + 8);
      linedef.rightSidedefId = data.getInt16(i * 14 + 10);
      linedef.leftSidedefId = data.getInt16(i * 14 + 12);

      linedef.calcFlags();
    }
    return linedefs;
  }

  void compile(Level level) {
    fromVertex = level.vertices[fromVertexId];
    toVertex = level.vertices[toVertexId];

    rightSidedef = level.sidedefs[rightSidedefId];
    rightSectorId = rightSidedef.sectorId;
    rightSector = level.sectors[rightSidedef.sectorId];

    if (leftSidedefId != -1) {
      leftSidedef = level.sidedefs[leftSidedefId];
      leftSectorId = leftSidedef.sectorId;
      leftSector = level.sectors[leftSectorId];
    }
  }
}

class Colormap {
  List<List<int>> colormaps = new List<List<int>>(33);

  Colormap.read(WadByteData data) {
    int pos = 0;
    for (int i = 0; i < 33; i++) {
      colormaps[i] = new List<int>(256);
      for (int c = 0; c < 256; c++) {
        colormaps[i][c] = data.getUint8(pos++);
      }
    }
  }
}

class Playpal {
  List<Palette> palettes = new List<Palette>(14);

  Playpal.read(WadByteData data) {
    int pos = 0;
    for (int i = 0; i < 14; i++) {
      palettes[i] = new Palette();
      for (int c = 0; c < 256; c++) {
        palettes[i].r[c] = data.getUint8(pos++);
        palettes[i].g[c] = data.getUint8(pos++);
        palettes[i].b[c] = data.getUint8(pos++);
      }
    }
  }
}

class Sample {
  int sampleCount;
  int rate;
  Uint8List samples;

  static bool canBeRead(String name, WadByteData data) {
    if (data.lengthInBytes < 6) return false;
    int sampleCount = data.getUint16(4);
    if (data.lengthInBytes < 6 + sampleCount) return false;

    return true;
  }

  Sample.read(String name, WadByteData data) {
    rate = data.getUint16(2);
    sampleCount = data.getUint16(4);
    samples = new Uint8List(sampleCount);

    for (int i = 0; i < sampleCount; i++) {
      samples[i] = data.getUint8(8 + i);
    }
  }
}

class Image {
  String name;
  int width, height;
  int xCenter;
  int yCenter;
  Int16List pixels; // -1 = transparent. 0-255 = color index

  /**
   * Return true if the lump COULD be read as an image. No guarantee that it actually IS an image.
   */
  static bool canBeRead(String name, WadByteData data) {
    if (data.lengthInBytes < 8) return false;
    if (WadFile._ABSOLUTELY_NOT_IMAGE_LUMPS_.contains(name)) return false;

    int w = data.getInt16(0);
    int h = data.getInt16(2);
    if (h > 128) return false;
    if (w < 0 || h < 0) return false;
    if (data.lengthInBytes < 8 + w * 4) {
      return false;
    }
    for (int x = 0; x < w; x++) {
      int offs = data.getInt32(8 + x * 4);
      if (offs < 0) return false;
      if (offs > data.lengthInBytes - 1) {
        return false;
      }

      int pos = offs;
      int maxPos = data.lengthInBytes;

      while (true) {
        int rowStart = data.getUint8(pos++);
        if (rowStart == 255) break;
        int count = data.getUint8(pos++);
        if (count<0) return false;
        
        pos += count + 2;
        if (pos >= maxPos) {
          return false;
        }
      }
    }

    return true;
  }

  Image.empty(this.name, this.width, this.height) {
    this.xCenter = 0;
    this.yCenter = 0;

    pixels = new Int16List(width * height)..fillRange(0,  width*height, -1);
  }

  Image.tuttiFruttiEmpty(this.name, this.width, this.height) {
    this.xCenter = 0;
    this.yCenter = 0;

    pixels = new Int16List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int i = x + y * width;
        pixels[i] = (i ~/ 4) & 15; // Our version of tutti frutti
      }
    }
  }

  void draw(Image source, int xp, int yp, bool overwrite) {
    for (int y = 0; y < source.height; y++) {
      int dy = (yp + y);
      if (dy < 0 || dy >= height) continue;

      for (int x = 0; x < source.width; x++) {
        int dx = xp + x;
        if (dx < 0 || dx >= width) continue;

        int sp = (x + y * source.width);
        int dp = (dx + dy * width);
        
        if (source.pixels[sp]>=0 || overwrite) pixels[dp] = source.pixels[sp];
      }
    }
  }

  Image.readFlat(this.name, WadByteData data) {
    width = 64;
    height = 64;
    xCenter = 0;
    yCenter = 0;

    pixels = new Int16List(width * height);

    for (int i = 0; i < 64 * 64; i++) {
      pixels[i] = data.getUint8(i);
    }
  }
  
  Image.mirror(Image source) {
    this.name = source.name;
    width = source.width;
    height = source.height;
    xCenter = width-source.xCenter-1;
    yCenter = source.yCenter;

    pixels = new Int16List(width * height);

    for (int y=0; y<height; y++) {
      for (int x=0; x<width; x++) {
        pixels[x+y*width] = source.pixels[(width-x-1)+y*width];
      }
    }
  }

  Image.read(this.name, WadByteData data) {
    width = data.getInt16(0x00);
    height = data.getInt16(0x02);
    xCenter = data.getInt16(0x04);
    yCenter = data.getInt16(0x06);

    pixels = new Int16List(width * height)..fillRange(0,  width*height, -1);

    var columns = new List<int>(width);
    for (int x = 0; x < width; x++) {
      columns[x] = data.getUint32(0x08 + x * 4);
    }

    for (int x = 0; x < width; x++) {
      int pos = columns[x];
      while (true) {
        int rowStart = data.getUint8(pos++);
        if (rowStart == 255) break;
        int count = data.getUint8(pos++);
        data.getUint8(pos++); // Skip first byte in a column
        for (int i = 0; i < count; i++) {
          int pp = x + (rowStart + i) * width;
          pixels[pp] = data.getUint8(pos++);
        }
        data.getUint8(pos++); // Also skip the last byte
      }
    }
  }
}

class LumpInfo {
  int filePos, size, index;
  String name;

  LumpInfo(this.name, this.filePos, this.size, this.index);

  WadByteData getByteData(WadByteData data) {
    return new WadByteData.view(data.data, filePos, size);
  }
}