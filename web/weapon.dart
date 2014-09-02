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
  bool triggerDown = false;
  String defaultSprite;
  GunAnimation animation = null;
  double animationTime = 0.0;
  
  Weapon(this.defaultSprite) {
  }
  
  void playAnimation(GunAnimation animation) {
    this.animation = animation;
    animationTime = 0.0;
  }
  
  void render() {
    int xBob = (sin(player.bobPhase/2.0)*player.bobSpeed*20.5).round();
    int yBob = (cos(player.bobPhase/2.0)*player.bobSpeed*10.5).abs().round()+32;
    renderAt(xBob, yBob);
  }
  
  void renderAt(int x, int y) {
    if (animation==null) 
      renderers.addGuiSprite(x, y, defaultSprite);
    else
      animation.render(x, y, animationTime);
  }
  
  void tick(bool triggerHeld, double passedTime) {
    triggerDown = triggerHeld;
    if (animation!=null) {
      animationTime+=passedTime*35.0; // Doom ran at 35 ticks per second
      if (animationTime>animation.duration) {
        animation = null;
        animationTime = 0.0;
      }
    } else animationTime = 0.0;
    update(!triggerDown && triggerHeld, triggerHeld, passedTime);
  }
  
  void update(bool pressed, bool held, double passedTime) {
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
      playSound(null, "PUNCH");
      playAnimation(reloadAnimation);
    }
  }
}

class Chainsaw extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(1, ["SAWGA0"]),
      new GunAnimationFrame(1, ["SAWGB0"]),
  ]);
  
  Chainsaw() : super("SAWGC0");
  
  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      playSound(null, "SAWHIT");
      playAnimation(reloadAnimation);
    }
  }
}

class Pistol extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(6, ["PISGC0", "PISFA0"]),
      new GunAnimationFrame(4, ["PISGD0"]),
      new GunAnimationFrame(4, ["PISGC0"]),
  ]);

  Pistol() : super("PISGA0");

  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      playSound(null, "PISTOL");
      playAnimation(reloadAnimation);
    }
  }
}

class Shotgun extends Weapon {
  static GunAnimation reloadAnimation = new GunAnimation([
      new GunAnimationFrame(3, ["SHTGA0", "SHTFA0"]),
      new GunAnimationFrame(3, ["SHTGA0", "SHTFB0"]),
      new GunAnimationFrame(5, ["SHTGB0"]),
      new GunAnimationFrame(8, ["SHTGC0"]),
      new GunAnimationFrame(5, ["SHTGD0"]),
      new GunAnimationFrame(5, ["SHTGC0"]),
      new GunAnimationFrame(5, ["SHTGB0"]),
      new GunAnimationFrame(5, ["SHTGA0"]),
  ]);
  
  Shotgun() : super("SHTGA0");

  void update(bool pressed, bool held, double passedTime) {
    if (held && animation==null) {
      playSound(null, "SHOTGN");
      playAnimation(reloadAnimation);
    }
  }
}

class SuperShotgun extends Weapon {
  SuperShotgun() : super("SHTGA0");
}

class Chaingun extends Weapon {
  Chaingun() : super("SHTGA0");
}

class RocketLauncher extends Weapon {
  RocketLauncher() : super("SHTGA0");
}

class Plasmagun extends Weapon {
  Plasmagun() : super("SHTGA0");
}

class BFG extends Weapon {
  BFG() : super("SHTGA0");
}