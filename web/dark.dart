library Dark;

import "dart:html";

import "dart:math";
import "dart:collection";
import "dart:typed_data";
import "dart:web_gl" as GL;
import "package:vector_math/vector_math.dart";

part "shader.dart";
part "sprites.dart";
part "walls.dart";
part "texture.dart";
part "wad.dart";

/**
 *  GAME_ORIGINAL_RESOLUTION false is COMPLETELY broken right now because of the framebuffer being hardcoded at 512*512
 */
bool GAME_ORIGINAL_RESOLUTION = true; // Original doom was 320x200 pixels


bool GAME_ORIGINAL_SCREEN_ASPECT_RATIO = false; // Original doom was 4:3.
bool GAME_ORIGINAL_PIXEL_ASPECT_RATIO = true; // Original doom used slightly vertically stretched pixels (320x200 pixels in 4:3)

double GAME_MIN_ASPECT_RATIO = 4/3; // Letterbox if aspect ratio is lower than this
double GAME_MAX_ASPECT_RATIO = 2/1; // Pillarbox if aspect ratio is higher than this


const TEXTURE_ATLAS_SIZE = 1024;


int screenWidth, screenHeight;


var canvas;
GL.RenderingContext gl;

HashMap<GL.Texture, Sprites> spriteMaps = new HashMap<GL.Texture, Sprites>();
HashMap<GL.Texture, Walls> walls = new HashMap<GL.Texture, Walls>();
HashMap<GL.Texture, Walls> transparentMiddleWalls = new HashMap<GL.Texture, Walls>();
Floors floors;
ScreenRenderer screenRenderer;
SkyRenderer skyRenderer;
List<Sprite> sprites = new List<Sprite>();

void addSpriteMap(GL.Texture texture) {
  spriteMaps[texture] = new Sprites(spriteShader, texture);
}

void addSprite(Sprite sprite) {
  sprites.add(sprite);
}

void addWallMap(GL.Texture texture) {
  walls[texture] = new Walls(wallShader, texture);
  transparentMiddleWalls[texture] = new Walls(wallShader, texture);
}

void addMiddleTransparentWall(Wall wall) {
  transparentMiddleWalls[wall.texture].insertWall(wall);
}

void addWall(Wall wall) {
  walls[wall.texture].insertWall(wall);
}

List<bool> keys = new List<bool>(256);

WadFile wadFile = new WadFile();

// Init method. Set up WebGL, load textures, etc
void main() {
  canvas = querySelector("#game");
  canvas.setAttribute("width",  "${screenWidth}px");
  canvas.setAttribute("height",  "${screenHeight}px");
//  gl = canvas.getContext("webgl", {"stencil": true});
  gl = canvas.getContext("webgl");
  if (gl==null) gl = canvas.getContext("experimental-webgl");
  
  window.onResize.listen((event) => resize());
  
  if (gl==null) {
    noWebGL();
    return;
  } else {
    resize();
  }
  
  for (int i=0; i<256; i++) keys[i] = false;
  
  window.onKeyDown.listen((e) {
    print(e.keyCode);
    if (e.keyCode<256) keys[e.keyCode] = true;
  });

  window.onKeyUp.listen((e) {
    if (e.keyCode<256) keys[e.keyCode] = false;
  });
  
  window.onBlur.listen((e) {
    for (int i=0; i<256; i++) keys[i] = false;
  });
  spriteShader.create();
  wallShader.create();
  floorShader.create();
  screenBlitShader.create();
  skyShader.create();

  floors = new Floors(floorShader, null);
  
  wadFile.load("originaldoom/doom.wad", start, (){
    playerPos = new Vector3(860.0,-50.0,-1480.0);
    wadFile.load("freedoom/doom.wad", start, (){
      print("Failed to load!");
    });
  });
}

void resize() {
  int width = window.innerWidth;
  int height = window.innerHeight;
  double aspectRatio = width/height;
  double minAspect = GAME_MIN_ASPECT_RATIO;
  double maxAspect = GAME_MAX_ASPECT_RATIO;
  if (GAME_ORIGINAL_SCREEN_ASPECT_RATIO) minAspect = maxAspect = 4/3;

  if (!GAME_ORIGINAL_RESOLUTION) {
    screenWidth = width;
    screenHeight = height;
    if (aspectRatio<minAspect) {
      screenHeight ~/= minAspect/aspectRatio;
    }
    if (aspectRatio>maxAspect) {
      screenWidth~/= aspectRatio/maxAspect;
    }
    canvas.setAttribute("width",  "${screenWidth}px");
    canvas.setAttribute("height",  "${screenHeight}px");
    canvas.setAttribute("style",  "width: ${screenWidth}px; height:${screenHeight}px; left:${(width-screenWidth)~/2}px; top:${(height-screenHeight)~/3}px;");
  } else {
    screenWidth = 320;
    screenHeight = 200;
    if (aspectRatio<minAspect) aspectRatio=minAspect;
    if (aspectRatio>maxAspect) aspectRatio=maxAspect;
    screenWidth = ((GAME_ORIGINAL_PIXEL_ASPECT_RATIO?240:200)*aspectRatio).floor();
  
    double gameWidth = screenWidth.toDouble();
    double gameHeight = screenHeight.toDouble();
    if (GAME_ORIGINAL_PIXEL_ASPECT_RATIO) gameHeight*=240/200;
  
    canvas.setAttribute("width",  "${screenWidth}px");
    canvas.setAttribute("height",  "${screenHeight}px");
    double xScale = width/gameWidth;
    double yScale = height/gameHeight;
    if (xScale<yScale) {
      int newHeight = (gameHeight*xScale).floor(); 
      canvas.setAttribute("style",  "width: ${width}px; height:${newHeight}px; left:0px; top:${(height-newHeight)~/3}px;");
    } else {
      int newWidth= (gameWidth*yScale).floor(); 
      canvas.setAttribute("style",  "width: ${newWidth}px; height:${height}px; left:${(width-newWidth)~/2}px; top:0px;");
    }
  }
}

void noWebGL() {
  canvas.setAttribute("style", "display:none;");
  querySelector("#webglwarning").setAttribute("style",  "");
}

Random random = new Random();

Matrix4 modelMatrix;
Matrix4 viewMatrix;
Matrix4 projectionMatrix;

Vector3 playerPos = new Vector3(1075.8603515625,-50.0,-3237.50537109375);
//Vector3 playerPos = new Vector3(-2090.5009765625,169.0,1060.5748291015625);
double playerRot = 0.0;

Framebuffer indexColorBuffer;

GL.Texture skyTexture;

void start() {
  floors.texture = flatMap.values.first.imageAtlas.texture;

  modelMatrix = new Matrix4.identity();
  viewMatrix = new Matrix4.identity();
  window.requestAnimationFrame(render);
  
  // TODO: Resize this in HD mode
  indexColorBuffer = new Framebuffer(512, 512);
  // TODO: Pass a proper color lookup texture

  Uint8List lookupTextureData = new Uint8List(256*256*4);
  // Top row: 14 16*16 grids of color look-ups, based on PLAYPAL
  for (int i=0; i<14; i++) {
    Palette palette = wadFile.palette.palettes[i];
    int xo = i*16;
    for (int y=0; y<16; y++) {
      for (int x=0; x<16; x++) {
        lookupTextureData[((x+xo)+y*256)*4+0] = palette.r[x+y*16];
        lookupTextureData[((x+xo)+y*256)*4+1] = palette.g[x+y*16];
        lookupTextureData[((x+xo)+y*256)*4+2] = palette.b[x+y*16];
        lookupTextureData[((x+xo)+y*256)*4+3] = 255;
      }
    }
  }
  // Below that, lookuptables for COLORMAP.. in rows of 16?
  for (int i=0; i<33; i++) {
    List<int> colormap = wadFile.colormap.colormaps[i];
    int xo = (i%16)*16;
    int yo = (i~/16+1)*16;
    for (int y=0; y<16; y++) {
      for (int x=0; x<16; x++) {
        int color = colormap[x+y*16];
        lookupTextureData[((x+xo)+(y+yo)*256)*4+0] = (color%16)*16+8;
        lookupTextureData[((x+xo)+(y+yo)*256)*4+1] = (color~/16)*16+8;
      }
    }
  }
  
  GL.Texture colorLookupTexture = gl.createTexture();
  gl.bindTexture(GL.TEXTURE_2D, colorLookupTexture);
  gl.texImage2DTyped(GL.TEXTURE_2D,  0,  GL.RGBA,  256,  256,  0,  GL.RGBA,  GL.UNSIGNED_BYTE, lookupTextureData);
  gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MIN_FILTER, GL.NEAREST);
  gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MAG_FILTER, GL.NEAREST);
  
  screenRenderer = new ScreenRenderer(screenBlitShader,  indexColorBuffer.texture, colorLookupTexture);
  
  WAD_Image skyImage = new WAD_Image.empty("_sky_", 1024, 128);
  WAD_Image sky = patchMap["SKY1"];
  for (int i=0; i<1024; i+=sky.width) {
    skyImage.draw(sky, i, 0);
  }
  skyTexture = skyImage.createTexture(wadFile.palette.palettes[0]);

  skyRenderer = new SkyRenderer(skyShader, skyTexture);
}

class Framebuffer {
  int width, height;
  GL.Texture texture;
  GL.Framebuffer framebuffer;
  GL.Renderbuffer depthbuffer;
  
  Framebuffer(this.width, this.height) {
    framebuffer = gl.createFramebuffer();
    gl.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);
    
    texture = gl.createTexture();
    gl.bindTexture(GL.TEXTURE_2D, texture);
    gl.texImage2DTyped(GL.TEXTURE_2D,  0,  GL.RGBA,  512,  512,  0,  GL.RGBA,  GL.UNSIGNED_BYTE, null);
    gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    
    gl.framebufferTexture2D(GL.FRAMEBUFFER,  GL.COLOR_ATTACHMENT0,  GL.TEXTURE_2D,  texture, 0);
    
    depthbuffer = gl.createRenderbuffer();
    gl.bindRenderbuffer(GL.RENDERBUFFER, depthbuffer);
    gl.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, 512, 512);
    
    gl.framebufferRenderbuffer(GL.FRAMEBUFFER,  GL.DEPTH_ATTACHMENT,  GL.RENDERBUFFER,  depthbuffer);
  }
}

void updateGameLogic(double passedTime) {
  if (passedTime>0.1) passedTime = 0.1;
  if (passedTime<0.0) passedTime = 0.0;
  
  double iRot = 0.0;
  double iY = 0.0;
  double iX = 0.0;
  if (keys[81]) iRot+=1.0;
  if (keys[69]) iRot-=1.0;

  if (keys[65]) iX+=1.0;
  if (keys[68]) iX-=1.0;

  if (keys[87]) iY+=1.0;
  if (keys[83]) iY-=1.0;
  
  playerRot-=iRot*passedTime*3;
  
  playerPos.x-=(sin(playerRot)*iY-cos(playerRot)*iX)*passedTime*300.0;
  playerPos.z-=(cos(playerRot)*iY+sin(playerRot)*iX)*passedTime*300.0;
  List<SubSector> subSectorsInRange = wadFile.level.bsp.findSubSectorsInRadius(playerPos.xz, 16.0);
  subSectorsInRange.forEach((ss)=>ss.segs.forEach((seg)=>clipMotion(seg, playerPos, 16.0)));

  int floorHeight = -10000000;
  HashSet<Sector> sectorsInRange = wadFile.level.bsp.findSectorsInRadius(playerPos.xz, 16.0);
  sectorsInRange.forEach((sector) {
    if (sector.floorHeight>floorHeight) floorHeight=sector.floorHeight;
  });
  playerPos.y = floorHeight.toDouble()+41;
}

void clipMotion(Seg seg, Vector3 playerPos, double radius) {
  if (seg.linedef.impassable || seg.backSector==null) {
    double xp = playerPos.x;
    double yp = playerPos.z;

    double d = xp*seg.xn+yp*seg.yn - seg.d;
    if (d>0.0 && d<=16.0) {
      double sd = xp*seg.xt+yp*seg.yt - seg.sd;
      if (sd>=0.0 && sd<=seg.length) {
        // Hit the center of the seg
        double toPushOut = radius-d+0.001;
        xp+=seg.xn*toPushOut;
        yp+=seg.yn*toPushOut;
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
          xp+=xd/dist*toPushOut;
          yp+=yd/dist*toPushOut;
        }
      }
    }
    
    playerPos.x = xp;
    playerPos.z = yp;
  }
}

void renderGame() {
  gl.bindFramebuffer(GL.FRAMEBUFFER, indexColorBuffer.framebuffer);
  gl.viewport(0,  0,  screenWidth,  screenHeight);

  projectionMatrix = makePerspectiveMatrix(60*PI/180,  screenWidth/screenHeight,  8,  10000.0).scale(-1.0, 1.0, 1.0);
  if (GAME_ORIGINAL_PIXEL_ASPECT_RATIO && !GAME_ORIGINAL_RESOLUTION) {
    // If the original aspect ratio is set, this scaling is done elsewhere.
    projectionMatrix = projectionMatrix.scale(1.0, 240/200, 1.0);
  }
  viewMatrix = new Matrix4.identity().rotateY(playerRot).translate(-playerPos);

  List<Seg> visibleSegs = wadFile.level.bsp.findSortedSegs(new Matrix4.copy(viewMatrix)..invert(), projectionMatrix);
  visibleSegs.forEach((seg) => Wall.addWallsForSeg(seg));
  
  gl.enable(GL.CULL_FACE);
  gl.enable(GL.DEPTH_TEST);
  gl.depthFunc(GL.ALWAYS);
  floors.render(visibleSegs, playerPos);
  gl.depthFunc(GL.LEQUAL);
  
  walls.values.forEach((walls) {
    walls.render();
    walls.clear();
  });
  
  gl.depthFunc(GL.ALWAYS);
  gl.colorMask(false, false, false, false);
  floors.renderBackWallHack(visibleSegs, playerPos);
  gl.colorMask(true, true, true, true);
  gl.depthFunc(GL.LEQUAL);
  
  sprites.forEach((sprite) {
    sprite.addToDisplayList(playerRot);
  });
  
  spriteMaps.values.forEach((sprites) {
    sprites.render();
    sprites.clear();
  });
  
  transparentMiddleWalls.values.forEach((walls) {
    walls.render();
    walls.clear();
  });
}

void blitScreen() {
  gl.bindFramebuffer(GL.FRAMEBUFFER, null);
  gl.viewport(0,  0,  screenWidth,  screenHeight);
  gl.disable(GL.DEPTH_TEST);
  projectionMatrix = makeOrthographicMatrix(0.0, screenWidth, screenHeight, 0.0, -10.0, 10.0);
  skyRenderer.render();
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.SRC_ALPHA,  GL.ONE_MINUS_SRC_ALPHA);
  screenRenderer.render();
  gl.disable(GL.BLEND);
}

double lastTime = -1.0;
void render(double time) {
  if (lastTime==-1.0) lastTime = time;
  double passedTime = (time-lastTime)/1000.0; // in seconds
  lastTime = time;
  
  updateGameLogic(passedTime);
  renderGame();
  blitScreen();
  
  int error = gl.getError();
  if (error!=0) {
    print("Error: $error");
  } else {
    window.requestAnimationFrame(render);
  }
}