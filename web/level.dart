part of Dark;

class BlockCell {
  List<Entity> blockers = new List<Entity>();
  List<Entity> pickups = new List<Entity>();
  
  BlockCell(WAD.BlockCell data) {
  }
}

class Blockmap {
  // Changing this DOES NOT WORK yet
  static const int BLOCKMAP_WIDTH = 128;
  
  int x;
  int y;
  int width;
  int height;

  List<BlockCell> blockCells;
  
  Blockmap(WAD.Blockmap data) {
    this.x = data.x;
    this.y = data.y;
    this.width = data.width;
    this.height = data.height;
    blockCells = new List<BlockCell>(width * height);
    for (int i = 0; i < width * height; i++) {
      BlockCell bc = blockCells[i] = new BlockCell(data.blockCells[i]);
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

class PerformLater {
  double time;
  Function toPerform;
  
  PerformLater(this.time, this.toPerform);
}

class Level {
  WAD.Level levelData;
  
  List<Sector> sectors;
  List<Segment> segments;
  List<Sidedef> sidedefs;
  List<SubSector> subSectors;
  List<Wall> walls;
  BSP bsp;
  
  List<PlayerSpawn> playerSpawns = new List<PlayerSpawn>(4);
  List<PlayerSpawn> deathmatchSpawns = new List<PlayerSpawn>();
  List<Entity> entities = new List<Entity>();
  Blockmap blockmap;
  
  HashMap<int, List<Sector>> sectorsWithTag = new HashMap<int, List<Sector>>();

  Level(this.levelData) {
    sectors = new List<Sector>(levelData.sectors.length);
    walls = new List<Wall>(levelData.linedefs.length);
    sidedefs = new List<Sidedef>(levelData.sidedefs.length);
    subSectors = new List<SubSector>(levelData.sSectors.length);
    segments = new List<Segment>(levelData.segs.length);
    
    for (int i=0; i<sectors.length; i++) {
      sectors[i] = new Sector(this, levelData.sectors[i]);
      if (!sectorsWithTag.containsKey(sectors[i].data.tag)) {
        sectorsWithTag[sectors[i].data.tag] = new List<Sector>();
      }
      sectorsWithTag[sectors[i].data.tag].add(sectors[i]);
    }
    for (int i=0; i<sidedefs.length; i++) {
      sidedefs[i] = new Sidedef(this, levelData.sidedefs[i]);
    }
    for (int i=0; i<walls.length; i++) {
      walls[i] = new Wall(this, levelData.linedefs[i]);
    }
    for (int i=0; i<segments.length; i++) {
      segments[i] = new Segment(this, levelData.segs[i]);
    }
    for (int i=0; i<subSectors.length; i++) {
      subSectors[i] = new SubSector(this, levelData.sSectors[i]);
    }
    for (int i=0; i<sectors.length; i++) {
      sectors[i].findNeighbors(segments);
    }
    

    blockmap = new Blockmap(levelData.blockmap);
    bsp = new BSP(this);
    
    for (int i=0; i<levelData.things.length; i++) {
      loadThing(levelData.things[i]);
    }
  }

  List<PerformLater> toPerformLater = new List<PerformLater>();

  void performLater(double time, Function toPerform) {
    toPerformLater.add(new PerformLater(time, toPerform));
  }
  
  
  List<Sector> getSectorsWithTag(int tag) {
    return sectorsWithTag.containsKey(tag)?sectorsWithTag[tag]:new List<Sector>();
  }
  
  void loadThing(WAD.Thing thing) {
    Vector3 spritePos = new Vector3(thing.x.toDouble(), 20.0, thing.y.toDouble());
    Sector sector = bsp.findSector(spritePos.x, spritePos.z);
    spritePos.y = sector.floorHeight;
    double rot = ((90-thing.angle-22)~/45)*PI*2/8.0;
    
    switch (thing.type) { 
      case 0x0001: playerSpawns[0] = new PlayerSpawn(spritePos, rot); break; // Spawn 1
      case 0x0002: playerSpawns[1] = new PlayerSpawn(spritePos, rot); break; // Spawn 2
      case 0x0003: playerSpawns[2] = new PlayerSpawn(spritePos, rot); break; // Spawn 3
      case 0x0004: playerSpawns[3] = new PlayerSpawn(spritePos, rot); break; // Spawn 4
      case 0x000b: deathmatchSpawns.add(new PlayerSpawn(spritePos, rot));  break; // Multiplayer spawn
      case 0x0bbc: entities.add(new Monster("POSS", this, spritePos, rot)); break; // Former Human
      case 0x0054: entities.add(new Monster("SSWV", this, spritePos, rot)); break; // Wolfenstein SS
      case 0x0009: entities.add(new Monster("SPOS", this, spritePos, rot)); break; // Former Human Seargeant
      case 0x0041: entities.add(new Monster("CPOS", this, spritePos, rot)); break; // Heavy Weapon Dude
      case 0x0bb9: entities.add(new Monster("TROO", this, spritePos, rot)); break; // Imp 
      case 0x0bba: entities.add(new Monster("SARG", this, spritePos, rot)); break; // Demon
      case 0x003a: entities.add(new Monster("SARG", this, spritePos, rot, true)); break; // Spectre
      case 0x0bbe: entities.add(new Monster("SKUL", this, spritePos, rot)); break; // Lost soul
      case 0x0bbd: entities.add(new Monster("HEAD", this, spritePos, rot)); break; // Cacodemon
      case 0x0045: entities.add(new Monster("BOS2", this, spritePos, rot)); break; // Hell Knight
      case 0x0bbb: entities.add(new Monster("BOSS", this, spritePos, rot)); break; // Baron of Hell
      case 0x0044: entities.add(new Monster("BSPI", this, spritePos, rot)); break; // Arachnotron
      case 0x0047: entities.add(new Monster("PAIN", this, spritePos, rot)); break; // Pain elemental
      case 0x0042: entities.add(new Monster("SKEL", this, spritePos, rot)); break; // Revenant
      case 0x0043: entities.add(new Monster("FATT", this, spritePos, rot)); break; // Mancubus
      case 0x0040: entities.add(new Monster("VILE", this, spritePos, rot)); break; // Arch-vile
      case 0x0007: entities.add(new Monster("SPID", this, spritePos, rot)); break; // Spider Mastermind
      case 0x0010: entities.add(new Monster("CYBR", this, spritePos, rot)); break; // Cyber-demon
      case 0x0058: entities.add(new Monster("BBRN", this, spritePos, rot)); break; // Romero
      
      case 0x07d5: entities.add(new Pickup("CSAW", "a", this, spritePos, rot)); break; //     $ Chainsaw
      case 0x07d1: entities.add(new Pickup("SHOT", "a", this, spritePos, rot)); break; //      $ Shotgun
      case 0x0052: entities.add(new Pickup("SGN2", "a", this, spritePos, rot)); break; //      $ Double-barreled shotgun
      case 0x07d2: entities.add(new Pickup("MGUN", "a", this, spritePos, rot)); break; //      $ Chaingun, gatling gun, mini-gun, whatever
      case 0x07d3: entities.add(new Pickup("LAUN", "a", this, spritePos, rot)); break; //      $ Rocket launcher
      case 0x07d4: entities.add(new Pickup("PLAS", "a", this, spritePos, rot)); break; //      $ Plasma gun
      case 0x07d6: entities.add(new Pickup("BFUG", "a", this, spritePos, rot)); break; //      $ Bfg9000
      case 0x07d7: entities.add(new Pickup("CLIP", "a", this, spritePos, rot)); break; //      $ Ammo clip
      case 0x07d8: entities.add(new Pickup("SHEL", "a", this, spritePos, rot)); break; //      $ Shotgun shells
      case 0x07da: entities.add(new Pickup("ROCK", "a", this, spritePos, rot)); break; //      $ A rocket
      case 0x07ff: entities.add(new Pickup("CELL", "a", this, spritePos, rot)); break; //      $ Cell charge
      case 0x0800: entities.add(new Pickup("AMMO", "a", this, spritePos, rot)); break; //      $ Box of Ammo
      case 0x0801: entities.add(new Pickup("SBOX", "a", this, spritePos, rot)); break; //      $ Box of Shells
      case 0x07fe: entities.add(new Pickup("BROK", "a", this, spritePos, rot)); break; //      $ Box of Rockets
      case 0x0011: entities.add(new Pickup("CELP", "a", this, spritePos, rot)); break; //      $ Cell charge pack
      case 0x0008: entities.add(new Pickup("BPAK", "a", this, spritePos, rot)); break; //      $ Backpack: doubles maximum ammo capacities
      case 0x07db: entities.add(new Pickup("STIM", "a", this, spritePos, rot)); break; //      $ Stimpak
      case 0x07dc: entities.add(new Pickup("MEDI", "a", this, spritePos, rot)); break; //      $ Medikit
      case 0x07de: entities.add(new Pickup("BON1", "abcdcb", this, spritePos, rot)); break; // ! Health Potion +1% health
      case 0x07df: entities.add(new Pickup("BON2", "abcdcb", this, spritePos, rot)); break; // ! Spirit Armor +1% armor
      case 0x07e2: entities.add(new Pickup("ARM1", "ab", this, spritePos, rot)); break; //     $ Green armor 100%
      case 0x07e3: entities.add(new Pickup("ARM2", "ab", this, spritePos, rot)); break; //     $ Blue armor 200%
      case 0x0053: entities.add(new Pickup("MEGA", "abcd", this, spritePos, rot)); break; //   ! Megasphere: 200% health, 200% armor
      case 0x07dd: entities.add(new Pickup("SOUL", "abcdcb", this, spritePos, rot)); break; // ! Soulsphere, Supercharge, +100% health
      case 0x07e6: entities.add(new Pickup("PINV", "abcd", this, spritePos, rot)); break; //   ! Invulnerability
      case 0x07e7: entities.add(new Pickup("PSTR", "a", this, spritePos, rot)); break; //      ! Berserk Strength and 100% health
      case 0x07e8: entities.add(new Pickup("PINS", "abcd", this, spritePos, rot)); break; //   ! Invisibility
      case 0x07e9: entities.add(new Pickup("SUIT", "a", this, spritePos, rot)); break; //     (!)Radiation suit - see notes on ! above
      case 0x07ea: entities.add(new Pickup("PMAP", "abcdcb", this, spritePos, rot)); break; // ! Computer map
      case 0x07fd: entities.add(new Pickup("PVIS", "ab", this, spritePos, rot)); break; //     ! Lite Amplification goggles
      case 0x0005: entities.add(new Pickup("BKEY", "ab", this, spritePos, rot)); break; //     $ Blue keycard
      case 0x0028: entities.add(new Pickup("BSKU", "ab", this, spritePos, rot)); break; //     $ Blue skullkey
      case 0x000d: entities.add(new Pickup("RKEY", "ab", this, spritePos, rot)); break; //     $ Red keycard
      case 0x0026: entities.add(new Pickup("RSKU", "ab", this, spritePos, rot)); break; //     $ Red skullkey
      case 0x0006: entities.add(new Pickup("YKEY", "ab", this, spritePos, rot)); break; //     $ Yellow keycard
      case 0x0027: entities.add(new Pickup("YSKU", "ab", this, spritePos, rot)); break; //     $ Yellow skullkey
      
      
      case 0x000a: entities.add(new Decoration("PLAY", "w", this, spritePos, rot)); break; // Bloody mess (an exploded player)
      case 0x000c: entities.add(new Decoration("PLAY", "w", this, spritePos, rot)); break; // 
      case 0x0018: entities.add(new Decoration("POL5", "a", this, spritePos, rot)); break; // Pool of blood and flesh
      case 0x004f: entities.add(new Decoration("POB1", "a", this, spritePos, rot)); break; // Pool of blood
      case 0x0050: entities.add(new Decoration("POB2", "a", this, spritePos, rot)); break; // Pool of blood
      case 0x0051: entities.add(new Decoration("BRS1", "a", this, spritePos, rot)); break; // Pool of brains
      case 0x000f: entities.add(new Decoration("PLAY", "n", this, spritePos, rot)); break; // Dead player
      case 0x0012: entities.add(new Decoration("POSS", "l", this, spritePos, rot)); break; // Dead former human
      case 0x0013: entities.add(new Decoration("SPOS", "l", this, spritePos, rot)); break; // Dead former sergeant
      case 0x0014: entities.add(new Decoration("TROO", "m", this, spritePos, rot)); break; // Dead imp
      case 0x0015: entities.add(new Decoration("SARG", "n", this, spritePos, rot)); break; // Dead demon
      case 0x0016: entities.add(new Decoration("HEAD", "l", this, spritePos, rot)); break; // Dead cacodemon
      case 0x0017: entities.add(new Decoration("SKUL", "k", this, spritePos, rot)); break; // Dead lost soul, invisible 

      case 0x0030: entities.add(new Decoration.blocking("ELEC", "a", this, spritePos, rot)); break; //      # Tall, techno pillar
      case 0x001e: entities.add(new Decoration.blocking("COL1", "a", this, spritePos, rot)); break; //      # Tall green pillar
      case 0x0020: entities.add(new Decoration.blocking("COL3", "a", this, spritePos, rot)); break; //      # Tall red pillar
      case 0x001f: entities.add(new Decoration.blocking("COL2", "a", this, spritePos, rot)); break; //      # Short green pillar
      case 0x0024: entities.add(new Decoration.blocking("COL5", "ab", this, spritePos, rot)); break; //     # Short green pillar with beating heart
      case 0x0021: entities.add(new Decoration.blocking("COL4", "a", this, spritePos, rot)); break; //      # Short red pillar
      case 0x0025: entities.add(new Decoration.blocking("COL6", "a", this, spritePos, rot)); break; //      # Short red pillar with skull
      case 0x002f: entities.add(new Decoration.blocking("SMIT", "a", this, spritePos, rot)); break; //      # Stalagmite: small brown pointy stump
      case 0x002b: entities.add(new Decoration.blocking("TRE1", "a", this, spritePos, rot)); break; //      # Burnt tree: gray tree
      case 0x0036: entities.add(new Decoration.blocking("TRE2", "a", this, spritePos, rot)); break; //      # Large brown tree
      case 0x07ec: entities.add(new Decoration.blocking("COLU", "a", this, spritePos, rot)); break; //      # Floor lamp
      case 0x0055: entities.add(new Decoration.blocking("TLMP", "abcd", this, spritePos, rot)); break; //   # Tall techno floor lamp
      case 0x0056: entities.add(new Decoration.blocking("TLP2", "abcd", this, spritePos, rot)); break; //   # Short techno floor lamp
      case 0x0022: entities.add(new Decoration.blocking("CAND", "a", this, spritePos, rot)); break; //        Candle
      case 0x0023: entities.add(new Decoration.blocking("CBRA", "a", this, spritePos, rot)); break; //      # Candelabra
      case 0x002c: entities.add(new Decoration.blocking("TBLU", "abcd", this, spritePos, rot)); break; //   # Tall blue firestick
      case 0x002d: entities.add(new Decoration.blocking("TGRE", "abcd", this, spritePos, rot)); break; //   # Tall green firestick
      case 0x002e: entities.add(new Decoration.blocking("TRED", "abcd", this, spritePos, rot)); break; //   # Tall red firestick
      case 0x0037: entities.add(new Decoration.blocking("SMBT", "abcd", this, spritePos, rot)); break; //   # Short blue firestick
      case 0x0038: entities.add(new Decoration.blocking("SMGT", "abcd", this, spritePos, rot)); break; //   # Short green firestick
      case 0x0039: entities.add(new Decoration.blocking("SMRT", "abcd", this, spritePos, rot)); break; //   # Short red firestick
      case 0x0046: entities.add(new Decoration.blocking("FCAN", "abc", this, spritePos, rot)); break; //    # Burning barrel
      case 0x0029: entities.add(new Decoration.blocking("CEYE", "abcb", this, spritePos, rot)); break; //   # Evil Eye: floating eye in symbol, over candle
      case 0x002a: entities.add(new Decoration.blocking("FSKU", "abc", this, spritePos, rot)); break; //    # Floating Skull: flaming skull-rock
      case 0x0031: entities.add(new Decoration.blocking("GOR1", "abcb", this, spritePos, rot)..hanging = true); break; //  ^# Hanging victim, twitching
      case 0x003f: entities.add(new Decoration.blocking("GOR1", "abcb", this, spritePos, rot)..hanging = true); break; //  ^  Hanging victim, twitching
      case 0x0032: entities.add(new Decoration.blocking("GOR2", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging victim, arms out
      case 0x003b: entities.add(new Decoration.blocking("GOR2", "a", this, spritePos, rot)..hanging = true); break; //     ^  Hanging victim, arms out
      case 0x0034: entities.add(new Decoration.blocking("GOR4", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging pair of legs
      case 0x003c: entities.add(new Decoration.blocking("GOR4", "a", this, spritePos, rot)..hanging = true); break; //     ^  Hanging pair of legs
      case 0x0033: entities.add(new Decoration.blocking("GOR3", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging victim, 1-legged
      case 0x003d: entities.add(new Decoration.blocking("GOR3", "a", this, spritePos, rot)..hanging = true); break; //     ^  Hanging victim, 1-legged
      case 0x0035: entities.add(new Decoration.blocking("GOR5", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging leg
      case 0x003e: entities.add(new Decoration.blocking("GOR5", "a", this, spritePos, rot)..hanging = true); break; //     ^  Hanging leg
      case 0x0049: entities.add(new Decoration.blocking("HDB1", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging victim, guts removed
      case 0x004a: entities.add(new Decoration.blocking("HDB2", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging victim, guts and brain removed
      case 0x004b: entities.add(new Decoration.blocking("HDB3", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging torso, looking down
      case 0x004c: entities.add(new Decoration.blocking("HDB4", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging torso, open skull
      case 0x004d: entities.add(new Decoration.blocking("HDB5", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging torso, looking up
      case 0x004e: entities.add(new Decoration.blocking("HDB6", "a", this, spritePos, rot)..hanging = true); break; //     ^# Hanging torso, brain removed
      case 0x0019: entities.add(new Decoration.blocking("POL1", "a", this, spritePos, rot)); break; //      # Impaled human
      case 0x001a: entities.add(new Decoration.blocking("POL6", "ab", this, spritePos, rot)); break; //     # Twitching impaled human
      case 0x001b: entities.add(new Decoration.blocking("POL4", "a", this, spritePos, rot)); break; //      # Skull on a pole
      case 0x001c: entities.add(new Decoration.blocking("POL2", "a", this, spritePos, rot)); break; //      # 5 skulls shish kebob
      case 0x001d: entities.add(new Decoration.blocking("POL3", "ab", this, spritePos, rot)); break; //     # Pile of skulls and candles
      
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
  
  void tick(double passedTime) {
    for (int i=0; i<sectors.length; i++) {
      sectors[i].tick(passedTime);
    }
    for (int i=0; i<toPerformLater.length; i++) {
      if ((toPerformLater[i].time-=passedTime)<=0.0) {
        toPerformLater[i].toPerform();
        toPerformLater.removeAt(i--);
      }
    }
  }
  HitResult hitscan(Vector3 pos, Vector3 dir, bool scanForEnemies) {
    return bsp.hitscan(pos, dir, scanForEnemies);
  }
}

class Segment {
  WAD.Seg data;
  
  Vector2 startVertex, endVertex;
  double x0, y0;
  double x1, y1;
  Sector sector;
  Sector backSector;
  Sidedef sidedef;
  Wall wall;
  double offset;
  double length;
  double xn, yn;
  double xt, yt;
  double d;
  double brightness;
  double dir;
  
  double sortDistance;
  double lowDistance, highDistance;
  
  Segment(Level level, this.data) {
    this.x0 = data.startVertex.x+0.0;
    this.y0 = data.startVertex.y+0.0;
    this.x1 = data.endVertex.x+0.0;
    this.y1 = data.endVertex.y+0.0;
    
    startVertex = new Vector2(x0, y0);
    endVertex = new Vector2(x1, y1);
    
    Vector2 tangent = (endVertex-startVertex).normalize();
    xt = tangent.x;
    yt = tangent.y;

    xn = tangent.y;
    yn = -tangent.x;
    
    d = x0*xn+y0*yn;
    
    dir = atan2(xn, yn);
    
    brightness = 1.0;
    if (yn*yn>0.99*0.99) {
      brightness = 0.9;      
    }
    if (xn*xn>0.99*0.99) {
      brightness = 1.1;      
    }
//    if (brightness>1.0) brightness=2.0-brightness;
    
    
    offset = data.offset+0.0;
    length = startVertex.distanceTo(endVertex).floorToDouble();
    
    wall = level.walls[data.linedefId];
    sidedef = level.sidedefs[data.frontSidedefId];
    
    sector = level.sectors[data.sidedef.sectorId];
    if (data.backSidedef != null) {
      backSector = level.sectors[data.backSidedef.sectorId];
    }
  }
  
  void renderWalls() {
    WallRenderer.addWallsForSeg(this);
  }
}

class Wall {
  int checkCounterHack;
  WAD.Linedef data;
  
  Sector leftSector;
  Sector rightSector;
  
  Vector2 startVertex, endVertex;
  Sidedef leftSidedef;
  Sidedef rightSidedef;

  double x0, y0, x1, y1;
  double xn, yn, xt, yt;
  double xc, yc;
  double d, sd;
  double length;
  
  bool triggerUsable = true;
  
  Wall(Level level, this.data) {
    if (data.leftSectorId!=-1) leftSector = level.sectors[data.leftSectorId];
    if (data.rightSectorId!=-1) rightSector = level.sectors[data.rightSectorId];
    if (data.leftSidedefId!=-1) leftSidedef = level.sidedefs[data.leftSidedefId];
    if (data.rightSidedefId!=-1) rightSidedef = level.sidedefs[data.rightSidedefId];

    startVertex = new Vector2(data.fromVertex.x+0.0, data.fromVertex.y+0.0);
    endVertex = new Vector2(data.toVertex.x+0.0, data.toVertex.y+0.0);
    x0 = startVertex.x;
    y0 = startVertex.y;
    x1 = endVertex.x;
    y1 = endVertex.y;
    
    xc = (x0+x1)/2.0;
    yc = (y0+y1)/2.0;
    
    
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
  }
  
  void triggerSwitch(Wall wall, bool rightSide, LinedefTrigger trigger) {
    Sidedef s = rightSide?wall.rightSidedef:wall.leftSidedef;
    Sector sector = rightSide?wall.rightSector:wall.leftSector; 
    bool changed = s.setSwitchTextures(true);
    
    if (changed) {
      double yc = (sector.floorHeight+sector.ceilingHeight)/2.0;
      Vector3 pos = new Vector3(wall.xc, yc, wall.yc);
      playSound(pos, "SWTCHN", uniqueId: wall);
      if (!trigger.once) level.performLater(35.0/35.0, ()=>untriggerSwitch(wall, rightSide, trigger));
    }
  }
  
  void untriggerSwitch(Wall wall, bool rightSide, LinedefTrigger trigger) {
    Sidedef s = rightSide?wall.rightSidedef:wall.leftSidedef;
    s.setSwitchTextures(false);
  }
}

class Sidedef {
  WAD.Sidedef data;
  
  Image middleTexture, upperTexture, lowerTexture;
  double xTextureOffs, yTextureOffs;
  
  Sidedef(Level level, this.data) {
    middleTexture = resources.wallTextures.containsKey(data.middleTexture)?resources.wallTextures[data.middleTexture]:null; 
    upperTexture = resources.wallTextures.containsKey(data.upperTexture)?resources.wallTextures[data.upperTexture]:null;
    lowerTexture = resources.wallTextures.containsKey(data.lowerTexture)?resources.wallTextures[data.lowerTexture]:null;
    xTextureOffs = data.xTextureOffs+0.0;
    yTextureOffs = data.yTextureOffs+0.0;
  }
  
  bool setSwitchTextures(bool on) {
    bool changed = false;
    String lowerTextureName = getSwitchTextureName(lowerTexture, on);
    String middleTextureName = getSwitchTextureName(middleTexture, on);
    String upperTextureName = getSwitchTextureName(upperTexture, on);
    if (lowerTextureName!=null) { 
      lowerTexture = resources.wallTextures.containsKey(lowerTextureName)?resources.wallTextures[lowerTextureName]:null;
      changed = true;
    }
    if (middleTextureName!=null) { 
      middleTexture = resources.wallTextures.containsKey(middleTextureName)?resources.wallTextures[middleTextureName]:null;
      changed = true;
    }
    if (upperTextureName!=null) { 
      upperTexture = resources.wallTextures.containsKey(upperTextureName)?resources.wallTextures[upperTextureName]:null;
      changed = true;
    }
    return changed;
  }
  
  String getSwitchTextureName(Image image, bool on) {
    if (image == null) return null;
    if (on && image.name.length>3 && image.name.startsWith("SW1"))  return "SW2${image.name.substring(3)}";
    if (!on && image.name.length>3 && image.name.startsWith("SW2"))  return "SW1${image.name.substring(3)}";
    return null;
  }
}

class Sector {
  WAD.Sector data;
  
  double floorHeight, ceilingHeight;
  Image floorTexture, ceilingTexture;
  double lightLevel;
  List<Entity> entities = new List<Entity>();
  List<Sector> neighborSectors;
  double originalLightLevel;
  double darkestNeighbor;

  double lightChangeAccum = 0.0;
  int lightOffset = 0;

  SectorEffect effect = null;
  Vector3 centerPos;
  LinedefTrigger onlyTriggerableBy = null;

  Sector(Level level, this.data) {
    floorHeight = data.floorHeight+0.0;
    ceilingHeight = data.ceilingHeight+0.0;
    floorTexture = resources.flats[data.floorTexture];
    ceilingTexture = resources.flats[data.ceilingTexture];
    originalLightLevel = lightLevel = data.lightLevel/255.0;
    
    lightOffset = random.nextInt(8);
  }
  
  void findNeighbors(List<Segment> segments) {
    HashSet<Sector> neighbors = new HashSet();
    double x0 = 100000000000.0;
    double x1 = -100000000000.0;
    double y0 = 100000000000.0;
    double y1 = -100000000000.0;
    segments.forEach((segment) {
      if (segment.sector==this) {
        if (segment.x0<x0) x0 = segment.x0;
        if (segment.y0<y0) y0 = segment.y0;
        if (segment.x0>x1) x1 = segment.x0;
        if (segment.y0>y1) y1 = segment.y0;
        if (segment.backSector!=null) neighbors.add(segment.backSector);
      }
    });
    neighborSectors = new List<Sector>.from(neighbors);
    darkestNeighbor = lightLevel;
    neighborSectors.forEach((sector) {
      if (sector.lightLevel<darkestNeighbor) {
        darkestNeighbor = sector.lightLevel;
      }
    });
    if (darkestNeighbor>=lightLevel) {
      if (data.special!=0x08) darkestNeighbor = 0.0; // Pulsating lights should not change
    }
    centerPos = new Vector3((x1+x0)/2.0, floorHeight, (y0+y1)/2.0);
  }
  
  void endEffect() {
    this.effect = null;
  }
  
  void setEffect(SectorEffect effect) {
    if (this.effect == null) {
      this.effect = effect;
      if (effect!=null) effect.start(this);
    } else {
      this.effect.replaceWithEffect(effect);
    }
  }

  void tick(double passedTime) {
    if (effect!=null) effect.tick(passedTime);
    if (data.special==0x01) {
      lightChangeAccum+=passedTime*35.0/4.0;
      int ticks = 0;
      ticks = lightChangeAccum.floor();
      lightChangeAccum-=ticks;
      if (ticks>0) {
        lightLevel = random.nextInt(5)==0?darkestNeighbor:originalLightLevel;
      }
    }
    if (data.special==0x08) {
      lightChangeAccum+=passedTime*20.0/35.0;
      lightChangeAccum-=lightChangeAccum.floorToDouble();
      double t = lightChangeAccum*2.0;
      if (t>1.0) t = 2.0-t;
      lightLevel = darkestNeighbor+(originalLightLevel-darkestNeighbor)*t;
    }
    if (data.special==0x02 || data.special==0x03 || data.special==0x04 || data.special==0x0c || data.special==0x0d) {
      lightChangeAccum+=passedTime*31.0/35.0;
      if (data.special==0x02 || data.special==0x04 || data.special==0x0c) {
        lightChangeAccum+=passedTime*31.0/35.0;
      }
      lightChangeAccum-=lightChangeAccum.floor();
      int tick = ((lightChangeAccum*31.0).floor());
      if (data.special<0x0c) tick+=lightOffset;
      lightLevel = (tick%31)>4?darkestNeighbor:originalLightLevel;
    }
    // 0x04 hurt player 20% (+ light above)
    // 0x05 hurt player 10%
    // 0x07 hurt player 5%
    // 0x09 secret
    // 0x0a close after 30 seconds
    // 0x0b hurt 20%, switch level if health is < 11%
    // 0x0e open after 300 seconds
    // 0x10 hurt player 20%
  }
}

class SubSector {
  Sector sector;
  int segCount;
  List<Segment> segs;
  List<Sector> backSectors;
  List<Wall> walls;
  int sortedSubSectorId;

  SubSector(Level level, WAD.SSector sSector) {
    WAD.Level levelData = level.levelData;
    WAD.Seg seg = levelData.segs[sSector.segStart];
    WAD.Linedef linedef = levelData.linedefs[seg.linedefId];
    WAD.Sidedef sidedef = levelData.sidedefs[seg.direction == 0 ? linedef.rightSidedefId : linedef.leftSidedefId];
    sector = level.sectors[sidedef.sectorId];

    segCount = sSector.segCount;
    backSectors = new List<Sector>(segCount);

    segs = new List<Segment>(segCount);

    HashSet<Wall> wallSet = new HashSet<Wall>();
    for (int i = 0; i < sSector.segCount; i++) {
      Segment segment = level.segments[sSector.segStart + i];
      wallSet.add(segment.wall);
      int backSidedef = seg.direction != 0 ? linedef.rightSidedefId : linedef.leftSidedefId;
      if (backSidedef != -1) {
        backSectors[i] = level.sectors[levelData.sidedefs[backSidedef].sectorId];
      }
      segs[i] = segment;
    }

    walls = new List<Wall>.from(wallSet);
  }
}