part of Dark;

class GunAnimation {
  List<GunAnimationFrame> frames;
  double duration;
  
  GunAnimation(this.frames) {
    duration = 0.0;
    frames.forEach((f)=>duration+=f.frames);
  }
  
  void render(int x, int y, double animationTime) {
    for (int i=0; i<frames.length; i++) {
      if (frames[i].frames>animationTime) {
        frames[i].render(x, y);
        return;
      } else {
        animationTime-=frames[i].frames;
      }
    }
  }
}

class GunAnimationFrame {
  int frames;
  List<String> images;
  
  GunAnimationFrame(this.frames, this.images);
  
  void render(int x, int y) {
    images.forEach((image)=>renderers.addGuiSprite(x, y, image));
  }  
}

class Weapon {
  static double bobPower = 1.0;
  static double switchSpeed = 1.0/0.2;
  bool triggerDown = false;
  String defaultSprite;
  GunAnimation animation = null;
  double animationTime = 0.0;
  
  double switchOutTime = 0.0;
  
  Weapon(this.defaultSprite) {
  }
  
  void playAnimation(GunAnimation animation) {
    this.animation = animation;
    animationTime = 0.0;
  }
  
  void render() {
    if (bobPower>1.0) bobPower = 1.0;
    if (bobPower<0.4) bobPower = 0.4;
    int xBob = (sin(player.bobPhase/2.0)*player.bobSpeed*25.5*bobPower).round();
    int yBob = (cos(player.bobPhase/2.0)*player.bobSpeed*12.5*bobPower).abs().round()+32;
    renderAt(xBob, yBob+(switchOutTime*switchOutTime*switchOutTime*200.0).floor());
  }
  
  void renderAt(int x, int y) {
    if (animation==null) 
      renderers.addGuiSprite(x, y, defaultSprite);
    else
      animation.render(x, y, animationTime);
  }
  
  void tick(bool triggerHeld, double passedTime) {
    bool wasTriggerDown = triggerDown;
    triggerDown = triggerHeld;
    if (triggerHeld) {
      bobPower-=passedTime/0.2;
    } else {
      bobPower+=passedTime/0.5;
    }

    if (switchOutTime>0.0) {
      if (player.nextWeapon!=this) {
        switchOutTime+=passedTime*switchSpeed;
        if (switchOutTime>1.0) {
          switchOutTime = 1.0;
          player.weapon = player.nextWeapon;
          player.weapon.switchTo();
          player.weapon.switchOutTime = 1.0;
        }
      } else {
        switchOutTime-=passedTime*switchSpeed;
        if (switchOutTime<0.0) switchOutTime = 0.0;
      }
      return;
    }
    
    if (animation!=null) {
      animationTime+=passedTime*35.0; // Doom ran at 35 ticks per second
      if (animationTime>animation.duration) {
        animation = null;
        animationTime = 0.0;
      }
    } else {
      animationTime = 0.0;
    }
    if (player.nextWeapon!=this && animation==null) {
      switchOutTime += passedTime*switchSpeed;
    } else {
      update(!wasTriggerDown && triggerHeld, triggerHeld, passedTime);
    }
  }
  
  void update(bool pressed, bool held, double passedTime) {
  }
  
  Vector3 findAimDir(Vector3 pos, Vector3 dir) {
    HitResult scanResult = level.hitscan(pos, dir, true);
    if (scanResult!=null && scanResult.entity!=null) {
      print("Aiming at ${scanResult.entity}");
      double yAim = scanResult.entity.pos.y+scanResult.entity.height/2.0;
      dir*=(scanResult.entity.pos-pos).length;
      dir.y = yAim-pos.y;
      dir.normalize();
    }
    return dir;
  }
  
  void shootBullets(Vector3 pos, Vector3 dir, int amount, double spreadAmount) {
    for (int i=0; i<amount; i++) {
      Vector3 spread;
      do {
        spread = new Vector3(random.nextDouble()-0.5, random.nextDouble()-0.5, random.nextDouble()-0.5)*2.0;
      } while (spread.length2>1.0);
      spread.y*=0.2;
      HitResult result = level.hitscan(pos, (dir+spread*spreadAmount).normalize(), false);
      if (result!=null) {
        if (result.entity!=null) {
          if (result.entity is Monster) {
            (result.entity as Monster).motion+=dir*100.0;
          }
          if (result.entity.bleeds) 
            level.entities.add(new Blood("BLUD", "ABC", level, result.pos, 0.0));
          else 
            level.entities.add(new Puff("PUFF", "ABCD", level, result.pos, 0.0));
        } else {
          level.entities.add(new Puff("PUFF", "ABCD", level, result.pos, 0.0));
        }
      }
    }
  }
  
  void switchTo() {
  }
}

class Fists extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(2, ["PUNGB0"]),
      new GunAnimationFrame(2, ["PUNGC0"]),
      new GunAnimationFrame(2, ["PUNGD0"]),
      new GunAnimationFrame(3, ["PUNGC0"]),
      new GunAnimationFrame(4, ["PUNGB0"]),
  ]);
  
  Fists() : super("PUNGA0");
  
  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      playSound(null, "PUNCH", uniqueId: "weapon");
      playAnimation(reloadAnimation);
    }
  }
}

class Chainsaw extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(2, ["SAWGA0"]),
      new GunAnimationFrame(2, ["SAWGB0"]),
  ]);
  
  double idleTime = 0.0;
  int idleFrame = 0;
  
  Chainsaw() : super("SAWGC0");
  
  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      playSound(null, "SAWFUL", uniqueId: "weapon");
      playAnimation(reloadAnimation);
      idleTime = 0.0;
    } else {
      idleTime+=passedTime;
      if (idleTime>4.0/35.0) {
        idleTime-=4.0/35.0;
        
        idleFrame = (idleFrame+1)%2;
        defaultSprite = idleFrame==0?"SAWGC0":"SAWGD0";
        
        if (idleFrame==0) {
          playSound(null, "SAWIDL", uniqueId: "weapon");
        }
      }
    }
  }
  
  void switchTo() {
    playSound(null, "SAWUP", uniqueId: "weapon");
  }
}

class Pistol extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(4, ["PISGB0", "PISFA0"]),
      new GunAnimationFrame(4, ["PISGC0"]),
      new GunAnimationFrame(4, ["PISGB0"]),
      new GunAnimationFrame(3, ["PISGA0"]),
  ]);

  Pistol() : super("PISGA0");

  void update(bool pressed, bool held, double passedTime) {
    if (pressed) print("pressed");
    if ((held && animation==null) || (pressed && animationTime>animation.duration*0.50)) {
      Vector3 shootPos = player.pos+new Vector3(0.0, 36.0, 0.0);
      Vector3 dir = new Vector3(sin(player.rot), 0.0, cos(player.rot));
      dir = findAimDir(shootPos, dir);
      shootBullets(shootPos, dir, 1, 0.01);
      
      playSound(null, "PISTOL", uniqueId: "weapon");
      playAnimation(reloadAnimation);
    }
  }
}

class Shotgun extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(3, ["SHTGA0", "SHTFA0"]),
      new GunAnimationFrame(3, ["SHTGA0", "SHTFB0"]),
      new GunAnimationFrame(3, ["SHTGB0"]),
      new GunAnimationFrame(8, ["SHTGC0"]),
      new GunAnimationFrame(8, ["SHTGD0"]),
      new GunAnimationFrame(4, ["SHTGC0"]),
      new GunAnimationFrame(4, ["SHTGB0"]),
      new GunAnimationFrame(4, ["SHTGA0"]),
  ]);
  
  Shotgun() : super("SHTGA0");

  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      Vector3 shootPos = player.pos+new Vector3(0.0, 36.0, 0.0);
      Vector3 dir = new Vector3(sin(player.rot), 0.0, cos(player.rot));
      dir = findAimDir(shootPos, dir);
      shootBullets(shootPos, dir, 14, 0.1);
      
      playSound(null, "SHOTGN", uniqueId: "weapon");
      playAnimation(reloadAnimation);
    }
  }
}

class SuperShotgun extends Weapon {
  SuperShotgun() : super("SHTGA0");
}

class Chaingun extends Weapon {
  static GunAnimation fireAnimation1 = new GunAnimation([
      new GunAnimationFrame(3, ["CHGGA0", "CHGFA0"]),
  ]);
  static GunAnimation fireAnimation2 = new GunAnimation([
      new GunAnimationFrame(3, ["CHGGB0", "CHGFB0"]),
  ]);
  
  Chaingun() : super("CHGGA0");
  
  int step = 0;
  int shootTime = 1;
  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      shootTime++;
      Vector3 shootPos = player.pos+new Vector3(0.0, 36.0, 0.0);
      Vector3 dir = new Vector3(sin(player.rot), 0.0, cos(player.rot));
      dir = findAimDir(shootPos, dir);
      shootBullets(shootPos, dir, 1, 0.15-40.0/(shootTime+40.0)*0.10);
      
      playSound(null, "PISTOL", uniqueId: "weapon", volume: (40.0/(shootTime+40.0)*0.5+0.5));
      if (step==0) playAnimation(fireAnimation1);
      if (step==1) playAnimation(fireAnimation2);
      step = (step+1)%2;
    } 
    
    if (animation == null) {
      shootTime = 0;
    }
  }  
}

class RocketLauncher extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(4, ["MISGA0", "MISFA0"]),
      new GunAnimationFrame(4, ["MISGB0", "MISFB0"]),
      new GunAnimationFrame(4, ["MISGB0", "MISFC0"]),
      new GunAnimationFrame(4, ["MISGB0", "MISFD0"]),
      new GunAnimationFrame(4, ["MISGA0"]),
  ]);
  
  RocketLauncher() : super("MISGA0");
  
  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      Vector3 shootPos = player.pos+new Vector3(0.0, 32.0, 0.0);
      Vector3 dir = new Vector3(sin(player.rot), 0.0, cos(player.rot));
      dir = findAimDir(shootPos, dir);

      Projectile p = new Projectile("MISL", level, shootPos, dir*1000.0, player);
      level.entities.add(p);
      playSound(p.pos, "RLAUNC");

      playAnimation(reloadAnimation);
    }
  }  
}

class Plasmagun extends Weapon {
  static GunAnimation fireAnimation = new GunAnimation([
      new GunAnimationFrame(1, ["PLSFA0"]),
      new GunAnimationFrame(1, ["PLSFB0"]),
  ]);

  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(16, ["PLSGB0"]),
  ]);
  
  Plasmagun() : super("PLSGA0");
  
  bool wasShooting = false;
  
  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      Vector3 shootPos = player.pos+new Vector3(0.0, 32.0, 0.0);
      Vector3 dir = new Vector3(sin(player.rot), 0.0, cos(player.rot));
      dir = findAimDir(shootPos, dir);

      Projectile p = new Projectile("PLSS", level, shootPos, dir*1000.0, player);
      level.entities.add(p);
      playSound(p.pos, "PLASMA");
      
      playAnimation(fireAnimation);
      wasShooting = true;
    }
    if (!held && wasShooting) {
      playAnimation(reloadAnimation);
      wasShooting = false;
    }
  }
}

class BFG extends Weapon {
  BFG() : super("SHTGA0");
}