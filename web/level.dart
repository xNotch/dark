part of Dark;

class Level {
  WAD.Level levelData;
  
  List<Sector> sectors;
  List<Segment> segments;
  List<SubSector> subSectors;
  List<Wall> walls;
  BSP bsp;
  
  Level(this.levelData) {
    sectors = new List<Sector>(levelData.sectors.length);
    subSectors = new List<SubSector>(levelData.sSectors.length);
    segments = new List<Segment>(levelData.segs.length);
    
    for (int i=0; i<sectors.length; i++) {
      sectors[i] = new Sector(this, levelData.sectors[i]);
    }
    for (int i=0; i<segments.length; i++) {
      segments[i] = new Segment(this, levelData.segs[i]);
    }
    for (int i=0; i<subSectors.length; i++) {
      subSectors[i] = new SubSector(this, levelData.sSectors[i]);
    }
    for (int i=0; i<walls.length; i++) {
      walls[i] = new Wall(this, levelData.linedefs[i]);
    }
    
    bsp = new BSP(this);
  }
}

class Segment {
  WAD.Seg data;
  
  double x0, y0;
  double x1, y1;
  Sector sector;
  Sector backSector;
  Wall wall;
  
  Segment(Level level, this.data) {
    this.x0 = data.startVertex.x+0.0;
    this.y0 = data.startVertex.y+0.0;
    this.x1 = data.endVertex.x+0.0;
    this.y1 = data.endVertex.y+0.0;
    
    sector = level.sectors[data.sidedef.sectorId];
    if (data.backSidedef != null) {
      backSector = level.sectors[data.backSidedef.sectorId];
    }
  }
}

class Wall {
  WAD.Linedef data;
  
  Wall(Level level, this.data) {
  }
}

class Sector {
  WAD.Sector data;
  
  double floorHeight, ceilingHeight;
  String floorTexture, ceilingTexture;
  double lightLevel;
  
  Sector(Level level, this.data) {
    floorHeight = data.floorHeight+0.0;
    ceilingHeight = data.ceilingHeight+0.0;
    floorTexture = data.floorTexture;
    ceilingTexture = data.ceilingTexture;
    lightLevel = data.lightLevel+0.0;
  }
}

class SubSector {
  Sector sector;
  int segCount;
  List<Segment> segs;
  List<Sector> backSectors;
  List<Wall> walls;

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
      wallSet.add(level.walls[seg.linedefId]);
      int backSidedef = seg.direction != 0 ? linedef.rightSidedefId : linedef.leftSidedefId;
      if (backSidedef != -1) {
        backSectors[i] = level.sectors[levelData.sidedefs[backSidedef].sectorId];
      }
      segs[i] = segment;
    }

    walls = new List<Wall>.from(wallSet);
  }
}
