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
part "entity.dart";

bool GAME_ORIGINAL_RESOLUTION = true; // Original doom was 320x200 pixels
bool GAME_ORIGINAL_SCREEN_ASPECT_RATIO = false; // Original doom was 4:3.
bool GAME_ORIGINAL_PIXEL_ASPECT_RATIO = true; // Original doom used slightly vertically stretched pixels (320x200 pixels in 4:3)

String GAME_NAME = "DARK";
String GAME_VERSION = "0.1";

double GAME_MIN_ASPECT_RATIO = 4/3; // Letterbox if aspect ratio is lower than this
double GAME_MAX_ASPECT_RATIO = 2/1; // Pillarbox if aspect ratio is higher than this


const TEXTURE_ATLAS_SIZE = 1024;


int screenWidth, screenHeight;

int textureScrollOffset = 0;
int transparentNoiseTime = 0;
var canvas;
GL.RenderingContext gl;

var consoleText;
HashMap<GL.Texture, Sprites> guiSprites = new HashMap<GL.Texture, Sprites>();

HashMap<GL.Texture, Sprites> spriteMaps = new HashMap<GL.Texture, Sprites>();
HashMap<GL.Texture, Sprites> transparentSpriteMaps = new HashMap<GL.Texture, Sprites>();

HashMap<GL.Texture, Walls> walls = new HashMap<GL.Texture, Walls>();
HashMap<GL.Texture, Walls> transparentMiddleWalls = new HashMap<GL.Texture, Walls>();
Floors floors;
ScreenRenderer screenRenderer;
SkyRenderer skyRenderer;
List<Sprite> sprites = new List<Sprite>();
List<Entity> entities = new List<Entity>();

bool invulnerable = false;

void addSpriteMap(GL.Texture texture) {
  guiSprites[texture] = new Sprites(spriteShader, texture);
  spriteMaps[texture] = new Sprites(spriteShader, texture);
  transparentSpriteMaps[texture] = new Sprites(transparentSpriteShader, texture);
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

Shader spriteShader, transparentSpriteShader, wallShader, floorShader, screenBlitShader, skyShader;

// Init method. Set up WebGL, load textures, etc
void main() {
  consoleText = querySelector("#consoleText");

  printToConsole("$GAME_NAME $GAME_VERSION");
  printToConsole("");
  canvas = querySelector("#game");
  canvas.setAttribute("width",  "${screenWidth}px");
  canvas.setAttribute("height",  "${screenHeight}px");
//  gl = canvas.getContext("webgl", {"stencil": true});
  gl = canvas.getContext("webgl");
  if (gl==null) gl = canvas.getContext("experimental-webgl");


  if (gl==null) {
    crash("No webgl", "Go to <a href=http://get.webgl.org/'>get.webgl.org</a> for more information");
    return;
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

  spriteShader = new Shader("sprite");
  transparentSpriteShader = new Shader("transparentsprite");
  wallShader = new Shader("wall");
  floorShader = new Shader("floor");
  screenBlitShader = new Shader("screenblit");
  skyShader = new Shader("sky");
  printToConsole("Loading shaders");
  Shader.loadAndCompileAll(() {
    floors = new Floors(floorShader, null);

    printToConsole("Loading WAD file");
    wadFile.load("originaldoom/doom.wad", start, (){
      wadFile.load("freedoom/doom.wad", start, (){
        print("Failed to load wad file!");
      });
    });
  },() {
    print("Failed to load shaders!");
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

void crash(String title, String message) {
  canvas.setAttribute("style", "display:none;");
  querySelector("#consoleHolder").setAttribute("style",  "");
  printToConsole("---------------------------");
  printToConsole(title);
  printToConsole("");
  printToConsole(message);
}

void printToConsole(String message) {
  consoleText.appendHtml(message+"\r");
}

Random random = new Random();

Matrix4 modelMatrix;
Matrix4 viewMatrix;
Matrix4 projectionMatrix;

Player player;
//Vector3 playerPos = ;
//Vector3 playerPos = new Vector3(-2090.5009765625,169.0,1060.5748291015625);
//double playerRot = 0.0;

List<Framebuffer> indexColorBuffers = new List<Framebuffer>(3);
Framebuffer indexColorBuffer;

GL.Texture skyTexture;

void start() {
  player = new Player(wadFile.level.playerSpawns[0]);

  floors.texture = flatMap.values.first.imageAtlas.texture;

  modelMatrix = new Matrix4.identity();
  viewMatrix = new Matrix4.identity();
  window.requestAnimationFrame(render);

  int frameBufferRes = 512;
  if (!GAME_ORIGINAL_RESOLUTION) frameBufferRes = 2048;
  for (int i=0; i<3; i++) {
    indexColorBuffers[i] = new Framebuffer(frameBufferRes, frameBufferRes);
  }

  printToConsole("Creating color lookup texture");
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
  for (int i=0; i<32; i++) {
    List<int> colormap = wadFile.colormap.colormaps[i];
    List<int> icolormap = wadFile.colormap.colormaps[32];
    int xo = (i%16)*16;
    int yo = (i~/16+1)*16;
    for (int y=0; y<16; y++) {
      for (int x=0; x<16; x++) {
        int color = colormap[x+y*16];
        lookupTextureData[((x+xo)+(y+yo)*256)*4+0] = (color%16)*16+8;
        lookupTextureData[((x+xo)+(y+yo)*256)*4+1] = (color~/16)*16+8;

        int icolor = colormap[icolormap[x+y*16]];
        lookupTextureData[((x+xo)+(y+yo+32)*256)*4+0] = (icolor%16)*16+8;
        lookupTextureData[((x+xo)+(y+yo+32)*256)*4+1] = (icolor~/16)*16+8;
      }
    }
  }

  GL.Texture colorLookupTexture = gl.createTexture();
  gl.bindTexture(GL.TEXTURE_2D, colorLookupTexture);
  gl.texImage2DTyped(GL.TEXTURE_2D,  0,  GL.RGBA,  256,  256,  0,  GL.RGBA,  GL.UNSIGNED_BYTE, lookupTextureData);
  gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MIN_FILTER, GL.NEAREST);
  gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MAG_FILTER, GL.NEAREST);

  printToConsole("Setting up screen renderer");
  screenRenderer = new ScreenRenderer(screenBlitShader,  indexColorBuffers[0].texture, colorLookupTexture);

  WAD_Image skyImage = new WAD_Image.empty("_sky_", 1024, 128);
  WAD_Image sky = patchMap["SKY1"];
  for (int i=0; i<1024; i+=sky.width) {
    skyImage.draw(sky, i, 0, true);
  }
  skyTexture = skyImage.createTexture(wadFile.palette.palettes[0]);

  skyRenderer = new SkyRenderer(skyShader, skyTexture);

  querySelector("#consoleHolder").setAttribute("style",  "display:none;");
  window.onResize.listen((event) => resize());
  resize();
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
    gl.texImage2DTyped(GL.TEXTURE_2D,  0,  GL.RGBA,  width,  height,  0,  GL.RGBA,  GL.UNSIGNED_BYTE, null);
    gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    gl.texParameteri(GL.TEXTURE_2D,  GL.TEXTURE_MAG_FILTER, GL.NEAREST);

    gl.framebufferTexture2D(GL.FRAMEBUFFER,  GL.COLOR_ATTACHMENT0,  GL.TEXTURE_2D,  texture, 0);

    depthbuffer = gl.createRenderbuffer();
    gl.bindRenderbuffer(GL.RENDERBUFFER, depthbuffer);
    gl.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);

    gl.framebufferRenderbuffer(GL.FRAMEBUFFER,  GL.DEPTH_ATTACHMENT,  GL.RENDERBUFFER,  depthbuffer);
  }
}

void updateGameLogic(double passedTime) {
  if (passedTime>0.1) passedTime = 0.1;
  if (passedTime<0.001) passedTime = 0.001;

  double iRot = 0.0;
  double iY = 0.0;
  double iX = 0.0;
  if (keys[81] || keys[37]) iRot+=1.0;
  if (keys[69] || keys[39]) iRot-=1.0;

  if (keys[65]) iX+=1.0;
  if (keys[68]) iX-=1.0;

  if (keys[87]) iY+=1.0;
  if (keys[83]) iY-=1.0;
  
  
//  player.rot-=iRot*passedTime*3;
  if (iRot==0.0) player.rotMotion = 0.0;
  player.rotMotion-=iRot;
  player.move(iX, iY, passedTime);

  entities.forEach((entity) {
    entity.tick(passedTime);
  });

}

void renderGame() {
  indexColorBuffer = indexColorBuffers[indexColorBufferId];
  screenRenderer.texture = indexColorBuffer.texture;
  gl.bindFramebuffer(GL.FRAMEBUFFER, indexColorBuffer.framebuffer);
  gl.viewport(0,  0,  screenWidth,  screenHeight);
//  gl.clear(GL.DEPTH_BUFFER_BIT | GL.COLOR_BUFFER_BIT);

  projectionMatrix = makePerspectiveMatrix(60*PI/180,  screenWidth/screenHeight,  8,  10000.0).scale(-1.0, 1.0, 1.0);
  if (GAME_ORIGINAL_PIXEL_ASPECT_RATIO && !GAME_ORIGINAL_RESOLUTION) {
    // If the original aspect ratio is set, this scaling is done elsewhere.
    projectionMatrix = projectionMatrix.scale(1.0, 240/200, 1.0);
  }
  double bob = (sin(player.bobPhase)*0.5+0.5)*player.bobSpeed;
  viewMatrix = new Matrix4.identity().rotateY(player.rot+PI).translate(-player.pos).translate(0.0, -41.0+bob*8+player.stepUp, 0.0);
  Matrix4 invertedViewMatrix = new Matrix4.copy(viewMatrix)..invert();
  Vector3 cameraPos = invertedViewMatrix.transform3(new Vector3(0.0, 0.0, 0.0));

  List<Seg> visibleSegs = wadFile.level.bsp.findSortedSegs(invertedViewMatrix, projectionMatrix);
  visibleSegs.forEach((seg) => Wall.addWallsForSeg(seg));

  gl.enable(GL.CULL_FACE);
  gl.enable(GL.DEPTH_TEST);
  gl.depthFunc(GL.ALWAYS);
  floors.render(visibleSegs, cameraPos);
  gl.depthFunc(GL.LEQUAL);

  walls.values.forEach((walls) {
    walls.render();
    walls.clear();
  });

  gl.depthFunc(GL.ALWAYS);
  gl.colorMask(false, false, false, false);
  floors.renderBackWallHack(visibleSegs, cameraPos);
  gl.colorMask(true, true, true, true);
  gl.depthFunc(GL.LEQUAL);


  Matrix4 oldMatrix = projectionMatrix;
  projectionMatrix = makeOrthographicMatrix(0.0, screenWidth, screenHeight, 0.0, -10.0, 10.0);
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.ONE_MINUS_DST_ALPHA, GL.DST_ALPHA);
  gl.depthMask(false);
  skyRenderer.render();
  gl.depthMask(true);
  gl.disable(GL.BLEND);
  projectionMatrix = oldMatrix;

  sprites.forEach((sprite) {
    sprite.addToDisplayList(player.rot);
  });

  entities.forEach((entity) {
    entity.addToDisplayList(player.rot);
  });

  spriteMaps.values.forEach((sprites) {
    sprites.render();
    sprites.clear();
  });

  gl.colorMask(false, false, true, false);
  gl.depthMask(false);
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.DST_COLOR, GL.ZERO);
  transparentSpriteMaps.values.forEach((sprites) {
    sprites.render();
    sprites.clear();
  });
  gl.disable(GL.BLEND);
  gl.depthMask(true);
  gl.colorMask(true, true, true, true);

  transparentMiddleWalls.values.forEach((walls) {
    walls.render();
    walls.clear();
  });
}

void addGuiSprite(int x, int y, String imageName) {
  WAD_Image image = wadFile.spriteMap[imageName];
  guiSprites[image.imageAtlas.texture].insertGuiSprite(x, y, guiSpriteCount++, image);
}

int guiSpriteCount = 0;
void renderGui() {
  gl.disable(GL.DEPTH_TEST);
  double ww = screenWidth*200.0/screenHeight;
  if (!GAME_ORIGINAL_RESOLUTION && GAME_ORIGINAL_PIXEL_ASPECT_RATIO) {
    ww=ww*240/200;
  }
  double margin = ww-320;
  double x0 = 0.0-margin/2.0;
  double x1 = ww-margin/2.0;
  projectionMatrix = makeOrthographicMatrix(x0, x1, 200.0, 0.0, -10.0, 10.0);
  viewMatrix = new Matrix4.identity();
  
//  addGuiSprite(0, 0, "TITLEPIC");
  int x = (sin(player.bobPhase/2.0)*player.bobSpeed*20.5).round();
  int y = (cos(player.bobPhase/2.0)*player.bobSpeed*10.5).abs().round();
  addGuiSprite(x, 32+y, "SHTGA0");
  
  
  gl.enable(GL.BLEND);
  gl.disable(GL.CULL_FACE);
  gl.blendFunc(GL.SRC_ALPHA,  GL.ONE_MINUS_SRC_ALPHA);
  guiSprites.values.forEach((sprites) {
    sprites.render();
    sprites.clear();
  });  
  guiSpriteCount = 0;
  gl.enable(GL.CULL_FACE);
  gl.disable(GL.BLEND);
}

void blitScreen() {
  gl.bindFramebuffer(GL.FRAMEBUFFER, null);
  gl.viewport(0,  0,  screenWidth,  screenHeight);
  gl.disable(GL.DEPTH_TEST);
  projectionMatrix = makeOrthographicMatrix(0.0, screenWidth, screenHeight, 0.0, -10.0, 10.0);
//  skyRenderer.render();
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.SRC_ALPHA,  GL.ONE_MINUS_SRC_ALPHA);
  screenRenderer.render();
  gl.disable(GL.BLEND);
}

double scrollAccum = 0.0;
int indexColorBufferId = 0;
void updateAnimations(double passedTime) {
  scrollAccum+=passedTime*35.0;
  textureScrollOffset = scrollAccum.floor();
  transparentNoiseTime = (scrollAccum.floor())&511;
  indexColorBufferId = (indexColorBufferId+1)%3;
  FlatAnimation.animateAll(passedTime);
  WallAnimation.animateAll(passedTime);
}

double lastTime = -1.0;
void render(double time) {
  int error = gl.getError();
  if (error!=0) {
    print("Error: $error");
  } else {
    window.requestAnimationFrame(render);
  }

  if (lastTime==-1.0) lastTime = time;
  double passedTime = (time-lastTime)/1000.0; // in seconds
  lastTime = time;

  updateAnimations(passedTime);

  updateGameLogic(passedTime);
  renderGame();
  renderGui();
  blitScreen();
}