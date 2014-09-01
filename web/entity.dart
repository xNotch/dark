part of Dark;

class PlayerSpawn {
  Vector3 pos;
  double rot;
  
  PlayerSpawn(this.pos, this.rot);
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
  bool blocking = false;
  BlockCell blockCell;
  
  Entity(this.level, this.pos) {
    blockCell = level.blockmap.getBlockCell(pos.x, pos.z); 
    if (blockCell!=null) {
      blockCell.entities.add(this);
    }
  }
  
  void tick(double passedTime) {
  }
  
  void addToDisplayList(double playerRot) {
    if (spriteTemplate==null) return;
    Sector sector = level.bsp.findSector(pos.xz);
    
    double rotDiff = rot - playerRot+PI;
    int rotFrame = (rotDiff * 8 / (PI * 2) + 0.5).floor() & 7;
    SpriteTemplateFrame stf = spriteTemplate.frames[animFrame];
    if (stf.rots.length == 1) rotFrame = 0;
    SpriteTemplateRot str = stf.rots[rotFrame];

    if (transparent) {
      renderers.transparentSpriteMaps[str.image.imageAtlas.texture].insertSprite(sector, pos, str);
    } else {
      renderers.spriteMaps[str.image.imageAtlas.texture].insertSprite(sector, pos, str);
    }
  }  
}

class AnimatedStationary extends Entity {
  String frames;
  int animStep = 0;
  double animAccum = 0.0;
  
  AnimatedStationary(String templateName, String frames, Level level, Vector3 pos, double rot) : super(level, pos) {
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
  Pickup(String templateName, String frames, Level level, Vector3 pos, double rot) : super(templateName, frames, level, pos, rot) {
  }
}

class Decoration extends AnimatedStationary {
  Decoration(String templateName, String frames, Level level, Vector3 pos, double rot) : super(templateName, frames, level, pos, rot)  {
  }

  factory Decoration.blocking(String templateName, String frames, Level level, Vector3 pos, double rot) {
    Decoration result = new Decoration(templateName, frames, level, pos, rot);
    result.blocking = true;
    return result;
  }
}

class Mob extends Entity {
  static int checkCounterHack = 0;
  static List<BlockCell> tmpBlockCells = new List<BlockCell>();
  static Set<Wall> tmpLinedefs = new Set<Wall>();
  Vector3 motion = new Vector3(0.0, 0.0, 0.0);
  double rotMotion = 0.9;
  double stepUp = 0.0;
  
  bool collided = false;
  
  
  Mob(Level level, Vector3 pos) : super(level, pos) {
    blocking = true;
  }
  
  void move(double iX, double iY, double passedTime) {
    collided = false;
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
    
    int steps = (motion.length/(radius/3.0)).floor()+1;
    
    HashSet<Sector> sectorsInRange = new HashSet<Sector>();
    sectorsInRange.clear();
    List<SubSector> subSectorsInRange = new List<SubSector>();
    for (int i=0; i<steps; i++) {
      checkCounterHack++;
      pos.x+=motion.x*(passedTime/steps);
      pos.z+=motion.z*(passedTime/steps);

      level.blockmap.getBlockCellsRadius(pos.x, pos.z, radius+128.0, tmpBlockCells);
      for (int i=0; i<tmpBlockCells.length; i++) {
        BlockCell bc = tmpBlockCells[i];
        for (int j=0; j<bc.entities.length; j++) {
          Entity e = bc.entities[j];
          if (e!=this && e.blocking) clipMotionEntity(e);
        }
      }

      level.bsp.findSubSectorsInRadius(pos.xz, radius, subSectorsInRange);
      for (int i=0; i<subSectorsInRange.length; i++) {
        SubSector ss = subSectorsInRange[i];
        for (int j=0; j<ss.walls.length; j++) {
          Wall ld = ss.walls[j];
          if (ld.checkCounterHack != checkCounterHack) {
            ld.checkCounterHack = checkCounterHack;
            clipMotion(ld, sectorsInRange);
          }
        }
      }
    }
    
    pos.y+=motion.y*(passedTime);


    BlockCell newBlockCell = level.blockmap.getBlockCell(pos.x, pos.z); 
    if (blockCell!=newBlockCell) {
      if (blockCell!=null) blockCell.entities.remove(this);
      blockCell = newBlockCell;
      if (blockCell!=null) blockCell.entities.add(this);
    }

    double floorHeight = -10000000.0;
    sectorsInRange.add(level.bsp.findSector(pos.xz));
    sectorsInRange.forEach((sector) {
      if (sector.floorHeight>floorHeight) floorHeight=sector.floorHeight;
    });
    motion = (pos-oldPos)/passedTime;
    if (pos.y<=floorHeight.toDouble()) {
      if (oldPos.y<=floorHeight.toDouble()) {
        stepUp+=floorHeight-oldPos.y;
      }
      pos.y = floorHeight.toDouble();
      motion.y = 0.0;
    } else {
      motion.y-=2000*passedTime;
    }
    
    if (stepUp>32.0) stepUp = 32.0;
  }
  
  bool canEnterSector(Sector sector) {
    if (sector.floorHeight>pos.y+24) return false;
    if (sector.ceilingHeight-sector.floorHeight==0) return true;
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
  
  void clipMotion(Wall seg, HashSet<Sector> overlappedSectors) {
/*  double xp = pos.x;
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
      if (seg.impassable || seg.leftSector==null) {
        collideWall = true;
      } else if (!canEnterSector(seg.leftSector) || !canEnterSector(seg.rightSector)) {
        collideWall = true;
      }

      if (collideWall) {
        collided = true;
        pos.x += xNudge;
        pos.z += yNudge;
      } else if (overlappedSectors!=null) {
        overlappedSectors.add(seg.rightSector);
        if (seg.leftSector!=null) overlappedSectors.add(seg.leftSector);
      }
    }*/
  }
}

class Player extends Mob {
  double bobSpeed = 0.0, bobPhase = 0.0;
  Player(Level level, Vector3 pos, double rot) : super(level, pos) {
    this.rot = rot;
    radius = 16.0;
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
  
  Monster(String templateName, Level level, Vector3 pos, double rot, [bool transparent = false]) : super(level, pos) {
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    this.transparent = transparent;
    radius = 16.0;
  }
  
  void tick(double passedTime) {
    rot+=passedTime*rota;
    move(0.0, 1.0*0.2, passedTime);
    
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
        turnIn = random.nextDouble()*2.0+0.5;
        rota += (random.nextDouble()*30.0)*(random.nextInt(2)*2-1);
      }
    }
  }
}