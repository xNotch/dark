part of Dark;

HashMap<String, WAD_Image> wallTextureMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> patchMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> flatMap = new HashMap<String, WAD_Image>(); 

class WadFile {
  WAD_Header header;
  WAD_Playpal palette;
  WAD_Colormap colormap;
  ByteData data;
  
  List<WAD_Image> patchList = new List<WAD_Image>();
  List<WAD_Image> spriteList = new List<WAD_Image>();
  
  Level level;
  
  void load(String url, Function onDone, Function onFail) {
    var request = new HttpRequest();
    request.open("get",  url);
    request.responseType = "arraybuffer";
    request.onLoadEnd.listen((e) {
      print("${request.status}");
      if (request.status~/100==2) {
        parse(new ByteData.view(request.response as ByteBuffer));
        onDone();
      } else {
        onFail();
      }
    });
    request.send("");
  }
  
  void parse(ByteData data) {
    this.data = data;
    header = new WAD_Header.parse(data);
    palette = new WAD_Playpal.parse(header.lumpInfoMap["PLAYPAL"].getByteData(data));
    colormap = new WAD_Colormap.parse(header.lumpInfoMap["COLORMAP"].getByteData(data));

    bool foundSprites = false;
//    print("==================SPRITES");
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "S_START") foundSprites = true;
      else if (lump.name == "S_END") foundSprites = false;
      else if (foundSprites) {
        WAD_Image sprite = new WAD_Image.parse(lump.name, lump.getByteData(data));
//        print(lump.name);
        spriteList.add(sprite);
      }
    }
//    print("==========================");
    
    bool foundFlats = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "F_START") foundFlats = true;
      else if (lump.name == "F_END") foundFlats = false;
      else if (foundFlats) {
        if (lump.size==64*64) {
          flatMap[lump.name] = new WAD_Image.parseFlat(lump.name, lump.getByteData(data));
        }
      }
      flatMap["_sky_"] = new WAD_Image.empty("_sky_", 64,  64);
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
      addWallMap(imageAtlas.texture);

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
      addSpriteMap(imageAtlas.texture);

      imageAtlases.add(imageAtlas);
    } while (toInsert.length>0);
    
    
    spriteList.forEach((sprite) {
      SpriteTemplate.addFrameFromLump(sprite.name, sprite);
    });
    print("Sprite atlas count: ${imageAtlases.length}");
  }
  
  void readPatches(ByteData data) {
    int count = data.getInt32(0, Endianness.LITTLE_ENDIAN);
    for (int i=0; i<count; i++) {
      String pname = readString(data,  4+i*8, 8);
      
      if (header.lumpInfoMap.containsKey(pname)) {
        WAD_Image patch = new WAD_Image.parse(pname, header.lumpInfoMap[pname].getByteData(data));
        patchMap[pname] = patch;
        patchList.add(patch);
      }
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
    
    WAD_Image wallTexture = new WAD_Image.empty(name, width, height);
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
//      addSprite(spriteMap["BAR1A0"].createSprite(sector, spritePos));
      double rot = ((90-thing.angle-22)~/45)*PI*2/8.0;
      
      if (thing.spriteName!=null) addSprite(new Sprite(sector, spritePos, rot, spriteTemplates[thing.spriteName]));
    }
    
    for (int i=0; i<segs.length; i++) {
      segs[i].compile(this);
    }
    /*
    for (int i=0; i<segs.length; i++) {
      Seg seg = segs[i];
      Wall.addWallsForSeg(seg);
    }
    * */
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
  String spriteName;
  
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
      
      if (thing.type==0x0001) thing.spriteName = "PLAY"; //
      if (thing.type==0x0002) thing.spriteName = "PLAY";
      if (thing.type==0x0003) thing.spriteName = "PLAY";
      if (thing.type==0x0004) thing.spriteName = "PLAY";
      if (thing.type==0x0bbc) thing.spriteName = "POSS"; // +      # FORMER HUMAN: regular pistol-shooting zombieman
      if (thing.type==0x0054) thing.spriteName = "SSWV"; // +      # WOLFENSTEIN SS: guest appearance by Wolf3D blue guy
      if (thing.type==0x0009) thing.spriteName = "SPOS"; // +      # FORMER HUMAN SERGEANT: black armor, shotgunners
      if (thing.type==0x0041) thing.spriteName = "CPOS"; // +      # HEAVY WEAPON DUDE: red armor, chaingunners
      if (thing.type==0x0bb9) thing.spriteName = "TROO"; // +      # IMP: brown, hurl fireballs
      if (thing.type==0x0bba) thing.spriteName = "SARG"; // +      # DEMON: pink, muscular bull-like chewers
      if (thing.type==0x003a) thing.spriteName = "SARG"; // +      # SPECTRE: invisible version of the DEMON
      if (thing.type==0x0bbe) thing.spriteName = "SKUL"; // +     ^# LOST SOUL: flying flaming skulls, they really bite
      if (thing.type==0x0bbd) thing.spriteName = "HEAD"; // +     ^# CACODEMON: red one-eyed floating heads. Behold...
      if (thing.type==0x0045) thing.spriteName = "BOS2"; // +      # HELL KNIGHT: grey-not-pink BARON, weaker
      if (thing.type==0x0bbb) thing.spriteName = "BOSS"; // +      # BARON OF HELL: cloven hooved minotaur boss
      if (thing.type==0x0044) thing.spriteName = "BSPI"; // +      # ARACHNOTRON: baby SPIDER, shoots green plasma
      if (thing.type==0x0047) thing.spriteName = "PAIN"; // +     ^# PAIN ELEMENTAL: shoots LOST SOULS, deserves its
      if (thing.type==0x0042) thing.spriteName = "SKEL"; // +      # REVENANT: Fast skeletal dude shoots homing missles
      if (thing.type==0x0043) thing.spriteName = "FATT"; // +      # MANCUBUS: Big, slow brown guy shoots barrage of
      if (thing.type==0x0040) thing.spriteName = "VILE"; // +      # ARCH-VILE: Super-fire attack, ressurects the dead!
      if (thing.type==0x0007) thing.spriteName = "SPID"; // +      # SPIDER MASTERMIND: giant walking brain boss
      if (thing.type==0x0010) thing.spriteName = "CYBR"; // +      # CYBER-DEMON: robo-boss, rocket launcher
      if (thing.type==0x0058) thing.spriteName = "BBRN"; // +      # BOSS BRAIN: Horrifying visage of the ultimate demon
//      if (thing.type==0x0059) thing.spriteName = "-   "; // -        Boss Shooter: Shoots spinning skull-blocks
//      if (thing.type==0x0057) thing.spriteName = "-   "; // -        Spawn Spot: Where Todd McFarlane's guys appear
      if (thing.type==0x07d5) thing.spriteName = "CSAW"; // a      $ Chainsaw
      if (thing.type==0x07d1) thing.spriteName = "SHOT"; // a      $ Shotgun
      if (thing.type==0x0052) thing.spriteName = "SGN2"; // a      $ Double-barreled shotgun
      if (thing.type==0x07d2) thing.spriteName = "MGUN"; // a      $ Chaingun, gatling gun, mini-gun, whatever
      if (thing.type==0x07d3) thing.spriteName = "LAUN"; // a      $ Rocket launcher
      if (thing.type==0x07d4) thing.spriteName = "PLAS"; // a      $ Plasma gun
      if (thing.type==0x07d6) thing.spriteName = "BFUG"; // a      $ Bfg9000
      if (thing.type==0x07d7) thing.spriteName = "CLIP"; // a      $ Ammo clip
      if (thing.type==0x07d8) thing.spriteName = "SHEL"; // a      $ Shotgun shells
      if (thing.type==0x07da) thing.spriteName = "ROCK"; // a      $ A rocket
      if (thing.type==0x07ff) thing.spriteName = "CELL"; // a      $ Cell charge
      if (thing.type==0x0800) thing.spriteName = "AMMO"; // a      $ Box of Ammo
      if (thing.type==0x0801) thing.spriteName = "SBOX"; // a      $ Box of Shells
      if (thing.type==0x07fe) thing.spriteName = "BROK"; // a      $ Box of Rockets
      if (thing.type==0x0011) thing.spriteName = "CELP"; // a      $ Cell charge pack
      if (thing.type==0x0008) thing.spriteName = "BPAK"; // a      $ Backpack: doubles maximum ammo capacities
      if (thing.type==0x07db) thing.spriteName = "STIM"; // a      $ Stimpak
      if (thing.type==0x07dc) thing.spriteName = "MEDI"; // a      $ Medikit
      if (thing.type==0x07de) thing.spriteName = "BON1"; // abcdcb ! Health Potion +1% health
      if (thing.type==0x07df) thing.spriteName = "BON2"; // abcdcb ! Spirit Armor +1% armor
      if (thing.type==0x07e2) thing.spriteName = "ARM1"; // ab     $ Green armor 100%
      if (thing.type==0x07e3) thing.spriteName = "ARM2"; // ab     $ Blue armor 200%
      if (thing.type==0x0053) thing.spriteName = "MEGA"; // abcd   ! Megasphere: 200% health, 200% armor
      if (thing.type==0x07dd) thing.spriteName = "SOUL"; // abcdcb ! Soulsphere, Supercharge, +100% health
      if (thing.type==0x07e6) thing.spriteName = "PINV"; // abcd   ! Invulnerability
      if (thing.type==0x07e7) thing.spriteName = "PSTR"; // a      ! Berserk Strength and 100% health
      if (thing.type==0x07e8) thing.spriteName = "PINS"; // abcd   ! Invisibility
      if (thing.type==0x07e9) thing.spriteName = "SUIT"; // a     (!)Radiation suit - see notes on ! above
      if (thing.type==0x07ea) thing.spriteName = "PMAP"; // abcdcb ! Computer map
      if (thing.type==0x07fd) thing.spriteName = "PVIS"; // ab     ! Lite Amplification goggles
      if (thing.type==0x0005) thing.spriteName = "BKEY"; // ab     $ Blue keycard
      if (thing.type==0x0028) thing.spriteName = "BSKU"; // ab     $ Blue skullkey
      if (thing.type==0x000d) thing.spriteName = "RKEY"; // ab     $ Red keycard
      if (thing.type==0x0026) thing.spriteName = "RSKU"; // ab     $ Red skullkey
      if (thing.type==0x0006) thing.spriteName = "YKEY"; // ab     $ Yellow keycard
      if (thing.type==0x0027) thing.spriteName = "YSKU"; // ab     $ Yellow skullkey
      if (thing.type==0x07f3) thing.spriteName = "BAR1"; // ab+    # Barrel; not an obstacle after blown up
      if (thing.type==0x0048) thing.spriteName = "KEEN"; // a+     # A guest appearance by Billy
      if (thing.type==0x0030) thing.spriteName = "ELEC"; // a      # Tall, techno pillar
      if (thing.type==0x001e) thing.spriteName = "COL1"; // a      # Tall green pillar
      if (thing.type==0x0020) thing.spriteName = "COL3"; // a      # Tall red pillar
      if (thing.type==0x001f) thing.spriteName = "COL2"; // a      # Short green pillar
      if (thing.type==0x0024) thing.spriteName = "COL5"; // ab     # Short green pillar with beating heart
      if (thing.type==0x0021) thing.spriteName = "COL4"; // a      # Short red pillar
      if (thing.type==0x0025) thing.spriteName = "COL6"; // a      # Short red pillar with skull
      if (thing.type==0x002f) thing.spriteName = "SMIT"; // a      # Stalagmite: small brown pointy stump
      if (thing.type==0x002b) thing.spriteName = "TRE1"; // a      # Burnt tree: gray tree
      if (thing.type==0x0036) thing.spriteName = "TRE2"; // a      # Large brown tree
      if (thing.type==0x07ec) thing.spriteName = "COLU"; // a      # Floor lamp
      if (thing.type==0x0055) thing.spriteName = "TLMP"; // abcd   # Tall techno floor lamp
      if (thing.type==0x0056) thing.spriteName = "TLP2"; // abcd   # Short techno floor lamp
      if (thing.type==0x0022) thing.spriteName = "CAND"; // a        Candle
      if (thing.type==0x0023) thing.spriteName = "CBRA"; // a      # Candelabra
      if (thing.type==0x002c) thing.spriteName = "TBLU"; // abcd   # Tall blue firestick
      if (thing.type==0x002d) thing.spriteName = "TGRE"; // abcd   # Tall green firestick
      if (thing.type==0x002e) thing.spriteName = "TRED"; // abcd   # Tall red firestick
      if (thing.type==0x0037) thing.spriteName = "SMBT"; // abcd   # Short blue firestick
      if (thing.type==0x0038) thing.spriteName = "SMGT"; // abcd   # Short green firestick
      if (thing.type==0x0039) thing.spriteName = "SMRT"; // abcd   # Short red firestick
      if (thing.type==0x0046) thing.spriteName = "FCAN"; // abc    # Burning barrel
      if (thing.type==0x0029) thing.spriteName = "CEYE"; // abcb   # Evil Eye: floating eye in symbol, over candle
      if (thing.type==0x002a) thing.spriteName = "FSKU"; // abc    # Floating Skull: flaming skull-rock
      if (thing.type==0x0031) thing.spriteName = "GOR1"; // abcb  ^# Hanging victim, twitching
      if (thing.type==0x003f) thing.spriteName = "GOR1"; // abcb  ^  Hanging victim, twitching
      if (thing.type==0x0032) thing.spriteName = "GOR2"; // a     ^# Hanging victim, arms out
      if (thing.type==0x003b) thing.spriteName = "GOR2"; // a     ^  Hanging victim, arms out
      if (thing.type==0x0034) thing.spriteName = "GOR4"; // a     ^# Hanging pair of legs
      if (thing.type==0x003c) thing.spriteName = "GOR4"; // a     ^  Hanging pair of legs
      if (thing.type==0x0033) thing.spriteName = "GOR3"; // a     ^# Hanging victim, 1-legged
      if (thing.type==0x003d) thing.spriteName = "GOR3"; // a     ^  Hanging victim, 1-legged
      if (thing.type==0x0035) thing.spriteName = "GOR5"; // a     ^# Hanging leg
      if (thing.type==0x003e) thing.spriteName = "GOR5"; // a     ^  Hanging leg
      if (thing.type==0x0049) thing.spriteName = "HDB1"; // a     ^# Hanging victim, guts removed
      if (thing.type==0x004a) thing.spriteName = "HDB2"; // a     ^# Hanging victim, guts and brain removed
      if (thing.type==0x004b) thing.spriteName = "HDB3"; // a     ^# Hanging torso, looking down
      if (thing.type==0x004c) thing.spriteName = "HDB4"; // a     ^# Hanging torso, open skull
      if (thing.type==0x004d) thing.spriteName = "HDB5"; // a     ^# Hanging torso, looking up
      if (thing.type==0x004e) thing.spriteName = "HDB6"; // a     ^# Hanging torso, brain removed
      if (thing.type==0x0019) thing.spriteName = "POL1"; // a      # Impaled human
      if (thing.type==0x001a) thing.spriteName = "POL6"; // ab     # Twitching impaled human
      if (thing.type==0x001b) thing.spriteName = "POL4"; // a      # Skull on a pole
      if (thing.type==0x001c) thing.spriteName = "POL2"; // a      # 5 skulls shish kebob
      if (thing.type==0x001d) thing.spriteName = "POL3"; // ab     # Pile of skulls and candles
      if (thing.type==0x000a) thing.spriteName = "PLAY"; // w        Bloody mess (an exploded player)
      if (thing.type==0x000c) thing.spriteName = "PLAY"; // w        Bloody mess, this thing is exactly the same as 10
      if (thing.type==0x0018) thing.spriteName = "POL5"; // a        Pool of blood and flesh
      if (thing.type==0x004f) thing.spriteName = "POB1"; // a        Pool of blood
      if (thing.type==0x0050) thing.spriteName = "POB2"; // a        Pool of blood
      if (thing.type==0x0051) thing.spriteName = "BRS1"; // a        Pool of brains
      if (thing.type==0x000f) thing.spriteName = "PLAY"; // n        Dead player
      if (thing.type==0x0012) thing.spriteName = "POSS"; // l        Dead former human
      if (thing.type==0x0013) thing.spriteName = "SPOS"; // l        Dead former sergeant
      if (thing.type==0x0014) thing.spriteName = "TROO"; // m        Dead imp
      if (thing.type==0x0015) thing.spriteName = "SARG"; // n        Dead demon
      if (thing.type==0x0016) thing.spriteName = "HEAD"; // l        Dead cacodemon
      if (thing.type==0x0017) thing.spriteName = "SKUL"; // k        Dead lost soul, invisible
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
  int startVertexId;
  int endVertexId;
  int angle;
  int linedefId;
  int direction;
  int offset;
  
  double x0, y0; // Start vertex
  double x1, y1; // End vertex
  
  double xn, yn; // Normal
  double xt, yt; // Tangent
  double d; // Distance to line from origin
  double sd; // Distance to line from origin.. sideways?
  double length; // Length of the seg
  
  Linedef linedef;

  Sector sector;
  Sector backSector;
  
  Sidedef sidedef;
  Sidedef backSidedef;

  Vector2 startVertex;
  Vector2 endVertex;

  void compile(Level level) {
    startVertex = level.vertices[startVertexId];
    endVertex = level.vertices[endVertexId];
    x0 = startVertex.x;
    y0 = startVertex.y;
    x1 = endVertex.x;
    y1 = endVertex.y;
    
    double xd = x1-x0;
    double yd = y1-y0;
    
    length = sqrt(xd*xd+yd*yd);
    
    Vector2 tangent = (endVertex-startVertex).normalize();
    xt = tangent.x;
    yt = tangent.y;
    
    xn = tangent.y;
    yn = -tangent.x;
    
    d = x0*xn+y0*yn;
    sd = x0*xt+y0*yt;

    linedef = level.linedefs[linedefId];
    int frontSidedefId = direction==0?linedef.rightSidedef:linedef.leftSidedef;
    int backSidedefId = direction!=0?linedef.rightSidedef:linedef.leftSidedef;
    sidedef = level.sidedefs[frontSidedefId];
    sector = level.sectors[sidedef.sector];
    if (backSidedefId!=-1) {
      backSidedef = level.sidedefs[backSidedefId];
      backSector = level.sectors[backSidedef.sector];
    }
  }
  
  static List<Seg> parse(LumpInfo lump, ByteData data) {
    int segCount = lump.size~/12;
    List<Seg> segs = new List<Seg>(segCount);
    for (int i=0; i<segCount; i++) {
      Seg seg = segs[i] = new Seg();
      seg.startVertexId = data.getInt16(i*12+0, Endianness.LITTLE_ENDIAN);
      seg.endVertexId = data.getInt16(i*12+2, Endianness.LITTLE_ENDIAN);
      seg.angle = data.getInt16(i*12+4, Endianness.LITTLE_ENDIAN);
      seg.linedefId = data.getInt16(i*12+6, Endianness.LITTLE_ENDIAN);
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

class WAD_Colormap {
  List<List<int>> colormaps = new List<List<int>>(33);
  
  WAD_Colormap.parse(ByteData data) {
    int pos = 0;
    for (int i=0; i<33; i++) {
      colormaps[i] = new List<int>(256);
      for (int c=0; c<256; c++) {
        colormaps[i][c] = data.getUint8(pos++);
      }
    }
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
  String name;
  int width, height;
  int xCenter;
  int yCenter;
  int xAtlasPos, yAtlasPos;
  Uint8List pixels;
  Uint8List pixelData;
  ImageAtlas imageAtlas;
  
  WAD_Image.empty(this.name, this.width, this.height) {
    this.xCenter = 0;
    this.yCenter = 0;
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);
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
  
  WAD_Image.parseFlat(this.name, ByteData data) {
    width = 64;
    height = 64;
    xCenter = 0;
    yCenter = 0;
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);

    for (int i=0; i<64*64; i++) {
      int pixel = pixels[i] = data.getUint8(i);
      pixelData[i*4+0] = pixel%16*16+8; 
      pixelData[i*4+1] = pixel~/16*16+8; 
      pixelData[i*4+2] = 0; 
      pixelData[i*4+3] = 255; 
    }
  }
  
  WAD_Image.parse(this.name, ByteData data) {
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
          int pixel = pixels[pp] = data.getUint8(pos++);
          pixelData[pp*4+0] = pixel%16*16+8; 
          pixelData[pp*4+1] = pixel~/16*16+8; 
          pixelData[pp*4+2] = 0; 
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
  
  GL.Texture createTexture(Palette palette) {
    GL.Texture texture = gl.createTexture();
    
    Uint8List result = new Uint8List(width*height*4);
    for (int i=0; i<width*height; i++) {
      result[i*4+0] = palette.r[pixels[i]];
      result[i*4+1] = palette.g[pixels[i]];
      result[i*4+2] = palette.b[pixels[i]];
      result[i*4+3] = 255;
    }
    gl.bindTexture(GL.TEXTURE_2D, texture);
    gl.texImage2DTyped(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, result);
    gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    
    return texture;
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
  
  List<Seg> findSortedSegs(Matrix4 modelViewMatrix, Matrix4 perspectiveMatrix) {
    Culler culler = new Culler(modelViewMatrix, perspectiveMatrix);
    Vector2 pos = (modelViewMatrix.transform3(new Vector3(0.0, 0.0, 0.0))).xz;
    List<Seg> result = new List<Seg>();
    root.findSortedSegs(culler, pos, result);
    return result;
  }
  
  HashSet<Sector> findSectorsInRadius(Vector2 pos, double radius) {
    HashSet<Sector> result = new HashSet<Sector>();
    root.findSectorsInRadius(pos, radius, result);
    return result;
  }

  List<SubSector> findSubSectorsInRadius(Vector2 pos, double radius) {
    List<SubSector> result = new List<SubSector>();
    root.findSubSectorsInRadius(pos, radius, result);
    return result;
  }
}

class SubSector {
  Sector sector;
  int segCount;
  List<Seg> segs;
  List<Vector2> segFrom;
  List<Vector2> segTo;
  List<Sector> backSectors;
  
  SubSector(Level level, SSector sSector) {
    Seg seg = level.segs[sSector.segStart];
    Linedef linedef = level.linedefs[seg.linedefId];
    Sidedef sidedef = level.sidedefs[seg.direction==0?linedef.rightSidedef:linedef.leftSidedef];
    sector = level.sectors[sidedef.sector];
    
    segCount = sSector.segCount;
    segFrom = new List<Vector2>(segCount);
    segTo = new List<Vector2>(segCount);
    backSectors = new List<Sector>(segCount);
    
    segs = new List<Seg>(segCount);
    
    for (int i=0; i<sSector.segCount; i++) {
      Seg seg = level.segs[sSector.segStart+i];
      segFrom[i]=level.vertices[seg.startVertexId];
      segTo[i]=level.vertices[seg.endVertexId];

      Linedef linedef = level.linedefs[seg.linedefId];
      int backSidedef = seg.direction!=0?linedef.rightSidedef:linedef.leftSidedef;
      if (backSidedef!=-1) {
        backSectors[i] = level.sectors[level.sidedefs[backSidedef].sector]; 
      }
      segs[i] = seg;
    }
  }
}

class Culler {
  double tx, ty; // Tangent line
  double td; // Distance to tangent line from origin
  double c, s; // cos and sin
  double xc, yc; // Center
  
  double clip0 = -1.0, clip1 = 1.0;
  List<Vector2> clipRanges = new List<Vector2>();
  
  Culler(Matrix4 modelViewMatrix, Matrix4 perspectiveMatrix) {
    Matrix4 inversePerspective = new Matrix4.copy(perspectiveMatrix)..invert();
    double width = inversePerspective.transform3(new Vector3(1.0, 0.0, 0.0)).x;
    clip0 = width;
    clip1 = -clip0;
    
    Vector2 pos = (modelViewMatrix.transform3(new Vector3(0.0, 0.0, 0.0))).xz;
    Vector2 tangent = (modelViewMatrix.transform3(new Vector3(0.0, 0.0, 1.0))).xz-pos;
    
    xc = pos.x;
    yc = pos.y;
    
    double rot = atan2(tangent.y, tangent.x);
    s = sin(rot);
    c = cos(rot);
    
    tx = tangent.x;
    ty = tangent.y;
    td = pos.x*tx+pos.y*ty;
  }
  
  double xProject(double xp, double yp) {
    double x = xp-xc;
    double y = yp-yc;
    
    double xr = -(s*x-c*y);
    double yr = -(s*y+c*x);
    return xr/yr;
  }
  
  bool isVisible(Bounds b) {
    if (clip0>=clip1) return false;

    // Check if corners are behind the player. True means it's behind
    bool b0 = (b.x0*tx+b.y0*ty)>td; 
    bool b1 = (b.x1*tx+b.y0*ty)>td; 
    bool b2 = (b.x0*tx+b.y1*ty)>td; 
    bool b3 = (b.x1*tx+b.y1*ty)>td; 

    // If all the corners are behind the player, don't render it.
    if (b0 && b1 && b2 && b3) return false;
    
    // If at least one corner is behind the player, force it to render
    // (The player is inside the bounding box)
    if (b0 || b1 || b2 || b3) return true;
    
    // Else check the bounding box against the clipping planes
    List<double> xCorners = [
      xProject(b.x0, b.y0),
      xProject(b.x1, b.y0),
      xProject(b.x1, b.y1),
      xProject(b.x0, b.y1),
    ];
    
    double xLow = xCorners[0];
    double xHigh = xLow;
    for (int i=1; i<4; i++) {
      if (xCorners[i]<xLow) xLow = xCorners[i];
      if (xCorners[i]>xHigh) xHigh = xCorners[i];
    }
    
    return rangeVisible(xLow, xHigh);
  }
  
  bool rangeVisible(double x0, double x1) {
    if (x1<clip0 || x0>clip1) return false;
    
    for (int i=0; i<clipRanges.length; i++) {
      Vector2 cr = clipRanges[i];
      if (x0>=cr.x && x1<=cr.y) return false; 
    }
    return true;
  }
  
  void clipRegion(double x0, double x1) {
    x0-=0.001;
    x1+=0.001;
    for (int i=0; i<clipRanges.length; i++) {
      Vector2 cr = clipRanges[i];
      if (cr.x>=x1 || cr.y<=x0) {
        // It's not inside this range
      } else {
        // Expand to include the other one, and remove it
        if (cr.x<x0) x0 = cr.x;
        if (cr.y>x1) x1 = cr.y;
        clipRanges.removeAt(i--);
      }
    }
    if (x0>clip0 && x1<clip1) {
      if (x1-x0>4.0/320) { // Only add a clip range if it's wider than these many original doom pixels
        clipRanges.add(new Vector2(x0, x1));
      }
    } else {
      if (x0<=clip0 && x1>clip0) clip0=x1;
      if (x1>=clip1 && x0<clip1) clip1=x0;
    }
  }
  
  static const clipDist = 0.01;
  void checkOccluders(SubSector subSector, List<Seg> result) {
    if (clip0>=clip1) return;
    for (int i=0; i<subSector.segs.length; i++) {
      Seg seg = subSector.segs[i];
      double x0 = seg.x0-xc;
      double y0 = seg.y0-yc;
      double x1 = seg.x1-xc;
      double y1 = seg.y1-yc;
      
      double x0r = -(s*x0-c*y0);
      double x1r = -(s*x1-c*y1);
      
      double y0r = -(s*y0+c*x0);
      double y1r = -(s*y1+c*x1);
      
      if (y0r<clipDist && y1r<clipDist) {
        // Completely behind the player.. ignore this line.
        continue;
      } else if (y0r<clipDist) {
        // Clip left side
        double length = y1r-y0r;
        double p = clipDist-y0r;
        x0r += (x1r-x0r)*p/length; 
        y0r = clipDist;
      } else if (y1r<clipDist) {
        // Clip right side
        double length = y0r-y1r;
        double p = clipDist-y1r;
        x1r += (x0r-x1r)*p/length; 
        y1r = clipDist;
      }
      
      double xp0 = x0r/y0r;
      double xp1 = x1r/y1r;

      if (xp0>xp1) continue;
      
      if (rangeVisible(xp0, xp1)) {
        bool shouldClip = false;
        if (!seg.linedef.twoSided) {
          shouldClip = true;
        } else if (seg.backSector!=null) {
          if (seg.backSector.floorHeight>=seg.backSector.ceilingHeight) shouldClip = true;
          else if (seg.sector.floorHeight>=seg.backSector.ceilingHeight) shouldClip = true;
          else if (seg.sector.ceilingHeight<=seg.backSector.floorHeight) shouldClip = true;
        }
        if (shouldClip) clipRegion(xp0, xp1);
        result.add(seg);
      }
    }
  }
}

class Bounds {
  double x0, y0, x1, y1;
  
  Bounds(this.x0, this.y0, this.x1, this.y1);
}

class BSPNode {
  BSP bsp;
  Vector2 pos;
  Vector2 dir;
  double d;

  Bounds leftBounds;
  Bounds rightBounds;
  
  BSPNode leftChild, rightChild;
  SubSector leftSubSector, rightSubSector;
  
  BSPNode(Level level, Node node) {
    pos = new Vector2(node.x.toDouble(), node.y.toDouble());
    dir = new Vector2(-node.dy.toDouble(), node.dx.toDouble()).normalize();
    d = pos.dot(dir);
    
    rightBounds = new Bounds(node.bb0x0+0.0, node.bb0y0+0.0, node.bb0x1+0.0, node.bb0y1+0.0);
    leftBounds = new Bounds(node.bb1x0+0.0, node.bb1y0+0.0, node.bb1x1+0.0, node.bb1y1+0.0);
    
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
  
  void findSortedSegs(Culler culler, Vector2 p, List<Seg> result) {
    if (p.dot(dir)>d) {
      if (culler.isVisible(leftBounds)) {
        if (leftChild!=null) leftChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(leftSubSector, result);
      }
      
      if (culler.isVisible(rightBounds)) {
        if (rightChild!=null) rightChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(rightSubSector, result);
      }
    } else {
      if (culler.isVisible(rightBounds)) {
        if (rightChild!=null) rightChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(rightSubSector, result);
      }
      
      if (culler.isVisible(leftBounds)) {
        if (leftChild!=null) leftChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(leftSubSector, result);
      }
    }
  }
  
  void findSubSectorsInRadius(Vector2 p, double radius, List<SubSector> result) {
    if (p.dot(dir)>d-radius) {
      if (leftChild!=null) leftChild.findSubSectorsInRadius(p, radius, result);
      else result.add(leftSubSector);
    } 
    if (p.dot(dir)<d+radius) {
      if (rightChild!=null) rightChild.findSubSectorsInRadius(p, radius, result);
      else result.add(rightSubSector);
    }
  }
  
  void findSectorsInRadius(Vector2 p, double radius, HashSet<Sector> result) {
    if (p.dot(dir)>d-radius) {
      if (leftChild!=null) leftChild.findSectorsInRadius(p, radius, result);
      else result.add(leftSubSector.sector);
    } 
    if (p.dot(dir)<d+radius) {
      if (rightChild!=null) rightChild.findSectorsInRadius(p, radius, result);
      else result.add(rightSubSector.sector);
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