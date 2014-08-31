part of Dark;

HashMap<String, WAD_Image> wallTextureMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> patchMap = new HashMap<String, WAD_Image>();
HashMap<String, WAD_Image> flatMap = new HashMap<String, WAD_Image>();

List<FlatAnimation> flatAnimations = new List<FlatAnimation>();
List<WallAnimation> wallAnimations = new List<WallAnimation>();

HashSet<String> ABSOLUTELY_NOT_IMAGE_LUMPS = new HashSet<String>.from([
  "THINGS", "LINEDEFS", "SIDEDEFS", "VERTEXES", "SEGS", "SSECTORS", "NODES", "SECTORS",
  "REJECT", "BLOCKMAP", "GENMIDI", "DMXGUS", "PLAYPAL", "COLORMAP", "ENDOOM", "TEXTURE1", "TEXTURE2",
  "PNAMES"]);

class WallAnimation {
  String startFlatName;
  String endFlatName;

  List<String> wallNames = new List<String>();
  List<WAD_Image> images = new List<WAD_Image>();

  int frame = 0;
  int size = 0;

  WallAnimation(this.startFlatName, this.endFlatName) {
  }

  void add(String wallName, WAD_Image image) {
    wallNames.add(wallName);
    images.add(image);
    size++;
  }

  void animate(int frames) {
    if (size==0) return;
    frame = (frame+frames)%size;

    for (int i=0; i<size; i++) {
      wallTextureMap[wallNames[i]] = images[(i+frame)%size];
    }
  }

  static WallAnimation currentAnimation = null;

  static void check(String name, WAD_Image image) {
    for (int i=0; i<wallAnimations.length; i++) {
      if (wallAnimations[i].startFlatName == name) currentAnimation = wallAnimations[i];
    }
    if (currentAnimation!=null) {
      currentAnimation.add(name, image);
      if (currentAnimation.endFlatName == name) currentAnimation = null;
    }
  }

  static double timeAccum = 0.0;
  static void animateAll(double passedTime) {
    timeAccum += passedTime/(8/35); // Original doom was 35 fps, with 8 frames per flat change
    if (timeAccum >= 1.0) {
      int frames = timeAccum.floor();
      timeAccum-=frames;
      for (int i = 0; i < wallAnimations.length; i++) {
        wallAnimations[i].animate(frames);
      }
    }
  }
}

class FlatAnimation {
  String startFlatName;
  String endFlatName;

  List<String> flatNames = new List<String>();
  List<WAD_Image> images = new List<WAD_Image>();

  int frame = 0;
  int size = 0;

  FlatAnimation(this.startFlatName, this.endFlatName) {
  }

  void add(String flatName, WAD_Image image) {
    flatNames.add(flatName);
    images.add(image);
    size++;
  }

  void animate(int frames) {
    if (size==0) return;
    frame = (frame+frames)%size;

    for (int i=0; i<size; i++) {
      flatMap[flatNames[i]] = images[(i+frame)%size];
    }
  }

  static FlatAnimation currentAnimation = null;

  static void check(String name, WAD_Image image) {
    for (int i=0; i<flatAnimations.length; i++) {
      if (flatAnimations[i].startFlatName == name) currentAnimation = flatAnimations[i];
    }
    if (currentAnimation!=null) {
      currentAnimation.add(name, image);
      if (currentAnimation.endFlatName == name) currentAnimation = null;
    }
  }

  static double timeAccum = 0.0;
  static void animateAll(double passedTime) {
    timeAccum += passedTime/(8/35); // Original doom was 35 fps, with 8 frames per flat change
    if (timeAccum >= 1.0) {
      int frames = timeAccum.floor();
      timeAccum-=frames;
      for (int i = 0; i < flatAnimations.length; i++) {
        flatAnimations[i].animate(frames);
      }
    }
  }
}

class WadFile {
  WAD_Header header;
  WAD_Playpal palette;
  WAD_Colormap colormap;
  ByteData data;
  
  List<WAD_Image> patchList = new List<WAD_Image>();
  List<WAD_Image> spriteList = new List<WAD_Image>();
  HashMap<String, WAD_Image> spriteMap = new HashMap<String, WAD_Image>();
  
  Level level;

  WadFile() {
    flatAnimations.clear();

    flatAnimations.add(new FlatAnimation("NUKAGE1", "NUKAGE3"));
    flatAnimations.add(new FlatAnimation("FWATER1", "FWATER4"));
    flatAnimations.add(new FlatAnimation("SWATER1", "SWATER4"));
    flatAnimations.add(new FlatAnimation("LAVA1", "LAVA4"));
    flatAnimations.add(new FlatAnimation("BLOOD1", "BLOOD3"));
    flatAnimations.add(new FlatAnimation("RROCK05", "RROCK08"));
    flatAnimations.add(new FlatAnimation("SLIME01", "SLIME04"));
    flatAnimations.add(new FlatAnimation("SLIME05", "SLIME08"));
    flatAnimations.add(new FlatAnimation("SLIME09", "SLIME12"));

    wallAnimations.clear();

    wallAnimations.add(new WallAnimation("BLODGR1", "BLODGR4"));
    wallAnimations.add(new WallAnimation("BLODRIP1", "BLODRIP4"));
    wallAnimations.add(new WallAnimation("FIREBLU1", "FIREBLU2"));
    wallAnimations.add(new WallAnimation("FIRELAV3", "FIRELAVA"));
    wallAnimations.add(new WallAnimation("FIREMAG1", "FIREMAG3"));
    wallAnimations.add(new WallAnimation("FIREWALA", "FIREWALL"));
    wallAnimations.add(new WallAnimation("GSTFONT1", "GSTFONT3"));
    wallAnimations.add(new WallAnimation("ROCKRED1", "ROCKRED3"));
    wallAnimations.add(new WallAnimation("SLADRIP1", "SLADRIP3"));
    wallAnimations.add(new WallAnimation("BFALL1", "BFALL4"));
    wallAnimations.add(new WallAnimation("WFALL1", "WFALL4"));
    wallAnimations.add(new WallAnimation("SFALL1", "SFALL4"));
    wallAnimations.add(new WallAnimation("DBRAIN1", "DBRAIN4"));
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
  
  void parse(ByteData data) {
    this.data = data;
    header = new WAD_Header.parse(data);
    palette = new WAD_Playpal.parse(header.lumpInfoMap["PLAYPAL"].getByteData(data));
    colormap = new WAD_Colormap.parse(header.lumpInfoMap["COLORMAP"].getByteData(data));

    bool foundSprites = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "S_START") foundSprites = true;
      else if (lump.name == "S_END") foundSprites = false;
      else if (foundSprites) {
        WAD_Image sprite = new WAD_Image.parse(lump.name, lump.getByteData(data));
        spriteList.add(sprite);
        spriteMap[lump.name] = sprite;
      }
    }

    bool foundFlats = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "F_START") foundFlats = true;
      else if (lump.name == "F_END") foundFlats = false;
      else if (foundFlats) {
        if (lump.size==64*64) {
          flatMap[lump.name] = new WAD_Image.parseFlat(lump.name, lump.getByteData(data));
          FlatAnimation.check(lump.name, flatMap[lump.name]);
        }
      }
    }
    
    int depthCount = 0;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "S_START") depthCount++;
      else if (lump.name == "S_END") depthCount--;
      if (lump.name == "F_START") depthCount++;
      else if (lump.name == "F_END") depthCount--;
      if (lump.name == "P_START") depthCount++;
      else if (lump.name == "P_END") depthCount--;
      else if (depthCount==0) {
        if (WAD_Image.canBeRead(data, lump)) {
          WAD_Image sprite = new WAD_Image.parse(lump.name, lump.getByteData(data));
          print(lump.name);
          spriteMap[lump.name] = sprite;
        }
      }
    }    
    
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

    
    readPatches(header.lumpInfoMap["PNAMES"].getByteData(data));
    readAllWallTextures();
    readAllSpriteTextures();
    
    bool foundLevel = false;
    for (int i=0; i<header.lumpInfos.length; i++) {
      LumpInfo lump = header.lumpInfos[i];
      if (lump.name == "E1M7") loadLevel(lump.name, i+1);
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

    WAD_Image wallTexture = new WAD_Image.tuttiFruttiEmpty(name, width, height);
    for (int i=0; i<patchCount; i++) {
      int xOffs = data.getInt16(22+i*10, Endianness.LITTLE_ENDIAN); 
      int yOffs = data.getInt16(24+i*10, Endianness.LITTLE_ENDIAN); 
      int patchId = data.getInt16(26+i*10, Endianness.LITTLE_ENDIAN); 
      int stepDir = data.getInt16(28+i*10, Endianness.LITTLE_ENDIAN);
      int colorMap = data.getInt16(30+i*10, Endianness.LITTLE_ENDIAN);
      if (yOffs<0) yOffs = 0; // Original doom didn't support negative y offsets
      wallTexture.draw(patchList[patchId], xOffs, yOffs, i==0);
    }

    WallAnimation.check(name, wallTexture);
    wallTextureMap[name] = wallTexture;
    
    return wallTexture;
  }
  
  void loadLevel(String name, int lumpIndex) {
    level = new Level();
    
    while (true) {
      LumpInfo lump = header.lumpInfos[lumpIndex++];
      print(lump.name);
      if (lump.name=="VERTEXES") level.vertices = WAD_Vertexes.parse(lump, lump.getByteData(data));
      if (lump.name=="LINEDEFS") level.linedefs = Linedef.parse(lump, lump.getByteData(data));
      if (lump.name=="SIDEDEFS") level.sidedefs = Sidedef.parse(lump, lump.getByteData(data));
      if (lump.name=="SEGS") level.segs = Seg.parse(lump, lump.getByteData(data));
      if (lump.name=="SSECTORS") level.sSectors = SSector.parse(lump, lump.getByteData(data));
      if (lump.name=="SECTORS") level.sectors = Sector.parse(lump, lump.getByteData(data));
      if (lump.name=="THINGS") level.things = Thing.parse(lump, lump.getByteData(data));
      if (lump.name=="NODES") level.nodes = Node.parse(lump, lump.getByteData(data));
      if (lump.name=="BLOCKMAP") level.blockmap = new Blockmap.parse(lump, lump.getByteData(data));
      
      if (lump.name.length == 4 && lump.name.substring(0, 1)=="E" && lump.name.substring(2, 3)=="M") break;
      if (lump.name.length == 5 && lump.name.substring(0, 3)=="MAP") break;
    }
    
    level.build(this);
  }
}

class Level {
  List<PlayerSpawn> playerSpawns = new List<PlayerSpawn>(4);
  List<PlayerSpawn> deathmatchSpawns = new List<PlayerSpawn>();
  List<Vector2> vertices;
  List<Linedef> linedefs;
  List<Sidedef> sidedefs;
  List<Seg> segs;
  List<SSector> sSectors;
  List<Sector> sectors;
  List<Thing> things;
  List<Node> nodes;
  Blockmap blockmap;
  
  BSP bsp;
  
  void build(WadFile wadFile) {
    bsp = new BSP(this);

    for (int i=0; i<things.length; i++) {
      Thing thing = things[i];
      Vector3 spritePos = new Vector3(thing.x.toDouble(), 20.0, thing.y.toDouble());
      Sector sector = bsp.findSector(spritePos.xz);
      spritePos.y = sector.floorHeight.toDouble();
      double rot = ((90-thing.angle-22)~/45)*PI*2/8.0;
      
      switch (thing.type) { 
        case 0x0001: playerSpawns[0] = new PlayerSpawn(spritePos, rot); break; // Spawn 1
        case 0x0002: playerSpawns[1] = new PlayerSpawn(spritePos, rot); break; // Spawn 2
        case 0x0003: playerSpawns[2] = new PlayerSpawn(spritePos, rot); break; // Spawn 3
        case 0x0004: playerSpawns[3] = new PlayerSpawn(spritePos, rot); break; // Spawn 4
        case 0x000b: deathmatchSpawns.add(new PlayerSpawn(spritePos, rot));  break; // Multiplayer spawn
        case 0x0bbc: entities.add(new Monster("POSS", spritePos, rot)); break; // Former Human
        case 0x0054: entities.add(new Monster("SSWV", spritePos, rot)); break; // Wolfenstein SS
        case 0x0009: entities.add(new Monster("SPOS", spritePos, rot)); break; // Former Human Seargeant
        case 0x0041: entities.add(new Monster("CPOS", spritePos, rot)); break; // Heavy Weapon Dude
        case 0x0bb9: entities.add(new Monster("TROO", spritePos, rot)); break; // Imp 
        case 0x0bba: entities.add(new Monster("SARG", spritePos, rot)); break; // Demon
        case 0x003a: entities.add(new Monster("SARG", spritePos, rot, true)); break; // Spectre
        case 0x0bbe: entities.add(new Monster("SKUL", spritePos, rot)); break; // Lost soul
        case 0x0bbd: entities.add(new Monster("HEAD", spritePos, rot)); break; // Cacodemon
        case 0x0045: entities.add(new Monster("BOS2", spritePos, rot)); break; // Hell Knight
        case 0x0bbb: entities.add(new Monster("BOSS", spritePos, rot)); break; // Baron of Hell
        case 0x0044: entities.add(new Monster("BSPI", spritePos, rot)); break; // Arachnotron
        case 0x0047: entities.add(new Monster("PAIN", spritePos, rot)); break; // Pain elemental
        case 0x0042: entities.add(new Monster("SKEL", spritePos, rot)); break; // Revenant
        case 0x0043: entities.add(new Monster("FATT", spritePos, rot)); break; // Mancubus
        case 0x0040: entities.add(new Monster("VILE", spritePos, rot)); break; // Arch-vile
        case 0x0007: entities.add(new Monster("SPID", spritePos, rot)); break; // Spider Mastermind
        case 0x0010: entities.add(new Monster("CYBR", spritePos, rot)); break; // Cyber-demon
        case 0x0058: entities.add(new Monster("BBRN", spritePos, rot)); break; // Romero
        
        case 0x07d5: entities.add(new Pickup("CSAW", "a", spritePos, rot)); break; //     $ Chainsaw
        case 0x07d1: entities.add(new Pickup("SHOT", "a", spritePos, rot)); break; //      $ Shotgun
        case 0x0052: entities.add(new Pickup("SGN2", "a", spritePos, rot)); break; //      $ Double-barreled shotgun
        case 0x07d2: entities.add(new Pickup("MGUN", "a", spritePos, rot)); break; //      $ Chaingun, gatling gun, mini-gun, whatever
        case 0x07d3: entities.add(new Pickup("LAUN", "a", spritePos, rot)); break; //      $ Rocket launcher
        case 0x07d4: entities.add(new Pickup("PLAS", "a", spritePos, rot)); break; //      $ Plasma gun
        case 0x07d6: entities.add(new Pickup("BFUG", "a", spritePos, rot)); break; //      $ Bfg9000
        case 0x07d7: entities.add(new Pickup("CLIP", "a", spritePos, rot)); break; //      $ Ammo clip
        case 0x07d8: entities.add(new Pickup("SHEL", "a", spritePos, rot)); break; //      $ Shotgun shells
        case 0x07da: entities.add(new Pickup("ROCK", "a", spritePos, rot)); break; //      $ A rocket
        case 0x07ff: entities.add(new Pickup("CELL", "a", spritePos, rot)); break; //      $ Cell charge
        case 0x0800: entities.add(new Pickup("AMMO", "a", spritePos, rot)); break; //      $ Box of Ammo
        case 0x0801: entities.add(new Pickup("SBOX", "a", spritePos, rot)); break; //      $ Box of Shells
        case 0x07fe: entities.add(new Pickup("BROK", "a", spritePos, rot)); break; //      $ Box of Rockets
        case 0x0011: entities.add(new Pickup("CELP", "a", spritePos, rot)); break; //      $ Cell charge pack
        case 0x0008: entities.add(new Pickup("BPAK", "a", spritePos, rot)); break; //      $ Backpack: doubles maximum ammo capacities
        case 0x07db: entities.add(new Pickup("STIM", "a", spritePos, rot)); break; //      $ Stimpak
        case 0x07dc: entities.add(new Pickup("MEDI", "a", spritePos, rot)); break; //      $ Medikit
        case 0x07de: entities.add(new Pickup("BON1", "abcdcb", spritePos, rot)); break; // ! Health Potion +1% health
        case 0x07df: entities.add(new Pickup("BON2", "abcdcb", spritePos, rot)); break; // ! Spirit Armor +1% armor
        case 0x07e2: entities.add(new Pickup("ARM1", "ab", spritePos, rot)); break; //     $ Green armor 100%
        case 0x07e3: entities.add(new Pickup("ARM2", "ab", spritePos, rot)); break; //     $ Blue armor 200%
        case 0x0053: entities.add(new Pickup("MEGA", "abcd", spritePos, rot)); break; //   ! Megasphere: 200% health, 200% armor
        case 0x07dd: entities.add(new Pickup("SOUL", "abcdcb", spritePos, rot)); break; // ! Soulsphere, Supercharge, +100% health
        case 0x07e6: entities.add(new Pickup("PINV", "abcd", spritePos, rot)); break; //   ! Invulnerability
        case 0x07e7: entities.add(new Pickup("PSTR", "a", spritePos, rot)); break; //      ! Berserk Strength and 100% health
        case 0x07e8: entities.add(new Pickup("PINS", "abcd", spritePos, rot)); break; //   ! Invisibility
        case 0x07e9: entities.add(new Pickup("SUIT", "a", spritePos, rot)); break; //     (!)Radiation suit - see notes on ! above
        case 0x07ea: entities.add(new Pickup("PMAP", "abcdcb", spritePos, rot)); break; // ! Computer map
        case 0x07fd: entities.add(new Pickup("PVIS", "ab", spritePos, rot)); break; //     ! Lite Amplification goggles
        case 0x0005: entities.add(new Pickup("BKEY", "ab", spritePos, rot)); break; //     $ Blue keycard
        case 0x0028: entities.add(new Pickup("BSKU", "ab", spritePos, rot)); break; //     $ Blue skullkey
        case 0x000d: entities.add(new Pickup("RKEY", "ab", spritePos, rot)); break; //     $ Red keycard
        case 0x0026: entities.add(new Pickup("RSKU", "ab", spritePos, rot)); break; //     $ Red skullkey
        case 0x0006: entities.add(new Pickup("YKEY", "ab", spritePos, rot)); break; //     $ Yellow keycard
        case 0x0027: entities.add(new Pickup("YSKU", "ab", spritePos, rot)); break; //     $ Yellow skullkey
        
        
        case 0x000a: entities.add(new Decoration("PLAY", "w", spritePos, rot)); break; // Bloody mess (an exploded player)
        case 0x000c: entities.add(new Decoration("PLAY", "w", spritePos, rot)); break; // 
        case 0x0018: entities.add(new Decoration("POL5", "a", spritePos, rot)); break; // Pool of blood and flesh
        case 0x004f: entities.add(new Decoration("POB1", "a", spritePos, rot)); break; // Pool of blood
        case 0x0050: entities.add(new Decoration("POB2", "a", spritePos, rot)); break; // Pool of blood
        case 0x0051: entities.add(new Decoration("BRS1", "a", spritePos, rot)); break; // Pool of brains
        case 0x000f: entities.add(new Decoration("PLAY", "n", spritePos, rot)); break; // Dead player
        case 0x0012: entities.add(new Decoration("POSS", "l", spritePos, rot)); break; // Dead former human
        case 0x0013: entities.add(new Decoration("SPOS", "l", spritePos, rot)); break; // Dead former sergeant
        case 0x0014: entities.add(new Decoration("TROO", "m", spritePos, rot)); break; // Dead imp
        case 0x0015: entities.add(new Decoration("SARG", "n", spritePos, rot)); break; // Dead demon
        case 0x0016: entities.add(new Decoration("HEAD", "l", spritePos, rot)); break; // Dead cacodemon
        case 0x0017: entities.add(new Decoration("SKUL", "k", spritePos, rot)); break; // Dead lost soul, invisible 

        case 0x0030: entities.add(new Decoration.blocking("ELEC", "a", spritePos, rot)); break; //      # Tall, techno pillar
        case 0x001e: entities.add(new Decoration.blocking("COL1", "a", spritePos, rot)); break; //      # Tall green pillar
        case 0x0020: entities.add(new Decoration.blocking("COL3", "a", spritePos, rot)); break; //      # Tall red pillar
        case 0x001f: entities.add(new Decoration.blocking("COL2", "a", spritePos, rot)); break; //      # Short green pillar
        case 0x0024: entities.add(new Decoration.blocking("COL5", "ab", spritePos, rot)); break; //     # Short green pillar with beating heart
        case 0x0021: entities.add(new Decoration.blocking("COL4", "a", spritePos, rot)); break; //      # Short red pillar
        case 0x0025: entities.add(new Decoration.blocking("COL6", "a", spritePos, rot)); break; //      # Short red pillar with skull
        case 0x002f: entities.add(new Decoration.blocking("SMIT", "a", spritePos, rot)); break; //      # Stalagmite: small brown pointy stump
        case 0x002b: entities.add(new Decoration.blocking("TRE1", "a", spritePos, rot)); break; //      # Burnt tree: gray tree
        case 0x0036: entities.add(new Decoration.blocking("TRE2", "a", spritePos, rot)); break; //      # Large brown tree
        case 0x07ec: entities.add(new Decoration.blocking("COLU", "a", spritePos, rot)); break; //      # Floor lamp
        case 0x0055: entities.add(new Decoration.blocking("TLMP", "abcd", spritePos, rot)); break; //   # Tall techno floor lamp
        case 0x0056: entities.add(new Decoration.blocking("TLP2", "abcd", spritePos, rot)); break; //   # Short techno floor lamp
        case 0x0022: entities.add(new Decoration.blocking("CAND", "a", spritePos, rot)); break; //        Candle
        case 0x0023: entities.add(new Decoration.blocking("CBRA", "a", spritePos, rot)); break; //      # Candelabra
        case 0x002c: entities.add(new Decoration.blocking("TBLU", "abcd", spritePos, rot)); break; //   # Tall blue firestick
        case 0x002d: entities.add(new Decoration.blocking("TGRE", "abcd", spritePos, rot)); break; //   # Tall green firestick
        case 0x002e: entities.add(new Decoration.blocking("TRED", "abcd", spritePos, rot)); break; //   # Tall red firestick
        case 0x0037: entities.add(new Decoration.blocking("SMBT", "abcd", spritePos, rot)); break; //   # Short blue firestick
        case 0x0038: entities.add(new Decoration.blocking("SMGT", "abcd", spritePos, rot)); break; //   # Short green firestick
        case 0x0039: entities.add(new Decoration.blocking("SMRT", "abcd", spritePos, rot)); break; //   # Short red firestick
        case 0x0046: entities.add(new Decoration.blocking("FCAN", "abc", spritePos, rot)); break; //    # Burning barrel
        case 0x0029: entities.add(new Decoration.blocking("CEYE", "abcb", spritePos, rot)); break; //   # Evil Eye: floating eye in symbol, over candle
        case 0x002a: entities.add(new Decoration.blocking("FSKU", "abc", spritePos, rot)); break; //    # Floating Skull: flaming skull-rock
        case 0x0031: entities.add(new Decoration.blocking("GOR1", "abcb", spritePos, rot)..hanging = true); break; //  ^# Hanging victim, twitching
        case 0x003f: entities.add(new Decoration.blocking("GOR1", "abcb", spritePos, rot)..hanging = true); break; //  ^  Hanging victim, twitching
        case 0x0032: entities.add(new Decoration.blocking("GOR2", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging victim, arms out
        case 0x003b: entities.add(new Decoration.blocking("GOR2", "a", spritePos, rot)..hanging = true); break; //     ^  Hanging victim, arms out
        case 0x0034: entities.add(new Decoration.blocking("GOR4", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging pair of legs
        case 0x003c: entities.add(new Decoration.blocking("GOR4", "a", spritePos, rot)..hanging = true); break; //     ^  Hanging pair of legs
        case 0x0033: entities.add(new Decoration.blocking("GOR3", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging victim, 1-legged
        case 0x003d: entities.add(new Decoration.blocking("GOR3", "a", spritePos, rot)..hanging = true); break; //     ^  Hanging victim, 1-legged
        case 0x0035: entities.add(new Decoration.blocking("GOR5", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging leg
        case 0x003e: entities.add(new Decoration.blocking("GOR5", "a", spritePos, rot)..hanging = true); break; //     ^  Hanging leg
        case 0x0049: entities.add(new Decoration.blocking("HDB1", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging victim, guts removed
        case 0x004a: entities.add(new Decoration.blocking("HDB2", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging victim, guts and brain removed
        case 0x004b: entities.add(new Decoration.blocking("HDB3", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging torso, looking down
        case 0x004c: entities.add(new Decoration.blocking("HDB4", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging torso, open skull
        case 0x004d: entities.add(new Decoration.blocking("HDB5", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging torso, looking up
        case 0x004e: entities.add(new Decoration.blocking("HDB6", "a", spritePos, rot)..hanging = true); break; //     ^# Hanging torso, brain removed
        case 0x0019: entities.add(new Decoration.blocking("POL1", "a", spritePos, rot)); break; //      # Impaled human
        case 0x001a: entities.add(new Decoration.blocking("POL6", "ab", spritePos, rot)); break; //     # Twitching impaled human
        case 0x001b: entities.add(new Decoration.blocking("POL4", "a", spritePos, rot)); break; //      # Skull on a pole
        case 0x001c: entities.add(new Decoration.blocking("POL2", "a", spritePos, rot)); break; //      # 5 skulls shish kebob
        case 0x001d: entities.add(new Decoration.blocking("POL3", "ab", spritePos, rot)); break; //     # Pile of skulls and candles
        
        default:
/*          if (thing.spriteName!=null) {
          print("thing.spriteName: ${thing.spriteName}");
          SpriteTemplate template = spriteTemplates[thing.spriteName];
          if (template==null) {
            print("No template for ${thing.spriteName}");
          } else {
            addSprite(new Sprite(sector, spritePos, rot, template));
          }
        }*/
      }
    }
    
    for (int i=0; i<linedefs.length; i++) {
      linedefs[i].compile(this);
    }
    
    for (int i=0; i<segs.length; i++) {
      segs[i].compile(this);
    }
    
    blockmap.compile(this);
  }
}

class Palette {
  List<int> r = new List<int>(256);
  List<int> g = new List<int>(256);
  List<int> b = new List<int>(256);
}

class BlockCell {
  List<Entity> entities = new List<Entity>();
}

class Blockmap {
  static const int ORIGINAL_BLOCKMAP_WIDTH = 128;
  static const int BLOCKMAP_WIDTH = 128;
  int x;
  int y;
  int width;
  int height;
  
  List<BlockCell> blockCells;
  
  Blockmap.parse(LumpInfo lump, ByteData data) {
    x = data.getInt16(0, Endianness.LITTLE_ENDIAN);
    y = data.getInt16(2, Endianness.LITTLE_ENDIAN);
    width = data.getInt16(4, Endianness.LITTLE_ENDIAN)*BLOCKMAP_WIDTH~/ORIGINAL_BLOCKMAP_WIDTH;
    height = data.getInt16(6, Endianness.LITTLE_ENDIAN)*BLOCKMAP_WIDTH~/ORIGINAL_BLOCKMAP_WIDTH;
    
    blockCells = new List<BlockCell>(width*height);
    for (int i=0; i<width*height; i++) {
      BlockCell bc = blockCells[i] = new BlockCell();
/*      int offset = data.getUint16(8+i*2, Endianness.LITTLE_ENDIAN)*2;
      if (data.getInt16(offset, Endianness.LITTLE_ENDIAN)!=0) throw "Not a valid blockmap cell list";
      int pp = 0;
      while (true) {
        int linedefId = data.getInt16(offset+(pp+1)*2, Endianness.LITTLE_ENDIAN);
        if (linedefId==-1) break;
        bc.linedefIds.add(linedefId);
        pp++;
      }*/
    }
  }
  
  void compile(Level level) {
    for (int i=0; i<width*height; i++) {
//      blockCells[i].compile(level);
    }
  }
  
  void getBlockCellsRadius(double x, double y, double radius, List<BlockCell> result) {
    getBlockCells(x-radius, y-radius, x+radius, y+radius, result);
  }
  
  BlockCell getBlockCell(double xp, double yp) {
    int xc = (xp.floor()-x)~/BLOCKMAP_WIDTH;
    int yc = (yp.floor()-y)~/BLOCKMAP_WIDTH;
    if (xc<0 || yc<0 || xc>=width || yc>=height) return null;
    return blockCells[xc+yc*width];
  }

  void getBlockCells(double x0, double y0, double x1, double y1, List<BlockCell> result) {
    result.clear();
    int xc0 = (x0.floor()-x)~/BLOCKMAP_WIDTH;
    int yc0 = (y0.floor()-y)~/BLOCKMAP_WIDTH;
    int xc1 = (x1.floor()-x)~/BLOCKMAP_WIDTH;
    int yc1 = (y1.floor()-y)~/BLOCKMAP_WIDTH;
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
//  String spriteName;
  
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
      
   /* 
      case 0x07f3: entities.add(new Decoration("BAR1", "ab+    # Barrel; not an obstacle after blown up
      case 0x0048: entities.add(new Decoration("KEEN", "a+     # A guest appearance by Billy
      */

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

  double brightness;
  
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

    brightness = 1.0-yn.abs()*0.2;

    linedef = level.linedefs[linedefId];
    int frontSidedefId = direction==0?linedef.rightSidedefId:linedef.leftSidedefId;
    int backSidedefId = direction!=0?linedef.rightSidedefId:linedef.leftSidedefId;
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
  int ldCheckCounterHackId;
  int fromVertexId, toVertexId;
  int flags;
  int type;
  int tag;
  int rightSidedefId;
  int leftSidedefId;
  
  Vector2 fromVertex, toVertex;

  Sidedef rightSidedef;
  Sidedef leftSidedef;

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
  
  double x0, y0; // Start vertex
  double x1, y1; // End vertex
  
  double xn, yn; // Normal
  double xt, yt; // Tangent
  double d; // Distance to line from origin
  double sd; // Distance to line from origin.. sideways?
  double length; // Length of the seg
  
  
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
      linedef.fromVertexId = data.getInt16(i*14+0, Endianness.LITTLE_ENDIAN);
      linedef.toVertexId = data.getInt16(i*14+2, Endianness.LITTLE_ENDIAN);
      linedef.flags = data.getInt16(i*14+4, Endianness.LITTLE_ENDIAN);
      linedef.type = data.getInt16(i*14+6, Endianness.LITTLE_ENDIAN);
      linedef.tag = data.getInt16(i*14+8, Endianness.LITTLE_ENDIAN);
      linedef.rightSidedefId = data.getInt16(i*14+10, Endianness.LITTLE_ENDIAN);
      linedef.leftSidedefId = data.getInt16(i*14+12, Endianness.LITTLE_ENDIAN);
      
      linedef.calcFlags();
    }
    return linedefs;
  }
  
  void compile(Level level) {
    fromVertex = level.vertices[fromVertexId];
    toVertex = level.vertices[toVertexId];

    rightSidedef = level.sidedefs[rightSidedefId];
    rightSector = level.sectors[rightSidedef.sector];

    if (leftSidedefId!=-1) {
      leftSidedef = level.sidedefs[leftSidedefId];
      leftSector = level.sectors[leftSidedef.sector];
    }
    
    x0 = fromVertex.x;
    y0 = fromVertex.y;
    x1 = toVertex.x;
    y1 = toVertex.y;
    
    double xd = x1-x0;
    double yd = y1-y0;
    
    length = sqrt(xd*xd+yd*yd);
    
    Vector2 tangent = (toVertex-fromVertex).normalize();
    xt = tangent.x;
    yt = tangent.y;

    xn = tangent.y;
    yn = -tangent.x;
    
    d = x0*xn+y0*yn;
    sd = x0*xt+y0*yt;    
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
  static Random tuttiFruttiRandom = new Random(321334);
  String name;
  int width, height;
  int xCenter;
  int yCenter;
  int xAtlasPos, yAtlasPos;
  Uint8List pixels;
  Uint8List pixelData;
  ImageAtlas imageAtlas;

  /**
   * Return true if the lump COULD be read as an image.
   * It might contain nonsense.
   */
  static bool canBeRead(ByteData data, LumpInfo lump) {
    if (lump.size<8) return false;
    if (ABSOLUTELY_NOT_IMAGE_LUMPS.contains(lump.name)) return false;
    
    if (lump.name.startsWith("STCFN")) {
      print("Maybe char? ${lump.name}");
    }
    
    int w = data.getInt16(lump.filePos+0, Endianness.LITTLE_ENDIAN);
    int h = data.getInt16(lump.filePos+2, Endianness.LITTLE_ENDIAN);
    if (h>128) return false;
    if (w<0 || h<0) return false;
    if (lump.size<8+w*4){
      if (lump.name.startsWith("STCFN")) print("no!");
      return false;
    }
    for (int x=0; x<w; x++) {
      int offs = data.getInt32(lump.filePos+8+x*4, Endianness.LITTLE_ENDIAN);
      if (offs<0) return false;
      if (offs>lump.size) {
        if (lump.name.startsWith("STCFN")) print("no2!");
        return false;
      }
      
      int pos = lump.filePos+offs;
      int maxPos = lump.filePos+lump.size;
      
      while (true) {
        int rowStart = data.getUint8(pos++);
        if (rowStart==255) break;
        int count = data.getUint8(pos++);
        pos+=count+2;
        if (pos>=maxPos){
          if (lump.name.startsWith("STCFN")) print("no3! $count");
          return false;
        }
      }      
    }
    
    if (lump.name.startsWith("STCFN")) print("YES!");

    return true;
  }
  
  WAD_Image.empty(this.name, this.width, this.height) {
    this.xCenter = 0;
    this.yCenter = 0;
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);
  }
  
  WAD_Image.tuttiFruttiEmpty(this.name, this.width, this.height) {
    this.xCenter = 0;
    this.yCenter = 0;
    
    pixels = new Uint8List(width*height);
    pixelData = new Uint8List(width*height*4);

    int run = 0;
    int tuttifruttiColor = 0;
    for (int y=0; y<height; y++) {
      for (int x=0; x<width; x++) {
        int i = x+y*width;
        if (--run<0) {
          tuttifruttiColor = tuttiFruttiRandom.nextInt(256);
          run = random.nextInt(random.nextInt(32)+1);
        }
        int pixel = pixels[i] = tuttifruttiColor;
        pixelData[i*4+0] = pixel%16*8+4;
        pixelData[i*4+1] = pixel~/16*8+4;
        pixelData[i*4+2] = 0;
        pixelData[i*4+3] = 255;
      }
    }
  }
  
  void draw(WAD_Image source, int xp, int yp, bool overwrite) {
    for (int y=0; y<source.height; y++) {
      int dy = (yp+y);
      if (dy<0 || dy>=height) continue;
      for (int x=0; x<source.width; x++) {
        int dx = xp+x;
        if (dx<0 || dx>=width) continue;
        int sp = (x+y*source.width);
        int srcA = source.pixelData[sp*4+3];
        if (srcA>0 || overwrite) {
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
      pixelData[i*4+0] = pixel%16*8+4;
      pixelData[i*4+1] = pixel~/16*8+4;
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
          pixelData[pp*4+0] = pixel%16*8+4;
          pixelData[pp*4+1] = pixel~/16*8+4;
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
      result[i*4+0] = (pixels[i]%16)*8+4;
      result[i*4+1] = (pixels[i]~/16)*8+4+128;
      result[i*4+2] = 255;
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
  Culler culler = new Culler();
  
  BSP(this.level) {
    root = new BSPNode(level, level.nodes.last);
  }
  
  Sector findSector(Vector2 pos) {
    return root.findSubSector(pos).sector;
  }
  
  List<Seg> findSortedSegs(Matrix4 modelViewMatrix, Matrix4 perspectiveMatrix) {
    culler.init(modelViewMatrix, perspectiveMatrix);
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

  List<SubSector> findSubSectorsInRadius(Vector2 pos, double radius, List<SubSector> result) {
    result.clear();
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
  List<Linedef> linedefs;
  
  SubSector(Level level, SSector sSector) {
    Seg seg = level.segs[sSector.segStart];
    Linedef linedef = level.linedefs[seg.linedefId];
    Sidedef sidedef = level.sidedefs[seg.direction==0?linedef.rightSidedefId:linedef.leftSidedefId];
    sector = level.sectors[sidedef.sector];
    
    segCount = sSector.segCount;
    segFrom = new List<Vector2>(segCount);
    segTo = new List<Vector2>(segCount);
    backSectors = new List<Sector>(segCount);
    
    segs = new List<Seg>(segCount);
    
    HashSet<Linedef> linedefSet = new HashSet<Linedef>();
    for (int i=0; i<sSector.segCount; i++) {
      Seg seg = level.segs[sSector.segStart+i];
      segFrom[i]=level.vertices[seg.startVertexId];
      segTo[i]=level.vertices[seg.endVertexId];

      Linedef linedef = level.linedefs[seg.linedefId];
      linedefSet.add(linedef);
      int backSidedef = seg.direction!=0?linedef.rightSidedefId:linedef.leftSidedefId;
      if (backSidedef!=-1) {
        backSectors[i] = level.sectors[level.sidedefs[backSidedef].sector]; 
      }
      segs[i] = seg;
    }
    
    linedefs = new List<Linedef>.from(linedefSet);
  }
}

class ClipRange {
  double x0, x1;
  
  ClipRange(this.x0, this.x1);
  void set(double x0, double x1) {
    this.x0 = x0;
    this.x1 = x1;
  }
}

class Culler {
  double tx, ty; // Tangent line
  double td; // Distance to tangent line from origin
  double c, s; // cos and sin
  double xc, yc; // Center
  
  double clip0 = -1.0, clip1 = 1.0;
  List<ClipRange> clipRanges = new List<ClipRange>();
  int clipRangeCount = 0;
  
  void init(Matrix4 modelViewMatrix, Matrix4 perspectiveMatrix) {
    clipRangeCount = 0;
    Matrix4 inversePerspective = new Matrix4.copy(perspectiveMatrix)..invert();
    double width = inversePerspective.transform3(new Vector3(1.0, 0.0, 0.0)).x;
    clip0 = width*2.0;
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
    
    for (int i=0; i<clipRangeCount; i++) {
      ClipRange cr = clipRanges[i];
      if (x0>=cr.x0 && x1<=cr.x1) return false; 
    }
    return true;
  }
  
  void clipRegion(double x0, double x1) {
    x0-=0.001;
    x1+=0.001;
    for (int i=0; i<clipRangeCount; i++) {
      ClipRange cr = clipRanges[i];
      if (cr.x0>=x1 || cr.x1<=x0) {
        // It's not inside this range
      } else {
        // Expand to include the other one, and remove it
        if (cr.x0<x0) x0 = cr.x0;
        if (cr.x1>x1) x1 = cr.x1;
        if (clipRangeCount-->1)
          clipRanges[i--] = clipRanges[clipRangeCount];
      }
    }
    if (x0>clip0 && x1<clip1) {
      if (x1-x0>4.0/320) { // Only add a clip range if it's wider than these many original doom pixels
        if (clipRangeCount==clipRanges.length) {
          print("Adding cliprange");
          clipRanges.add(new ClipRange(x0, x1));
        }
        else clipRanges[clipRangeCount++].set(x0, x1);
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