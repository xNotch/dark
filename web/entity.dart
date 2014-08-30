part of Dark;

class PlayerSpawn {
  Vector3 pos;
  double rot;
  
  PlayerSpawn(this.pos, this.rot);
}

class Entity {
  Vector3 pos;
  double radius = 16.0;
  double rot = 0.0;
  SpriteTemplate spriteTemplate;
  bool transparent = false;
  int animFrame = 0;
  bool hanging = false;
  bool blocking = false;
  
  void tick(double passedTime) {
  }
  
  void addToDisplayList(double playerRot) {
    if (spriteTemplate==null) return;
    Sector sector = wadFile.level.bsp.findSector(pos.xz);
    
    double rotDiff = rot - playerRot+PI;
    int rotFrame = (rotDiff * 8 / (PI * 2) + 0.5).floor() & 7;
    SpriteTemplateFrame stf = spriteTemplate.frames[animFrame];
    if (stf.rots.length == 1) rotFrame = 0;
    SpriteTemplateRot str = stf.rots[rotFrame];

    if (transparent) {
      transparentSpriteMaps[str.image.imageAtlas.texture].insertSprite(sector, pos, str);
    } else {
      spriteMaps[str.image.imageAtlas.texture].insertSprite(sector, pos, str);
    }
  }  
}

class AnimatedStationary extends Entity {
  String frames;
  int animStep = 0;
  double animAccum = 0.0;
  
  AnimatedStationary(String templateName, String frames, Vector3 pos, double rot) {
    if (frames.length>1) print("Animated decoration: $templateName, $frames"); 
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
  Pickup(String templateName, String frames, Vector3 pos, double rot) : super(templateName, frames, pos, rot) {
  }
}

class Decoration extends AnimatedStationary {
  Decoration(String templateName, String frames, Vector3 pos, double rot) : super(templateName, frames, pos, rot)  {
  }

  factory Decoration.blocking(String templateName, String frames, Vector3 pos, double rot) {
    Decoration result = new Decoration(templateName, frames, pos, rot);
    result.blocking = true;
    return result;
  }
}

class Mob extends Entity {
  Vector3 motion = new Vector3(0.0, 0.0, 0.0);
  double rotMotion = 0.9;
  double stepUp = 0.0;
  
  void move(double iX, double iY, double passedTime) {
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
    pos+=motion*passedTime;

    HashSet<Sector> sectorsInRange = new HashSet<Sector>();
    List<SubSector> subSectorsInRange = wadFile.level.bsp.findSubSectorsInRadius(pos.xz, radius);
    subSectorsInRange.forEach((ss)=>ss.segs.forEach((seg)=>clipMotion(seg, sectorsInRange)));

    int floorHeight = -10000000;
    sectorsInRange.add(wadFile.level.bsp.findSector(pos.xz));
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
  
  void clipMotion(Seg seg, HashSet<Sector> overlappedSectors) {
    double xp = pos.x;
    double yp = pos.z;

    double xNudge = 0.0;
    double yNudge = 0.0;
    bool intersect = false;

    double d = xp*seg.xn+yp*seg.yn - seg.d;
    if (d>0.0 && d<=16.0) {
      double sd = xp*seg.xt+yp*seg.yt - seg.sd;
      if (sd>=0.0 && sd<=seg.length) {
        // Hit the center of the seg
        double toPushOut = radius-d+0.001;
        xNudge=seg.xn*toPushOut;
        yNudge=seg.yn*toPushOut;
        intersect = true;
      } else if (sd>0.0) {
        // Hit either corner of the seg
        double xd, yd;
  /*        if (sd<=seg.length/2.0) {
            xd = xp-seg.x0;
            yd = yp-seg.y0;
          } else {*/
          xd = xp-seg.x1;
          yd = yp-seg.y1;
//        }

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
      if (seg.linedef.impassable || seg.backSector==null) {
        collideWall = true;
      } else if (seg.backSector.floorHeight>pos.y+24 || seg.sector.floorHeight>pos.y+24) {
        collideWall = true;
      }

      if (collideWall) {
        pos.x += xNudge;
        pos.z += yNudge;
      } else {
        overlappedSectors.add(seg.sector);
        if (seg.backSector!=null) overlappedSectors.add(seg.backSector);
      }
    }
  }
}

class Player extends Mob {
  double bobSpeed = 0.0, bobPhase = 0.0;
  Player(PlayerSpawn playerSpawn) {
    this.pos = playerSpawn.pos;
    this.rot = playerSpawn.rot;
    radius = 16.0;
  }
  
  void move(double iX, double iY, double passedTime) {
    super.move(iX,  iY,  passedTime);
    bobSpeed = motion.length/300.0;
    bobSpeed = bobSpeed*bobSpeed;
    if (bobSpeed>1.0) bobSpeed = 1.0;
    bobPhase+=passedTime*PI*2*2*bobSpeed;
  }
}

class Monster extends Mob {
  Monster(String templateName, Vector3 pos, double rot, [bool transparent = false]) {
    spriteTemplate = spriteTemplates[templateName];
    this.pos = pos;
    this.rot = rot;
    this.transparent = transparent;
    radius = 16.0;
  }
  
  void tick(double passedTime) {
    rot+=passedTime;
    move(0.0, 1.0*0.2, passedTime);
  }
}