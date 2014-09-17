part of Dark;

class PlayerSpawn {
  Vector3 pos;
  double rot;
  
  PlayerSpawn(this.pos, this.rot);
}

class EntityBlockerType {
  static const NONE = const EntityBlockerType._(0);
  static const BLOCKING = const EntityBlockerType._(1);
  static const PICKUP = const EntityBlockerType._(2);

  final int type;
  const EntityBlockerType._(this.type);
}

class Entity {
  Level level;
  Vector3 pos;
  double radius = 16.0;
  double height = 56.0;
  double rot = 0.0;
  SpriteTemplate spriteTemplate;
  bool transparent = false;
  int animFrame = 0;
  bool hanging = false;
  bool shouldAimAt = false;
  bool bleeds = false;
  bool removed = false;
  bool collided = false;
  bool fullBright = false;
  Sector inSector;
  Set<Sector> inSectors = new Set<Sector>();
    
  EntityBlockerType blockerType = EntityBlockerType.BLOCKING;
  
  BlockCell blockCell;
  
  Entity(this.level, this.pos, this.blockerType) {
    inSector = level.bsp.findSector(pos.x, pos.z);
//    inSector.entities.add(this);
    inSectors = level.bsp.findSectorsInRadius(pos.x, pos.z, radius*0.9);
    inSectors.forEach((s)=>s.entities.add(this));

    if (blockerType!=EntityBlockerType.NONE) {
      blockCell = level.blockmap.getBlockCell(pos.x, pos.z);
      if (blockCell!=null) {
        if (blockerType==EntityBlockerType.BLOCKING) blockCell.blockers.add(this);
        if (blockerType==EntityBlockerType.PICKUP) blockCell.pickups.add(this);
      }
    }
  }
  
  void tick(double passedTime) {
  }
  
  void addToDisplayList(double playerRot) {
    if (spriteTemplate==null) return;
    
    double rotDiff = rot - playerRot+PI;
    int rotFrame = (rotDiff * 8 / (PI * 2) + 0.5).floor() & 7;
    SpriteTemplateFrame stf = spriteTemplate.frames[animFrame];
    if (stf.rots.length == 1) rotFrame = 0;
    SpriteTemplateRot str = stf.rots[rotFrame];

/*  int closestSubSectorId = inSubSectors[0].sortedSubSectorId;
    for (int i=1; i<inSubSectors.length; i++) {
      if (closestSubSectorId>inSubSectors[i].sortedSubSectorId) closestSubSectorId = inSubSectors[i].sortedSubSectorId;
    }*/
    double br = fullBright?1.0:inSector.lightLevel;
    
    if (transparent) {
      renderers.transparentSpriteMaps[str.image.imageAtlas.texture].insertSprite(br, pos, str);
    } else {
      renderers.spriteMaps[str.image.imageAtlas.texture].insertSprite(br, pos, str);
    }
  }
  
  void remove() {
    if (removed) return;
    
    if (blockerType==EntityBlockerType.BLOCKING) {
      if (blockCell!=null) blockCell.blockers.remove(this);
    } else if (blockerType==EntityBlockerType.PICKUP) {
      if (blockCell!=null) blockCell.pickups.remove(this);
    }
    inSectors.forEach((s)=>s.entities.remove(this));
    stopSoundAtUniqueId(this);
    
    removed = true;
  }
  
  static int checkCounterHack = 0;
  static List<BlockCell> tmpBlockCells = new List<BlockCell>();
  static Set<Wall> tmpLinedefs = new Set<Wall>();
  static List<SubSector> tmpSubSectorsInRange = new List<SubSector>();
  static Set<Sector> tmpSectorsInRange = new Set<Sector>();
  static Set<Wall> tmpWallsInRange = new Set<Wall>();

  void clipMove(Vector3 motion, double passedTime, HashSet<Sector> sectorsInRange) {
    double oldx = pos.x;
    double oldy = pos.z;
    int steps = (motion.length/(radius/3.0)).floor()+1;
    tmpWallsInRange.clear();
    
    for (int i=0; i<steps; i++) {
      checkCounterHack++;
      pos.x+=motion.x*(passedTime/steps);
      pos.z+=motion.z*(passedTime/steps);

      level.blockmap.getBlockCellsRadius(pos.x, pos.z, radius+64.0, tmpBlockCells);
      for (int i=0; i<tmpBlockCells.length; i++) {
        collideAgainstEntitiesIn(tmpBlockCells[i]);
      }

      tmpSubSectorsInRange.clear();
      level.bsp.findSubSectorsInRadius(pos.x, pos.z, radius, tmpSubSectorsInRange);
      for (int i=0; i<tmpSubSectorsInRange.length; i++) {
        SubSector ss = tmpSubSectorsInRange[i];
        for (int j=0; j<ss.walls.length; j++) {
          Wall ld = ss.walls[j];
          if (ld.checkCounterHack != checkCounterHack) {
            ld.checkCounterHack = checkCounterHack;
            if (!clipMotion(ld, sectorsInRange)) {
              if (ld.data.type>=0) tmpWallsInRange.add(ld);
            }
          }
        }
      }
    }
    
    tmpWallsInRange.forEach((wall) {
      double oldDist = oldx*wall.xn+oldy*wall.yn;
      double newDist = pos.x*wall.xn+pos.z*wall.yn;
      if ((oldDist<wall.d && newDist>=wall.d)||
          (oldDist>=wall.d && newDist<wall.d)) {
        passWall(wall);
      }
    });
    
    inSector = level.bsp.findSector(pos.x,  pos.z);
    
    tmpSectorsInRange.clear();
    tmpSectorsInRange.addAll(sectorsInRange);
    tmpSectorsInRange.add(inSector);
    
    inSectors.difference(tmpSectorsInRange).forEach((s)=>s.entities.remove(this));
    tmpSectorsInRange.difference(inSectors).forEach((s)=>s.entities.add(this));
    inSectors.clear();
    inSectors.addAll(tmpSectorsInRange);

    if (blockerType==EntityBlockerType.BLOCKING) {
      BlockCell newBlockCell = level.blockmap.getBlockCell(pos.x, pos.z);
      if (blockCell!=newBlockCell) {
        if (blockCell!=null) blockCell.blockers.remove(this);
        blockCell = newBlockCell;
        if (blockCell!=null) blockCell.blockers.add(this);
      }
    } else if (blockerType==EntityBlockerType.PICKUP) {
      BlockCell newBlockCell = level.blockmap.getBlockCell(pos.x, pos.z);
      if (blockCell!=newBlockCell) {
        if (blockCell!=null) blockCell.pickups.remove(this);
        blockCell = newBlockCell;
        if (blockCell!=null) blockCell.pickups.add(this);
      }
    }
  }
  
  void passWall(Wall wall) {
  }

  void collideAgainstEntitiesIn(BlockCell bc) {
    for (int j=0; j<bc.blockers.length; j++) {
      Entity e = bc.blockers[j];
      if (e!=this) clipMotionEntity(e);
    }
  }
  
  bool canEnterSector(Sector sector) {
    if (sector.floorHeight>pos.y+24) return false;
    if (sector.ceilingHeight<pos.y+height) return false;
    if (sector.ceilingHeight-sector.floorHeight<height) return false;
    return true;
  }
  
  void clipMotionEntity(Entity e) {
    double xd = pos.x-e.pos.x;
    double yd = pos.z-e.pos.z;
    double len2 = xd*xd+yd*yd;
    double sRad = radius+e.radius;
    if (len2>0.01 && len2<sRad*sRad) {
      double len = sqrt(len2);
      double toPushout = sRad-len;
      pos.x+=xd/len*toPushout;
      pos.z+=yd/len*toPushout;
      collided = true;
    }
  }
  
  bool clipMotion(Wall seg, HashSet<Sector> overlappedSectors) {
    double xp = pos.x;
    double yp = pos.z;

    double xNudge = 0.0;
    double yNudge = 0.0;
    bool intersect = false;

    double d = xp*seg.xn+yp*seg.yn - seg.d;
    double mul = 1.0;
    if (d>=-radius && d<=radius) {
      if (d<0) {
        d=-d;
        mul = -1.0;
      }
      double sd = xp*seg.xt+yp*seg.yt - seg.sd;
      if (sd>=0.0 && sd<=seg.length) {
        // Hit the center of the seg
        double toPushOut = radius-d+0.001;
        xNudge=seg.xn*toPushOut*mul;
        yNudge=seg.yn*toPushOut*mul;
        intersect = true;
      } else {
        // Hit either corner of the linedef
        double xd, yd;
        if (sd<=0.0) {
          xd = xp-seg.x0;
          yd = yp-seg.y0;
        } else {
          xd = xp-seg.x1;
          yd = yp-seg.y1;
        }

        double distSqr = xd*xd+yd*yd;
        if (xd*xd+yd*yd<radius*radius) {
          double dist = sqrt(distSqr);
          double toPushOut = radius-dist+0.001;
          xNudge=xd/dist*toPushOut;
          yNudge=yd/dist*toPushOut;
          intersect = true;
        }
      }
    }

    if (intersect) {
      bool collideWall = false;
      if (seg.data.impassable || seg.leftSector==null) {
        collideWall = true;
      } else if (!canEnterSector(seg.leftSector) || !canEnterSector(seg.rightSector)) {
        collideWall = true;
      }

      if (collideWall) {
        collided = true;
        pos.x += xNudge;
        pos.z += yNudge;
        return true;
      } else {
        if (overlappedSectors!=null) {
          overlappedSectors.add(seg.rightSector);
          if (seg.leftSector!=null) overlappedSectors.add(seg.leftSector);
          return false;
        }
      }
    }
    return false;
  }  
}

class AnimatedStationary extends Entity {
  String frames;
  int animStep = 0;
  double animAccum = 0.0;
  
  AnimatedStationary(String templateName, String frames, Level level, Vector3 pos, double rot, EntityBlockerType blockerType) : super(level, pos, blockerType) {
    frames = frames.toUpperCase();
    this.frames = frames;
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    radius = 16.0;
  }
  
  void tick(double passedTime) {
    int lastAnimStep = animStep;
    animAccum+=passedTime*35.0/6.0;
    animStep+=animAccum.floor();
    animAccum-=animAccum.floor();
    animStep = animStep%frames.length;
    if (lastAnimStep!=animStep) {
      animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    }
  }
}

class Pickup extends AnimatedStationary {
  Pickup(String templateName, String frames, Level level, Vector3 pos, double rot) : super(templateName, frames, level, pos, rot, EntityBlockerType.PICKUP) {
  }
}

class Decoration extends AnimatedStationary {
  Decoration(String templateName, String frames, Level level, Vector3 pos, double rot, [EntityBlockerType blockerType = EntityBlockerType.NONE]) : super(templateName, frames, level, pos, rot, blockerType)  {
  }

  factory Decoration.blocking(String templateName, String frames, Level level, Vector3 pos, double rot) {
    Decoration result = new Decoration(templateName, frames, level, pos, rot, EntityBlockerType.BLOCKING);
    result.blockerType = EntityBlockerType.BLOCKING;
    return result;
  }
}

class Puff extends Entity {
  String frames;
  int animStep = 0;
  double animAccum = 0.0;
  double speed = 1.0;
  
  Puff(String templateName, String frames, Level level, Vector3 pos, double rot) : super(level, pos, EntityBlockerType.NONE) {
    frames = frames.toUpperCase();
    this.frames = frames;
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    speed = 1.0/((random.nextDouble()-0.5)*1.0+1.0);
    animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    radius = 16.0;
    fullBright = true;
  }
  
  void tick(double passedTime) {
    int lastAnimStep = animStep;
    animAccum+=passedTime*35.0/4.0*speed;
    animStep+=animAccum.floor();
    animAccum-=animAccum.floor();
    animStep = animStep;
    pos.y+=passedTime*32;
    Sector sector = level.bsp.findSector(pos.x, pos.z);
    if (pos.y>sector.ceilingHeight-4.0) pos.y=sector.ceilingHeight-4.0;
    if (lastAnimStep!=animStep) {
      fullBright = animStep <= 1;

      if (animStep>=frames.length)
        remove();
      else 
        animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    }
  }
}

class Explosion extends Entity {
  String frames;
  int animStep = 0;
  double animAccum = 0.0;
  double speed = 1.0;
  
  Explosion(String templateName, String frames, Level level, Vector3 pos, double rot) : super(level, pos, EntityBlockerType.NONE) {
    frames = frames.toUpperCase();
    this.frames = frames;
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    speed = 1.0/((random.nextDouble()-0.5)*1.0+1.0);
    animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    radius = 16.0;
  }
  
  void tick(double passedTime) {
    int lastAnimStep = animStep;
    animAccum+=passedTime*35.0/4.0*speed;
    animStep+=animAccum.floor();
    animAccum-=animAccum.floor();
    animStep = animStep;
    if (lastAnimStep!=animStep) {
      if (animStep>=frames.length)
        remove();
      else 
        animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    }
  }
}

class Blood extends Entity {
  String frames;
  int animStep = 0;
  double life = 0.0;
  double xa, ya, za;
  
  Blood(String templateName, String frames, Level level, Vector3 pos, double rot) : super(level, pos, EntityBlockerType.NONE) {
    // TODO: Base blood frame on damage amount.
    // Cutoffs are apparently 9 and 12
    frames = frames.toUpperCase();
    this.frames = frames;
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    life = 0.2/((random.nextDouble()-0.5)*1.0+1.0);
    animStep = random.nextInt(frames.length);
    animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    radius = 16.0;
    
    Vector3 spread;
    do {
      spread = new Vector3(random.nextDouble()-0.5, random.nextDouble()-0.5, random.nextDouble()-0.5)*2.0;
    } while (spread.length2>1.0);
    xa = spread.x; 
    ya = spread.y; 
    za = spread.z; 
  }
  
  void tick(double passedTime) {
    life-=passedTime;
    pos.y+=passedTime*ya*100.0;
    ya-=passedTime*5.0;
    Sector sector = level.bsp.findSector(pos.x, pos.z);
    if (pos.y<sector.floorHeight-4.0) pos.y=sector.floorHeight-4.0;
    if (life<0.0) {
      remove();
    }
  }
}

class Projectile extends Entity {
  Entity owner;
  Vector3 dir;
  String frames;
  int animStep;
  double animAccum = 0.0;
  
  Projectile(String templateName, this.frames, Level level, Vector3 pos, this.dir, this.owner) : super(level, pos, EntityBlockerType.NONE) {
    spriteTemplate = spriteTemplates[templateName];
    radius = 8.0;
    height = 8.0;
    rot = atan2(dir.x, dir.z);
    animStep = 0;
    animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    radius = 16.0;
  }
  
  HashSet<Sector> sectorsInRange = new HashSet<Sector>();
  void tick(double passedTime) {
    int lastAnimStep = animStep;
    animAccum+=passedTime*35.0/2.0;
    animStep+=animAccum.floor();
    animAccum-=animAccum.floor();
    animStep = animStep%frames.length;
    if (lastAnimStep!=animStep) {
      animFrame = FRAME_NAMES.indexOf(frames.substring(animStep, animStep+1));
    }

    sectorsInRange.clear();
    clipMove(dir,  passedTime, sectorsInRange);
//    sectorsInRange.add(level.bsp.findSector(pos.x, pos.z));
    inSectors.forEach((sector) {
      if (sector.floorHeight>pos.y) collided = true;
      if (sector.ceilingHeight<pos.y+height) collided = true;
    });
    pos.y+=dir.y*passedTime;
    
    if (collided) {
      hit();
    }
  }
  
  void hit() {
    remove();
  }
  
  void clipMotionEntity(Entity e) {
    if (e!=owner) super.clipMotionEntity(e);
  }
}

class Missile extends Projectile {
  Missile(Level level, Vector3 pos, Vector3 dir, Entity owner) : super("MISL", "A", level, pos, dir, owner) {
    fullBright = true;
  }
  
  void hit() {
    Explosion e = new Explosion("MISL", "BCD", level, pos, rot)..fullBright = true;
    level.entities.add(e);
    playSound(pos, "BAREXP", uniqueId: e);
    remove();
  }
}

class Plasma extends Projectile {
  Plasma(Level level, Vector3 pos, Vector3 dir, Entity owner) : super("PLSS", "AB", level, pos, dir, owner) {
    fullBright = true;
  }
  
  void hit() {
    Explosion e = new Explosion("PLSE", "ABCDE", level, pos, rot)..fullBright = true;
    level.entities.add(e);
    
    playSound(pos, "FIRXPL", uniqueId: e);
    remove();
  }
}

class BfgShot extends Projectile {
  double orgRot;
  double blowUpIn = 0.0;
  BfgShot(Level level, Vector3 pos, Vector3 dir, Entity owner) : super("BFS1", "AB", level, pos, dir, owner) {
    orgRot = owner.rot;
    fullBright = true;
  }

  void tick(double passedTime) {
    if (blowUpIn>0.0) {
      blowUpIn-=passedTime;
      if (blowUpIn<=0.0) {
        int amount = 40;
        for (int i=0; i<amount; i++) {
          Vector3 shootPos = owner.pos+new Vector3(0.0, 32.0, 0.0);
          double rot = orgRot-PI/4+PI/2*i/amount;
          Vector3 dir = new Vector3(sin(rot), 0.0, cos(rot));
  
          HitResult scanResult = level.hitscan(shootPos, dir, true);
          if (scanResult!=null && scanResult.entity!=null) {
            double yAim = scanResult.entity.pos.y+scanResult.entity.height/2.0;
            dir*=(scanResult.entity.pos-shootPos).length;
            dir.y = yAim-shootPos.y;
            dir.normalize();
          }
          
          HitResult result = level.hitscan(shootPos, dir, false);
          if (result!=null) {
//            level.entities.add(new Puff("PUFF", "ABCD", level, result.pos, 0.0));
            if (result.entity!=null) {
              if (result.entity is Monster) {
                (result.entity as Monster).motion+=dir*100.0;
              }
              level.entities.add(new Explosion("BFE2", "ABCD", level, result.entity.pos+new Vector3(0.0, result.entity.height/2.0, 0.0), 0.0));
            }
          }
        }
        remove();
      }
    } else {
      super.tick(passedTime);
    }
  }
  
  void hit() {
    Explosion e = new Explosion("BFE1", "ABCDEF", level, pos, rot)..fullBright = true;
    level.entities.add(e);

    spriteTemplate = null;
    playSound(pos, "RXPLOD", uniqueId: e);
    blowUpIn = 12/35.0;
  }
}

class Mob extends Entity {
  Vector3 motion = new Vector3(0.0, 0.0, 0.0);
  double rotMotion = 0.9;
  double stepUp = 0.0;
  double walkTime = 0.0;
  
  
  Mob(Level level, Vector3 pos) : super(level, pos, EntityBlockerType.BLOCKING) {
    bleeds = true;
  }
  
  HashSet<Sector> sectorsInRange = new HashSet<Sector>();
//  List<SubSector> subSectorsInRange = new List<SubSector>();
  void move(double iX, double iY, double passedTime) {
    collided = false;
    animFrame=((walkTime*35/6)).floor()%4;
    Vector3 oldPos = new Vector3.copy(pos);
    
    rot+=rotMotion*passedTime;
    rotMotion *= pow(0.0000001, passedTime);
    
    stepUp *= pow(0.0000001, passedTime);
    double frictionXZ = pow(0.0005, passedTime);
    double frictionY = pow(0.2, passedTime);
    motion.x*=frictionXZ;
    motion.y*=frictionY;
    motion.z*=frictionXZ;
    motion.x+=(sin(rot)*iY-cos(rot)*iX)*passedTime*4000.0;
    motion.z+=(cos(rot)*iY+sin(rot)*iX)*passedTime*4000.0;
    sectorsInRange.clear();

    if (motion.xz.length2<100.0) {
      motion.x = 0.0;
      motion.z = 0.0;
    } else {
      walkTime+=passedTime;
      super.clipMove(motion, passedTime, sectorsInRange);
    }
    
    pos.y+=motion.y*(passedTime);


    double floorHeight = -10000000.0;
//    sectorsInRange.add(level.bsp.findSector(pos.x, pos.z));
    inSectors.forEach((sector) {
      if (sector.floorHeight>floorHeight) floorHeight=sector.floorHeight;
    });
    motion = (pos-oldPos)/passedTime;
    if (pos.y<=floorHeight) {
      if (oldPos.y<=floorHeight) {
        stepUp+=floorHeight-oldPos.y;
      }
      pos.y = floorHeight;
      motion.y = 0.0;
    } else {
      motion.y-=2000*passedTime;
    }
    
    if (stepUp>32.0) stepUp = 32.0;
  }
  
}

class Player extends Mob {
  Fists fists = new Fists();
  Chainsaw chainsaw = new Chainsaw();
  Pistol pistol = new Pistol();
  Shotgun shotgun = new Shotgun();
  SuperShotgun superShotgun = new SuperShotgun();
  Chaingun chaingun = new Chaingun();
  RocketLauncher rocketLauncher = new RocketLauncher();
  Plasmagun plasmaGun = new Plasmagun();
  BFG bfg = new BFG();
  
  Weapon weapon;
  Weapon nextWeapon;
  double bobSpeed = 0.0, bobPhase = 0.0;

  Player(Level level, Vector3 pos, double rot) : super(level, pos) {
    this.rot = rot;
    radius = 16.0;
    nextWeapon = weapon = pistol;
  }
  
  void requestWeaponSlot(int slot) {
    Weapon switchTo = null;
    if (slot==0) switchTo = nextWeapon == fists?chainsaw:fists;
    if (slot==1) switchTo = pistol;
    if (slot==2) switchTo = nextWeapon == shotgun?superShotgun:shotgun;
    if (slot==3) switchTo = chaingun;
    if (slot==4) switchTo = rocketLauncher;
    if (slot==5) switchTo = plasmaGun;
    if (slot==6) switchTo = bfg;
    nextWeapon = switchTo;
  }
  
  void use() {
    double x0 = pos.x;
    double y0 = pos.y;
    List<HitResult> hits = level.bsp.getIntersectingSegs(pos, new Vector3(sin(rot), 0.0, cos(rot)));
    double maxDist = 64.0;
    for (int i=0; i<hits.length; i++) {
      HitResult hr = hits[i];
      double xd = hr.pos.x-pos.x;
      double zd = hr.pos.z-pos.z;
      if (xd*xd+zd*zd>maxDist*maxDist) break;
      Wall wall = hits[i].segment.wall;
      if (wall.data.type!=0) {
        // only trigger from the front, and only if the trigger isn't in use
        if (wall.rightSidedef == hits[i].segment.sidedef && wall.triggerUsable) {
          LinedefTrigger trigger = linedefTriggers.triggers[wall.data.type];
          if (trigger==null) {
            print("NO LINDEFTRIGGER FOR ${wall.data.type}");
          } else {
            if (trigger.activator == LinedefTriggers.TOUCH) {
              trigger.trigger(hits[i].segment.wall, hits[i].segment.sidedef==hits[i].segment.wall.rightSidedef);
              return;
            }
          }
        }
      }
    }
  }
  
  void passWall(Wall wall) {
    if (wall.data.type!=0) {
      if (wall.triggerUsable) {
        LinedefTrigger trigger = linedefTriggers.triggers[wall.data.type];
        if (trigger==null) {
          print("NO LINDEFTRIGGER FOR ${wall.data.type}");
        } else {
          if (trigger.activator == LinedefTriggers.WALK) {
            trigger.trigger(wall, true);
            return;
          }
        }
      }
    }
  }
  
  
  void move(double iX, double iY, double passedTime) {
    super.move(iX,  iY,  passedTime);
    bobSpeed = motion.length/300.0;
    bobSpeed = bobSpeed*bobSpeed;
    if (bobSpeed>1.0) bobSpeed = 1.0;
    bobPhase+=passedTime*PI*2*1.5*bobSpeed;
  }
}

class Monster extends Mob {
  double turnIn = 0.0;
  double collideTime = 0.0;
  double rota = 0.0;
  double standStillTime = 0.0;
  
  Monster(String templateName, Level level, Vector3 pos, double rot, [bool transparent = false]) : super(level, pos) {
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    this.transparent = transparent;
    this.shouldAimAt = true;
    
    radius = 16.0;
  }
  
  void tick(double passedTime) {
    if (standStillTime>0.0) {
      standStillTime-=passedTime;
      move(0.0, 0.0*0.0, passedTime);
    } else {
      move(0.0, 1.0*0.2, passedTime);
    }
    rot+=passedTime*rota;
    
    if (collided && collideTime<=0.0) {
      collideTime = random.nextDouble()*0.1+0.1;
      rota += (random.nextDouble()*4.0+2.0)*(random.nextInt(2)*2-1);
    }

    if (turnIn>0.0) {
      turnIn-=passedTime;
    }
    
    if (collideTime>0.0) {
      collideTime-=passedTime;
    } else {
      rota*=pow(0.000001, passedTime);
      if (turnIn<=0.0) {
        if (random.nextInt(3)==0) {
          standStillTime = random.nextDouble()*1.0+0.5; 
          turnIn = random.nextDouble()*2.0+0.5;
        } else {
          turnIn = random.nextDouble()*2.0+0.5;
          rota += (random.nextDouble()*30.0)*(random.nextInt(2)*2-1);
        }
      }
    }
  }
}