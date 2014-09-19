part of Dark;

LinedefTriggers linedefTriggers = new LinedefTriggers();

class LinedefTriggers {
  static const int KEY_NONE = 0;
  static const int KEY_BLUE = 1;
  static const int KEY_RED = 2;
  static const int KEY_YELLOW = 3;
  
  static const int DOOR_OPEN_CLOSE = 0;
  static const int DOOR_OPEN = 1;
  static const int DOOR_CLOSE = 2;
  static const int DOOR_CLOSE_OPEN = 3;
  
  static const int SPEED_SLOW = 0;
  static const int SPEED_MED = 1;
  static const int SPEED_FAST = 2;
  static const int SPEED_TURBO = 3;
  
  static const int TOUCH = 0;
  static const int BULLET = 1;
  static const int WALK = 2;
  
  HashMap<int, LinedefTrigger> triggers = new HashMap<int, LinedefTrigger>();
  
  LinedefTriggers() {
    // Local doors
    triggers[1] = new LocalDoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..activatedBy(TOUCH)..setMonsterActivatable();
    triggers[26] = new LocalDoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..requireKey(KEY_BLUE)..activatedBy(TOUCH);
    triggers[28] = new LocalDoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..requireKey(KEY_RED)..activatedBy(TOUCH);
    triggers[27] = new LocalDoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..requireKey(KEY_YELLOW)..activatedBy(TOUCH);
    
    triggers[31] = new LocalDoorTrigger(DOOR_OPEN, SPEED_MED)..activatedBy(TOUCH)..setOnce();
    triggers[32] = new LocalDoorTrigger(DOOR_OPEN, SPEED_MED)..requireKey(KEY_BLUE)..activatedBy(TOUCH)..setOnce();
    triggers[33] = new LocalDoorTrigger(DOOR_OPEN, SPEED_MED)..requireKey(KEY_RED)..activatedBy(TOUCH)..setOnce();
    triggers[34] = new LocalDoorTrigger(DOOR_OPEN, SPEED_MED)..requireKey(KEY_YELLOW)..activatedBy(TOUCH)..setOnce();
    
    triggers[46] = new LocalDoorTrigger(DOOR_OPEN, SPEED_MED)..activatedBy(BULLET);

    triggers[117] = new LocalDoorTrigger(DOOR_OPEN_CLOSE, SPEED_TURBO)..activatedBy(TOUCH);
    triggers[118] = new LocalDoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..setOnce();

    // Remote doors
    triggers[4] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..activatedBy(WALK)..setOnce();
    triggers[29] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..activatedBy(TOUCH)..setOnce();
    triggers[90] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..activatedBy(WALK);
    triggers[63] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_MED)..activatedBy(TOUCH);
    
    triggers[2] = new DoorTrigger(DOOR_OPEN, SPEED_MED)..activatedBy(WALK)..setOnce();
    triggers[103] = new DoorTrigger(DOOR_OPEN, SPEED_MED)..activatedBy(TOUCH)..setOnce();
    triggers[86] = new DoorTrigger(DOOR_OPEN, SPEED_MED)..activatedBy(WALK);
    triggers[61] = new DoorTrigger(DOOR_OPEN, SPEED_MED)..activatedBy(TOUCH);
    
    triggers[3] = new DoorTrigger(DOOR_CLOSE, SPEED_MED)..activatedBy(WALK)..setOnce();
    triggers[50] = new DoorTrigger(DOOR_CLOSE, SPEED_MED)..activatedBy(TOUCH)..setOnce();
    triggers[75] = new DoorTrigger(DOOR_CLOSE, SPEED_MED)..activatedBy(WALK);
    triggers[42] = new DoorTrigger(DOOR_CLOSE, SPEED_MED)..activatedBy(TOUCH);

    triggers[16] = new DoorTrigger(DOOR_CLOSE_OPEN, SPEED_MED)..activatedBy(WALK)..setOnce();
    triggers[76] = new DoorTrigger(DOOR_CLOSE_OPEN, SPEED_MED)..activatedBy(WALK);
    
    triggers[108] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_TURBO)..activatedBy(WALK)..setOnce();
    triggers[111] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_TURBO)..activatedBy(TOUCH)..setOnce();
    triggers[105] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_TURBO)..activatedBy(WALK);
    triggers[114] = new DoorTrigger(DOOR_OPEN_CLOSE, SPEED_TURBO)..activatedBy(TOUCH);
    
    triggers[109] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(WALK)..setOnce();
    triggers[112] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..setOnce();
    triggers[106] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(WALK);
    triggers[115] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH);
    
    triggers[110] = new DoorTrigger(DOOR_CLOSE, SPEED_TURBO)..activatedBy(WALK)..setOnce();
    triggers[113] = new DoorTrigger(DOOR_CLOSE, SPEED_TURBO)..activatedBy(TOUCH)..setOnce();
    triggers[107] = new DoorTrigger(DOOR_CLOSE, SPEED_TURBO)..activatedBy(WALK);
    triggers[116] = new DoorTrigger(DOOR_CLOSE, SPEED_TURBO)..activatedBy(TOUCH);
    
    triggers[133] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..setOnce()..requireKey(KEY_BLUE);
    triggers[99] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..requireKey(KEY_BLUE); 
    triggers[135] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..setOnce()..requireKey(KEY_RED);
    triggers[134] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..requireKey(KEY_RED);
    triggers[137] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..setOnce()..requireKey(KEY_YELLOW);
    triggers[136] = new DoorTrigger(DOOR_OPEN, SPEED_TURBO)..activatedBy(TOUCH)..requireKey(KEY_YELLOW);
    

    // Ceilings
    triggers[40] = new CeilingRaiseTrigger()..activatedBy(WALK)..setOnce();
    triggers[41] = new CeilingLowerTrigger(0.0)..activatedBy(TOUCH)..setOnce();
    triggers[43] = new CeilingLowerTrigger(0.0)..activatedBy(TOUCH);
    triggers[44] = new CeilingLowerTrigger(8.0)..activatedBy(WALK)..setOnce();
    triggers[49] = new CeilingLowerTrigger(8.0)..activatedBy(TOUCH)..setOnce();
    triggers[72] = new CeilingLowerTrigger(8.0)..activatedBy(WALK);
    
    
    // Lifts
    triggers[10] = new LiftTrigger(SPEED_FAST)..activatedBy(WALK)..setOnce();
    triggers[21] = new LiftTrigger(SPEED_FAST)..activatedBy(TOUCH)..setOnce();
    triggers[88] = new LiftTrigger(SPEED_FAST)..activatedBy(WALK)..setMonsterActivatable();
    triggers[62] = new LiftTrigger(SPEED_FAST)..activatedBy(TOUCH);
    triggers[121] = new LiftTrigger(SPEED_TURBO)..activatedBy(WALK)..setOnce();
    triggers[122] = new LiftTrigger(SPEED_TURBO)..activatedBy(TOUCH)..setOnce();
    triggers[120] = new LiftTrigger(SPEED_TURBO)..activatedBy(WALK);
    triggers[123] = new LiftTrigger(SPEED_TURBO)..activatedBy(TOUCH);
    
    
    // Floors
    triggers[119] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(WALK)..setOnce();
    triggers[128] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(WALK);
    triggers[18] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(TOUCH)..setOnce();
    triggers[69] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(TOUCH);
    
    triggers[22] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(WALK)..setOnce()..setTransferProperties()..setSectorUntriggerable();
    triggers[95] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(WALK)..setTransferProperties()..setSectorUntriggerable();
    triggers[20] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(TOUCH)..setOnce()..setTransferProperties()..setSectorUntriggerable();
    triggers[68] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(TOUCH)..setTransferProperties()..setSectorUntriggerable();
    triggers[47] = new FloorRaiseNextHigherTrigger(SPEED_SLOW)..activatedBy(BULLET)..setOnce()..setTransferProperties()..setSectorUntriggerable();
    
    triggers[5] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 0.0)..activatedBy(WALK)..setOnce();
    triggers[91] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 0.0)..activatedBy(WALK);
    triggers[101] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 0.0)..activatedBy(TOUCH)..setOnce();
    triggers[64] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 0.0)..activatedBy(TOUCH);
    triggers[24] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 0.0)..activatedBy(BULLET)..setOnce();
    
    triggers[130] = new FloorRaiseNextHigherTrigger(SPEED_TURBO)..activatedBy(WALK)..setOnce();
    triggers[131] = new FloorRaiseNextHigherTrigger(SPEED_TURBO)..activatedBy(TOUCH)..setOnce();
    triggers[129] = new FloorRaiseNextHigherTrigger(SPEED_TURBO)..activatedBy(WALK);
    triggers[132] = new FloorRaiseNextHigherTrigger(SPEED_TURBO)..activatedBy(TOUCH);

    triggers[56] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 8.0)..activatedBy(WALK)..setOnce()..setSectorUntriggerable()..setCrush();
    triggers[94] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 8.0)..activatedBy(WALK)..setSectorUntriggerable()..setCrush();
    triggers[55] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 8.0)..activatedBy(TOUCH)..setOnce()..setCrush();
    triggers[65] = new FloorRaiseLowestCeilingTrigger(SPEED_SLOW, 8.0)..activatedBy(TOUCH)..setCrush();
  }
}

class LinedefTrigger {
  int activator;
  bool monsterActivatable = false;
  bool once = false;
  bool makesSectorUntriggerable = false;
  bool crush = false;
  
  void trigger(Wall wall, bool rightSide) {
    if (once) {
      wall.triggerUsable = false;
    }
    bool triggered = false;
    level.getSectorsWithTag(wall.data.tag).forEach((sector) {
      if (sector.onlyTriggerableBy!=null && sector.onlyTriggerableBy!=this) return;
      
      if (sector.effect==null) {
        if (makesSectorUntriggerable) {
          sector.onlyTriggerableBy = this;
        }
        triggerOnSector(sector, wall, rightSide);
        triggered = true;
      }
    });
    
    if (triggered) {
      wall.triggerSwitch(wall, rightSide, this);
    }
  }
  
  void setCrush() {
    crush = true;
  }
  
  void setSectorUntriggerable() {
    makesSectorUntriggerable = true;
  }
  
  void triggerOnSector(Sector sector, Wall wall, bool rightSide) {
  }
  
  void activatedBy(int activator) {
    this.activator = activator;
  }
  
  void setMonsterActivatable() {
    this.monsterActivatable = true;
  }
  
  void setOnce() {
    this.once = true;
  }
}

class DoorTrigger extends LinedefTrigger {
  int type;
  int keyNeeded = LinedefTriggers.KEY_NONE;
  int speed;
  
  DoorTrigger(this.type, this.speed) {
  }
  
  void requireKey(int keyNeeded) {
    this.keyNeeded = keyNeeded;
  }
  
  void triggerOnSector(Sector sector, Wall wall, bool rightSide) {
    if (type==LinedefTriggers.DOOR_OPEN) sector.setEffect(new DoorOpenEffect(this, speed));
    if (type==LinedefTriggers.DOOR_CLOSE) sector.setEffect(new DoorCloseEffect(this, speed));
    if (type==LinedefTriggers.DOOR_OPEN_CLOSE) sector.setEffect(new DoorOpenCloseEffect(this, speed));
    if (type==LinedefTriggers.DOOR_CLOSE_OPEN) sector.setEffect(new DoorCloseOpenEffect(this, speed));
  }
}

class LocalDoorTrigger extends DoorTrigger {
  LocalDoorTrigger(int type, int speed) : super(type, speed) {
  }
  
  void trigger(Wall wall, bool rightSide) {
    wall.triggerSwitch(wall, rightSide, this);
    triggerOnSector(wall.leftSector, wall, false);
  }
}

class CeilingRaiseTrigger extends LinedefTrigger {
  void triggerOnSector(Sector sector, Wall wall, bool rightSide) {
    sector.effect = new CeilingRaiseEffect();
  }
}

class CeilingLowerTrigger extends LinedefTrigger {
  double gap;
  
  CeilingLowerTrigger(this.gap);
  
  void triggerOnSector(Sector sector, Wall wall, bool rightSide) {
    sector.effect = new CeilingLowerEffect(gap);
  }
}

class LiftTrigger extends LinedefTrigger {
  int speed;
  
  LiftTrigger(this.speed);
  
  void triggerOnSector(Sector sector, Wall wall, bool rightSide) {
    sector.setEffect(new LiftEffect(speed));
  }
}

class FloorRaiseTrigger extends LinedefTrigger {
  int speed;
  bool transferProperties = false;
  
  FloorRaiseTrigger(this.speed);
  
  void setTransferProperties() {
    this.transferProperties = true;
  }
  
  void triggerOnSector(Sector sector, Wall wall, bool rightSide) {
    sector.effect = new FloorRaiseEffect(this);
  }
}

class FloorRaiseNextHigherTrigger extends FloorRaiseTrigger {
  FloorRaiseNextHigherTrigger(int speed) : super(speed);
}

class FloorRaiseLowestCeilingTrigger extends FloorRaiseTrigger {
  double margin = 0.0;
  
  FloorRaiseLowestCeilingTrigger(int speed, this.margin) : super(speed);
}





class SectorEffect {
  Sector sector;
  
  void tick(double passedTime) {
  }
  
  void replaceWithEffect(SectorEffect effect) {
    return; // Do not replace effects?
//    sector.effect = effect;
//    if (effect!=null) effect.start(sector);
  }
  
  void start(Sector sector) {
    this.sector = sector;
  }
}

class LiftEffect extends SectorEffect {
  int speed;
  int phase = 0;
  double waitTime = 0.0;
  double startHeight;
  
  LiftEffect(this.speed);
  
  void start(Sector sector) {
    super.start(sector);
    startHeight = sector.floorHeight;
    playSound(sector.centerPos, "PSTART", uniqueId: sector);
  }
  
  bool lower(double passedTime) {
    double lowestNeighborFloor = startHeight; 
    for (int i=0; i<sector.neighborSectors.length; i++) {
      if (sector.neighborSectors[i].floorHeight<lowestNeighborFloor)
        lowestNeighborFloor = sector.neighborSectors[i].floorHeight; 
    }

    double orgHeight = sector.floorHeight;
    sector.floorHeight-=passedTime*35.0*4.0;
    
    double margin = 0.001;

    // Maybe move entities on this elevator down..
    sector.entities.forEach((entity){
      if (entity.pos.y<=orgHeight+margin) {
        double highest = sector.floorHeight;
        entity.inSectors.forEach((s) {
          if (s.floorHeight>highest) highest = s.floorHeight;
        });
        if (entity.pos.y>highest+margin) {
          entity.pos.y=highest;
        }
      }
    });
    
    if (sector.floorHeight<lowestNeighborFloor) {
      sector.floorHeight=lowestNeighborFloor;
      return true;
    }
    return false;
  }
  
  bool raise(double passedTime) {
    double orgHeight = sector.floorHeight;

    sector.floorHeight+=passedTime*35.0*4.0;
    
    double maxHeight = sector.floorHeight;
    
    double margin = 0.001;
    sector.entities.forEach((entity){
      double lowestCeiling = sector.ceilingHeight;
      entity.inSectors.forEach((s) {
        if (s.ceilingHeight<lowestCeiling) lowestCeiling = s.ceilingHeight;
      });
      double highestPossibleEntityPos = lowestCeiling - entity.height;
      if (maxHeight>highestPossibleEntityPos) maxHeight = highestPossibleEntityPos;
    });
    
    if (sector.floorHeight>startHeight) {
      sector.floorHeight=startHeight;
    }
    
    if (sector.floorHeight>maxHeight) {
      // TODO: Hit the entities here?
      phase = 0;
      playSound(sector.centerPos, "PSTART", uniqueId: sector);
      sector.floorHeight = maxHeight;
    }
    
    // Maybe move entities on this elevator down..
    sector.entities.forEach((entity){
      if (entity.pos.y<=orgHeight+margin) {
        double highest = sector.floorHeight;
        entity.inSectors.forEach((s) {
          if (s.floorHeight>highest) highest = s.floorHeight;
        });
        if (entity.pos.y<highest+margin) {
          entity.pos.y=highest;
        }
      }
    });
    
    if (sector.floorHeight>=startHeight) {
      return true;
    }
    return false;
  }
  

  void tick(double passedTime) {
    if (phase==0) {
      if (lower(passedTime)) {
        phase = 1;
        waitTime = 0.0;
        playSound(sector.centerPos, "PSTOP", uniqueId: sector);
      }
    } else if (phase==1) {
      waitTime+=passedTime;
      if (waitTime>3.0) {
        waitTime = 0.0;
        phase = 2;
        playSound(sector.centerPos, "PSTART", uniqueId: sector);
      }
    } else if (phase==2) {
      if (raise(passedTime)) {
        sector.endEffect();
        playSound(sector.centerPos, "PSTOP", uniqueId: sector);
      }
    }
  }
  
  void hitEntityOnClose(Entity e, double entityTopHeight) {
    sector.ceilingHeight = entityTopHeight;
    phase = 0;
  }
}


class CeilingRaiseEffect extends SectorEffect {
  CeilingRaiseEffect();
  
  void tick(double passedTime) {
    double highestNeighborCeiling = 10000000.0; 
    for (int i=0; i<sector.neighborSectors.length; i++) {
      if (sector.neighborSectors[i].ceilingHeight>highestNeighborCeiling)
        highestNeighborCeiling = sector.neighborSectors[i].ceilingHeight; 
    }

    sector.ceilingHeight+=passedTime*35.0*2.0;
    
    if (sector.ceilingHeight>highestNeighborCeiling-4.0) {
      sector.ceilingHeight=highestNeighborCeiling-4.0;
      sector.endEffect();
    }
  }
}

class CeilingLowerEffect extends SectorEffect {
  double gap;

  CeilingLowerEffect(this.gap);
  
  void tick(double passedTime) {
    sector.ceilingHeight-=passedTime*35.0*2.0;
    
    double lowest = sector.floorHeight+gap;
    sector.entities.forEach((e){
      if (e.pos.y+e.height+1.0>lowest) {
        lowest = e.pos.y+e.height+1.0;
      }
    });
    
    if (sector.ceilingHeight<sector.floorHeight+gap) {
      sector.ceilingHeight=sector.floorHeight+gap;
      sector.endEffect();
    } else if (sector.ceilingHeight<lowest) {
      sector.ceilingHeight = lowest;
    }
  }  
}

class DoorEffect extends SectorEffect {
  DoorTrigger trigger; 
  int speed;
  
  DoorEffect(this.trigger, this.speed);

  bool openDoor(double passedTime) {
    double lowestNeighborCeiling = 10000000.0; 
    for (int i=0; i<sector.neighborSectors.length; i++) {
      if (sector.neighborSectors[i].ceilingHeight<lowestNeighborCeiling)
        lowestNeighborCeiling = sector.neighborSectors[i].ceilingHeight; 
    }

    sector.ceilingHeight+=passedTime*35.0*2.0;
    
    if (sector.ceilingHeight>lowestNeighborCeiling-4.0) {
      sector.ceilingHeight=lowestNeighborCeiling-4.0;
      return true;
    }
    return false;
  }
  
  bool closeDoor(double passedTime) {
    sector.ceilingHeight-=passedTime*35.0*2.0;
    sector.entities.forEach((e){
      if (e.pos.y+e.height+1.0>=sector.ceilingHeight) {
        hitEntityOnClose(e, e.pos.y+e.height+1.0);
      }
    });
    if (sector.ceilingHeight<sector.floorHeight) {
      sector.ceilingHeight = sector.floorHeight;
      return true;
    }
    return false;
  }
  
  void hitEntityOnClose(Entity e, double entityTopHeight) {
    sector.ceilingHeight = entityTopHeight;
  }
}

class DoorOpenEffect extends DoorEffect {
  DoorOpenEffect(DoorTrigger trigger, int speed) : super(trigger, speed);

  void start(Sector sector) {
    super.start(sector);
    if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DOROPN", uniqueId: sector);
    if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "BDOPN", uniqueId: sector);
  }

  void tick(double passedTime) {
    if (openDoor(passedTime)) {
      sector.endEffect();
    }
  }
}

class DoorCloseEffect extends DoorEffect {
  DoorCloseEffect(DoorTrigger trigger, int speed) : super(trigger, speed);

  void start(Sector sector) {
    super.start(sector);
    if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DORCLS", uniqueId: sector);
    if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "DORCLS", uniqueId: sector);
  }
  
  void tick(double passedTime) {
    if (closeDoor(passedTime)) {
      sector.endEffect();
    }
  }
}

class DoorOpenCloseEffect extends DoorEffect {
  int phase = 0;
  double waitTime = 0.0;
  
  DoorOpenCloseEffect(DoorTrigger trigger, int speed) : super(trigger, speed);
  
  void start(Sector sector) {
    super.start(sector);
    if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DOROPN", uniqueId: sector);
    if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "BDOPN", uniqueId: sector);
  }

  void tick(double passedTime) {
    if (phase==0) {
      if (openDoor(passedTime)) {
        phase = 1;
        waitTime = 0.0;
      }
    } else if (phase==1) {
      waitTime+=passedTime;
      if (waitTime>4.0) {
        waitTime = 0.0;
        phase = 2;
        playSound(sector.centerPos, "DORCLS", uniqueId: sector);
      }
    } else if (phase==2) {
      if (closeDoor(passedTime)) {
        sector.endEffect();
      }
    }
  }
  
  void replaceWithEffect(SectorEffect effect) {
    if (effect is DoorOpenCloseEffect) {
      if (phase!=2) phase = 2;
      else phase = 0;
    } else {
      super.replaceWithEffect(effect);
    }
  }
  
  void hitEntityOnClose(Entity e, double entityTopHeight) {
    sector.ceilingHeight = entityTopHeight;
    phase = 0;
  }
}

class DoorCloseOpenEffect extends DoorEffect {
  int phase = 0;
  double waitTime = 0.0;
  
  DoorCloseOpenEffect(DoorTrigger trigger, int speed) : super(trigger, speed);
  
  void start(Sector sector) {
    super.start(sector);
    playSound(sector.centerPos, "DORCLS", uniqueId: sector);
  }

  void tick(double passedTime) {
    if (phase==0) {
      if (closeDoor(passedTime)) {
        phase = 1;
        waitTime = 0.0;
      }
    } else if (phase==1) {
      waitTime+=passedTime;
      if (waitTime>30.0) {
        waitTime = 0.0;
        phase = 2;
        if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DOROPN", uniqueId: sector);
        if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "BDOPN", uniqueId: sector);
      }
    } else if (phase==2) {
      if (openDoor(passedTime)) {
        sector.endEffect();
      }
    }
  }  
}