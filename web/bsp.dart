part of Dark;
int _subSectorCount = 0;

class BSP {
  Level level;
  BSPNode root;
  Culler culler = new Culler();
  
  BSP(this.level) {
    root = new BSPNode(level, level.levelData.nodes.last);
  }
  
  Sector findSector(Vector2 pos) {
    return root.findSubSector(pos).sector;
  }
  
  List<Segment> findSortedSegs(Matrix4 modelViewMatrix, Matrix4 perspectiveMatrix) {
    culler.init(modelViewMatrix, perspectiveMatrix);
    Vector2 pos = (modelViewMatrix.transform3(new Vector3(0.0, 0.0, 0.0))).xz;
    List<Segment> result = new List<Segment>();
    _subSectorCount = 0;
    root.findSortedSegs(culler, pos, result);
    return result;
  }
  
  HashSet<Sector> findSectorsInRadius(double x, double y, double radius) {
    HashSet<Sector> result = new HashSet<Sector>();
    root.findSectorsInRadius(x, y, radius, result);
    return result;
  }

  void findSubSectorsInRadius(double x, double y, double radius, List<SubSector> result) {
    root.findSubSectorsInRadius(x, y, radius, result);
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
    double width = inversePerspective.transform3(new Vector3(1.0, 1.0, 0.0)).x;
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
  void checkOccluders(SubSector subSector, List<Segment> result, int id) {
    if (clip0>=clip1) return;
    for (int i=0; i<subSector.segs.length; i++) {
      Segment seg = subSector.segs[i];
      
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
        if (!seg.wall.data.twoSided) {
          shouldClip = true;
        } else if (seg.backSector!=null) {
          if (seg.backSector.floorHeight>=seg.backSector.ceilingHeight) shouldClip = true;
          else if (seg.sector.floorHeight>=seg.backSector.ceilingHeight) shouldClip = true;
          else if (seg.sector.ceilingHeight<=seg.backSector.floorHeight) shouldClip = true;
        }
        if (shouldClip) clipRegion(xp0, xp1);
        seg.id = id;
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
  
  double dx, dy;
  double d;

  Bounds leftBounds;
  Bounds rightBounds;
  
  BSPNode leftChild, rightChild;
  SubSector leftSubSector, rightSubSector;
  
  BSPNode(Level level, WAD.Node node) {
    pos = new Vector2(node.x.toDouble(), node.y.toDouble());
    dir = new Vector2(-node.dy.toDouble(), node.dx.toDouble()).normalize();
    d = pos.dot(dir);
    dx = dir.x;
    dy = dir.y;
    
    rightBounds = new Bounds(node.bb0x0+0.0, node.bb0y0+0.0, node.bb0x1+0.0, node.bb0y1+0.0);
    leftBounds = new Bounds(node.bb1x0+0.0, node.bb1y0+0.0, node.bb1x1+0.0, node.bb1y1+0.0);
    
    if (node.leftChild&0x8000==0) {
      leftChild = new BSPNode(level, level.levelData.nodes[node.leftChild]);
    } else {
      leftSubSector = level.subSectors[node.leftChild&0x7fff];
    }
    if (node.rightChild&0x8000==0) {
      rightChild = new BSPNode(level, level.levelData.nodes[node.rightChild]);
    } else {
      rightSubSector = level.subSectors[node.rightChild&0x7fff];
    }
  }
  
  void findSortedSegs(Culler culler, Vector2 p, List<Segment> result) {
    if (p.dot(dir)>d) {
      if (culler.isVisible(leftBounds)) {
        if (leftChild!=null) leftChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(leftSubSector, result, _subSectorCount++);
      }
      
      if (culler.isVisible(rightBounds)) {
        if (rightChild!=null) rightChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(rightSubSector, result, _subSectorCount++);
      }
    } else {
      if (culler.isVisible(rightBounds)) {
        if (rightChild!=null) rightChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(rightSubSector, result, _subSectorCount++);
      }
      
      if (culler.isVisible(leftBounds)) {
        if (leftChild!=null) leftChild.findSortedSegs(culler, p, result);
        else culler.checkOccluders(leftSubSector, result, _subSectorCount++);
      }
    }
  }
  
  void findSubSectorsInRadius(double x, double y, double radius, List<SubSector> result) {
    double dd = x*dx+y*dy;
    if (dd>d-radius) {
      if (leftChild!=null) leftChild.findSubSectorsInRadius(x, y, radius, result);
      else result.add(leftSubSector);
    } 
    if (dd<d+radius) {
      if (rightChild!=null) rightChild.findSubSectorsInRadius(x, y, radius, result);
      else result.add(rightSubSector);
    }
  }
  
  void findSectorsInRadius(double x, double y, double radius, HashSet<Sector> result) {
    double dd = x*dx+y*dy;
    if (dd>d-radius) {
      if (leftChild!=null) leftChild.findSectorsInRadius(x, y, radius, result);
      else result.add(leftSubSector.sector);
    } 
    if (dd<d+radius) {
      if (rightChild!=null) rightChild.findSectorsInRadius(x, y, radius, result);
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