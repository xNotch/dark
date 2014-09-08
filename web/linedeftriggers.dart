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
  static const int SPEED_TURBO = 2;
  
  static const int TOUCH = 0;
  static const int BULLET = 1;
  static const int WALK = 2;
  
  HashMap<int, LinedefTrigger> triggers = new HashMap<int, LinedefTrigger>();
  
  LinedefTriggers() {
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
  }
}

class LinedefTrigger {
  int activator;
  bool monsterActivatable = false;
  bool once = false;
  
  void activatedBy(int activator) {
    this.activator = activator;
  }
  
  void setMonsterActivatable() {
    this.monsterActivatable = true;
  }
  
  void setOnce() {
    this.once = true;
  }
  
  void use(Segment segment) {
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
  
  void use(Segment segment) {
    level.getSectorsWithTag(segment.wall.data.tag).forEach((sector)=>trigger(sector));
  }
  
  void trigger(Sector sector) {
    if (type==LinedefTriggers.DOOR_OPEN) sector.setEffect(new DoorOpenEffect(speed));
    if (type==LinedefTriggers.DOOR_CLOSE) sector.setEffect(new DoorCloseEffect(speed));
    if (type==LinedefTriggers.DOOR_OPEN_CLOSE) sector.setEffect(new DoorOpenCloseEffect(speed));
    if (type==LinedefTriggers.DOOR_CLOSE_OPEN) sector.setEffect(new DoorCloseOpenEffect(speed));
  }
}

class LocalDoorTrigger extends DoorTrigger {
  LocalDoorTrigger(int type, int speed) : super(type, speed) {
  }
  
  void use(Segment segment) {
    trigger(segment.wall.leftSector);
  }
}

class SectorEffect {
  Sector sector;
  
  void tick(double passedTime) {
  }
  
  void replaceWithEffect(SectorEffect effect) {
    sector.effect = effect;
    if (effect!=null) effect.start(sector);
  }
  
  void start(Sector sector) {
    this.sector = sector;
  }
}

class DoorEffect extends SectorEffect {
  int speed;
  
  DoorEffect(this.speed);

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
    if (sector.ceilingHeight<sector.floorHeight) {
      sector.ceilingHeight = sector.floorHeight;
      return true;
    }
    return false;
  }
}

class DoorOpenEffect extends DoorEffect {
  DoorOpenEffect(int speed) : super(speed);

  void start(Sector sector) {
    super.start(sector);
    if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DOROPN");
    if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "BDOPN");
  }

  void tick(double passedTime) {
    if (openDoor(passedTime)) {
      sector.setEffect(null);
    }
  }
}

class DoorCloseEffect extends DoorEffect {
  DoorCloseEffect(int speed) : super(speed);

  void start(Sector sector) {
    super.start(sector);
    if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DORCLS");
    if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "DORCLS");
  }
  
  void tick(double passedTime) {
    if (closeDoor(passedTime)) {
      sector.setEffect(null);
    }
  }
}

class DoorOpenCloseEffect extends DoorEffect {
  int phase = 0;
  double waitTime = 0.0;
  
  DoorOpenCloseEffect(int speed) : super(speed);
  
  void start(Sector sector) {
    super.start(sector);
    if (speed==LinedefTriggers.SPEED_MED) playSound(sector.centerPos, "DOROPN");
    if (speed==LinedefTriggers.SPEED_TURBO) playSound(sector.centerPos, "BDOPN");
  }

  void tick(double passedTime) {
    print("phase: $phase");
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
        playSound(sector.centerPos, "DORCLS");
      }
    } else if (phase==2) {
      if (closeDoor(passedTime)) {
        sector.setEffect(null);
      }
    }
  }
  
  void replaceWithEffect(SectorEffect effect) {
    print("Replace with : $effect");
    if (effect is DoorOpenCloseEffect) {
      if (phase!=2) phase = 2;
      else phase = 0;
    } else {
      super.replaceWithEffect(effect);
    }
  }
}

class DoorCloseOpenEffect extends DoorEffect {
  int phase = 0;
  double waitTime = 0.0;
  
  DoorCloseOpenEffect(int speed) : super(speed);

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
      }
    } else if (phase==2) {
      if (openDoor(passedTime)) {
        sector.setEffect(null);
      }
    }
  }  
}