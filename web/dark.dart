library Dark;

import "dart:html";

import "dart:async";
import "dart:math";
import "dart:collection";
import "dart:typed_data";
import "dart:web_gl" as GL;
import "dart:web_audio";
import "package:vector_math/vector_math.dart";
import "wad/wad.dart" as WAD;

part "game.dart";
part "gameresources.dart";
part "shader.dart";
part "sprites.dart";
part "walls.dart";
part "texture.dart";
part "entity.dart";
part "bsp.dart";
part "level.dart";


const TEXTURE_ATLAS_SIZE = 1024;

bool crashed = false;
bool gameVisible = false;

int screenWidth, screenHeight;

int textureScrollOffset = 0;
int transparentNoiseTime = 0;
var canvas;
GL.RenderingContext gl;

var consoleText;


ScreenRenderer screenRenderer;
SkyRenderer skyRenderer;

bool invulnerable = false;

AudioContext audioContext;
List<bool> keys = new List<bool>(256);

Shader spriteShader, transparentSpriteShader, wallShader, floorShader, screenBlitShader, skyShader;

// Init method. Set up WebGL, load textures, etc
void main() {
  topLevelCatch(startup);
}

int xMouseMovement = 0, yMouseMovement = 0;

var consoleHolder = querySelector("#consoleHolder");
void startup() {
//  wadFile = new WadFile();
  consoleText = querySelector("#consoleText");

  printToConsole("-------------------------------------------------");
  printToConsole("$Game.NAME $Game.VERSION");
  printToConsole("-------------------------------------------------");
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
    if (!gameVisible) return;
    topLevelCatch((){
      print(e.keyCode);
      if (e.keyCode<256) keys[e.keyCode] = true;
    });
  });

  window.onKeyUp.listen((e) {
    if (!gameVisible) return;
    topLevelCatch((){
      if (e.keyCode<256) keys[e.keyCode] = false;
    });
  });

  window.onBlur.listen((e) {
    if (!gameVisible) return;
    topLevelCatch((){
      for (int i=0; i<256; i++) keys[i] = false;
    });
  });
  
  audioContext = new AudioContext();

  window.onClick.listen((e) {
    if (!gameVisible) return;
    topLevelCatch((){
      if (document.pointerLockElement!=canvas) {
        canvas.requestPointerLock();
      } else {
        playSound(null, "SHOTGN");
      }
    });
  });
  
  window.onMouseMove.listen((e) {
    if (!gameVisible) return;
    topLevelCatch((){
      if (document.pointerLockElement==canvas && player!=null) {
        xMouseMovement+=e.movement.x;
        yMouseMovement+=e.movement.y;
      }
    });
  });

  spriteShader = new Shader("sprite");
  transparentSpriteShader = new Shader("transparentsprite");
  wallShader = new Shader("wall");
  floorShader = new Shader("floor");
  screenBlitShader = new Shader("screenblit");
  skyShader = new Shader("sky");
  
  printToConsole("Loading and compiling shaders");
  Shader.loadAndCompileAll().catchError((e){
    crash("Failed to load shaders", e);
  }).then((_) { 
    topLevelCatch(() {
      printToConsole("Loading WAD file");
      attemptToLoadWadData(["originaldoom/doom.wad", "freedoom/doom.wad"]).then((data) {
        topLevelCatch((){
          WAD.WadFile wadFile = new WAD.WadFile.read(data); 
          wadFileLoaded(wadFile);
        });
      }).catchError((e) {
        crash("Failed to load WAD file", e);
      });
    });
  });
}

Future<ByteData> attemptToLoadWadData(List<String> urls) {
  Completer<ByteData> completer = new Completer<ByteData>();

  Future<ByteData> future = loadByteDataFromUrl(urls[0]).then((byteData) {
    completer.complete(byteData);
  }).catchError((e) {
    if (urls.length>1) {
      printToConsole("Can't find ${urls[0]}, trying ${urls[1]}");
      attemptToLoadWadData(urls.sublist(1)).then((byteData) {
        completer.complete(byteData);
      }).catchError((e) {
        completer.completeError(e);
      });
    } else {
      completer.completeError(e);
    }
  });
  
  return completer.future;
}

void wadFileLoaded(WAD.WadFile wadFile) {
  for (int i=0; i<32; i++) {
    soundChannels.add(new SoundChannel());
  }

  resources = new GameResources(wadFile);
  resources.loadAll();
  loadLevel("E1M1");
}

void loadLevel(String levelName) {
  printToConsole("Loading level $levelName");
  WAD.Level levelData = resources.wadFile.loadLevel(levelName);
  Level level = new Level(levelData);
  start(level);
}

Future<String> loadStringFromUrl(String url) {
  Completer<String> completer = new Completer<String>();
  ByteData result;
  var request = new HttpRequest();
  request.open("get",  url);
  Future future = request.onLoadEnd.first.then((e) {
    if (request.status~/100==2) {
      completer.complete(request.response as String);
    } else {
      completer.completeError("Can't load $url. Response type ${request.status}");
    }
  }).catchError((e)=>completer.completeError(e));
  request.send("");
  
  return completer.future;
}
  
Future<ByteData> loadByteDataFromUrl(String url) {
  Completer<ByteData> completer = new Completer<ByteData>();
  ByteData result;
  HttpRequest request = new HttpRequest();
  request.open("get",  url);
  request.responseType = "arraybuffer";
  request.onProgress.every((progressEvent) {
    printToConsoleNoNewLine(".");
    return true;
  });
  Future future = request.onLoadEnd.first.then((e) {
    if (request.status~/100==2) {
      completer.complete(new ByteData.view(request.response as ByteBuffer));
    } else {
      completer.completeError("Can't load $url. Response type ${request.status}");
    }
  }).catchError((e)=>completer.completeError(e));
  request.send("");
  
  return completer.future;
}

void resize() {
  int width = window.innerWidth;
  int height = window.innerHeight;
  double aspectRatio = width/height;
  double minAspect = Game.MIN_ASPECT_RATIO;
  double maxAspect = Game.MAX_ASPECT_RATIO;
  if (Game.ORIGINAL_SCREEN_ASPECT_RATIO) minAspect = maxAspect = 4/3;

  if (!Game.ORIGINAL_RESOLUTION) {
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
    gameVisible = true;
  } else {
    screenWidth = 320;
    screenHeight = 200;
    if (aspectRatio<minAspect) aspectRatio=minAspect;
    if (aspectRatio>maxAspect) aspectRatio=maxAspect;
    screenWidth = ((Game.ORIGINAL_PIXEL_ASPECT_RATIO?240:200)*aspectRatio).floor();

    double gameWidth = screenWidth.toDouble();
    double gameHeight = screenHeight.toDouble();
    if (Game.ORIGINAL_PIXEL_ASPECT_RATIO) gameHeight*=240/200;

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
    gameVisible = true;
  }
}

class GameEndError extends Error {
  GameEndError() {
  }
}

void crash(String title, var payload, [stackTrace = null]) {
  if (crashed) throw payload;
  
  try {
    canvas.setAttribute("style", "display:none;");
    gameVisible = false;
    document.exitPointerLock();
    querySelector("#consoleHolder").setAttribute("style",  "");
  } catch (e) {};
  
  crashed = true;
  
  printToConsole("");
  printToConsole("");
  printToConsole("-------------------------------------------------");
  printToConsole("                      CRASH                      ");
  printToConsole("-------------------------------------------------");
  printToConsole(title);
  printToConsole("");
  printToConsole("$payload");
  if (stackTrace!=null) {
    printToConsole("");
    printToConsole("Stack trace:");
    printToConsole("$stackTrace");
  }
  
  throw new GameEndError();
}

void printToConsoleNoNewLine(String message) {
  consoleText.appendHtml(message);
  consoleHolder.scrollTop = consoleHolder.scrollHeight;
}

void printToConsole(String message) {
  consoleText.appendHtml("\r"+message);
  consoleHolder.scrollTop = consoleHolder.scrollHeight;
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
PannerNode pannerNode;
AudioBufferSourceNode nodeHack;

class SoundChannel {
  PannerNode pannerNode;
  AudioBufferSourceNode source;
  Vector3 pos;
  bool playing = false;
  int startAge;
  
  SoundChannel() {
  }
  
  void play(Vector3 pos, AudioBuffer buffer) {
    startAge = new DateTime.now().millisecondsSinceEpoch;
    
    this.pos = pos;
    if (pos!=null) {
      pannerNode = audioContext.createPanner();
      pannerNode.refDistance = 300.0;
      pannerNode.rolloffFactor = 3.5;
      pannerNode.distanceModel = "exponential";
      pannerNode.panningModel = "equalpower";
      pannerNode.connectNode(audioContext.destination);
    }
      
    playing = true;
    
    update();
    
    source = audioContext.createBufferSource();
    source.onEnded.listen((e)=>finished());
    if (pos!=null) {
      source.connectNode(pannerNode);
    } else {
      source.connectNode(audioContext.destination);
    }
    source.buffer = buffer;
    source.start();
  }
  
  void finished() {
    source = null;
    pannerNode = null;
    playing = false;
    pos = null;
    soundChannels.remove(this);
  }
  
  void update() {
    if (pos!=null) {
      pannerNode.setPosition(pos.x, pos.y, pos.z);
      pannerNode.setPosition(pos.x, pos.y, pos.z);
      pannerNode.setPosition(pos.x, pos.y, pos.z);
      pannerNode.setPosition(pos.x, pos.y, pos.z);
    }
  }
}

List<SoundChannel> soundChannels = new List<SoundChannel>();
GameResources resources;

void playSound(Vector3 pos, String soundName) {
  if (pos!=null && pos.distanceToSquared(player.pos)>1200*1200) return;
  SoundChannel soundChannel = new SoundChannel();
  soundChannel.play(pos, resources.sampleMap[soundName]);
  soundChannels.add(soundChannel);
}

Level level;
void start(Level _level) {
  level = _level;
  player = new Player(level, level.playerSpawns[0].pos, level.playerSpawns[0].rot);

  modelMatrix = new Matrix4.identity();
  viewMatrix = new Matrix4.identity();

  int frameBufferRes = 512;
  if (!Game.ORIGINAL_RESOLUTION) frameBufferRes = 2048;
  for (int i=0; i<3; i++) {
    indexColorBuffers[i] = new Framebuffer(frameBufferRes, frameBufferRes);
  }

  printToConsole("Creating color lookup texture");
  Uint8List lookupTextureData = new Uint8List(256*256*4);
  // Top row: 14 16*16 grids of color look-ups, based on PLAYPAL
  for (int i=0; i<14; i++) {
    WAD.Palette palette = resources.wadFile.palette.palettes[i];
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
    List<int> colormap = resources.wadFile.colormap.colormaps[i];
    List<int> icolormap = resources.wadFile.colormap.colormaps[32];
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
  
  

  WAD.Image skyImage = new WAD.Image.empty("_sky_", 1024, 128);
  WAD.Image sky = resources.wadFile.patches["SKY1"];
  for (int i=0; i<1024; i+=sky.width) {
    skyImage.draw(sky, i, 0, true);
  }
  skyTexture = new Image.fromWadImage(skyImage).createTexture(resources.wadFile.palette.palettes[0]);

  skyRenderer = new SkyRenderer(skyShader, skyTexture);

  querySelector("#consoleHolder").setAttribute("style",  "display:none;");
  window.onResize.listen((event) => resize());
  resize();
  
  pannerNode = audioContext.createPanner();
  pannerNode.refDistance = 300.0;
  pannerNode.rolloffFactor = 3.0;
  pannerNode.distanceModel = "exponential";
  pannerNode.connectNode(audioContext.destination);

  requestAnimationFrame();
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

  level.entities.forEach((entity) {
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
  if (Game.ORIGINAL_PIXEL_ASPECT_RATIO && !Game.ORIGINAL_RESOLUTION) {
    // If the original aspect ratio is set, this scaling is done elsewhere.
    projectionMatrix = projectionMatrix.scale(1.0, 240/200, 1.0);
  }
  double bob = (sin(player.bobPhase)*0.5+0.5)*player.bobSpeed;
  viewMatrix = new Matrix4.identity().rotateY(player.rot+PI).translate(-player.pos).translate(0.0, -41.0+bob*8+player.stepUp, 0.0);
  Matrix4 invertedViewMatrix = new Matrix4.copy(viewMatrix)..invert();
  Vector3 cameraPos = invertedViewMatrix.transform3(new Vector3(0.0, 0.0, 0.0));

  List<Segment> visibleSegs = level.bsp.findSortedSegs(invertedViewMatrix, projectionMatrix);
  visibleSegs.forEach((seg) => seg.renderWalls());

  gl.enable(GL.CULL_FACE);
  gl.enable(GL.DEPTH_TEST);
  gl.depthFunc(GL.ALWAYS);
  renderers.floors.render(visibleSegs, cameraPos);
  gl.depthFunc(GL.LEQUAL);

  renderers.walls.values.forEach((walls) {
    walls.render();
    walls.clear();
  });

  gl.depthFunc(GL.ALWAYS);
  gl.colorMask(false, false, false, false);
  // TODO: Fix the floor hack!
//  floors.renderBackWallHack(visibleSegs, cameraPos);
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

  level.entities.forEach((entity) {
    entity.addToDisplayList(player.rot);
  });


  renderers.spriteMaps.values.forEach((sprites) {
    sprites.render();
    sprites.clear();
  });

  gl.colorMask(false, false, true, false);
  gl.depthMask(false);
  gl.enable(GL.BLEND);
  gl.blendFunc(GL.DST_COLOR, GL.ZERO);
  renderers.transparentSpriteMaps.values.forEach((sprites) {
    sprites.render();
    sprites.clear();
  });
  gl.disable(GL.BLEND);
  gl.depthMask(true);
  gl.colorMask(true, true, true, true);

  renderers.transparentMiddleWalls.values.forEach((walls) {
    walls.render();
    walls.clear();
  });
}



int guiSpriteCount = 0;
void renderGui() {
  gl.disable(GL.DEPTH_TEST);
  int ww = screenWidth*200~/screenHeight;
  if (!Game.ORIGINAL_RESOLUTION && Game.ORIGINAL_PIXEL_ASPECT_RATIO) {
    ww=ww*240~/200;
  }
  int margin = ww-320;
  double x0 = 0.0-margin~/2;
  double x1 = 0.0+ww-margin~/2;
  projectionMatrix = makeOrthographicMatrix(x0, x1, 200.0, 0.0, -10.0, 10.0);
  viewMatrix = new Matrix4.identity();
  
//  addGuiSprite(0, 0, "TITLEPIC");
  int x = (sin(player.bobPhase/2.0)*player.bobSpeed*20.5).round();
  int y = (cos(player.bobPhase/2.0)*player.bobSpeed*10.5).abs().round();
  renderers.addGuiSprite(x, 32+y, "SHTGA0");
  renderers.addGuiText(0, 0, "FPS: ${(1.0/lastFrameSeconds).toStringAsPrecision(4)}");
  renderers.addGuiText(0, 8, "MS: ${(lastFrameLogicSeconds*1000).toStringAsPrecision(4)}");
  renderers.addGuiText(0, 16, "MAX FPS: ${(1.0/lastFrameLogicSeconds).toStringAsPrecision(4)}");
  
  
  gl.enable(GL.BLEND);
  gl.disable(GL.CULL_FACE);
  gl.blendFunc(GL.SRC_ALPHA,  GL.ONE_MINUS_SRC_ALPHA);
  renderers.guiSprites.values.forEach((sprites) {
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
double soundTime = 0.0;
void updateAnimations(double passedTime) {
  scrollAccum+=passedTime*35.0;
  textureScrollOffset = scrollAccum.floor();
  transparentNoiseTime = (scrollAccum.floor())&511;
  indexColorBufferId = (indexColorBufferId+1)%3;
//  FlatAnimation.animateAll(passedTime);
  //WallAnimation.animateAll(passedTime);
  
  soundTime-=passedTime;
  if (soundTime<0.0) {
/*    AudioBufferSourceNode node = audioContext.createBufferSource();
    node.connectNode(pannerNode);
    node.buffer = sampleMap["CLAW"];
    node.start();*/
    soundTime+=0.5;
  }
}

void requestAnimationFrame() {
  if (crashed) return;
  window.requestAnimationFrame((time)=>topLevelCatch(()=>render(time)));
}

double lastTime = -1.0;
double lastFrameSeconds = 0.0;
double lastFrameLogicSeconds = 0.0;
void render(double time) {
  player.rot+=xMouseMovement*0.002;
  xMouseMovement = yMouseMovement = 0;

  audioContext.listener.setPosition(player.pos.x, player.pos.y, player.pos.z);
  audioContext.listener.setOrientation(sin(player.rot), 0.0, cos(player.rot), 0.0, -1.0, 0.0);
  int error = gl.getError();
  if (error!=0) {
    crash("OpenGL error", "$error");
    print("Error: $error");
  } else {
    requestAnimationFrame();
  }

  if (lastTime==-1.0) lastTime = time;
  double passedTime = (time-lastTime)/1000.0; // in seconds
  lastFrameSeconds = passedTime;
  lastTime = time;

  int before = new DateTime.now().millisecondsSinceEpoch;
  updateAnimations(passedTime);

  updateGameLogic(passedTime);
  renderGame();
  renderGui();
  blitScreen();
  
  int after = new DateTime.now().millisecondsSinceEpoch;
  lastFrameLogicSeconds = lastFrameLogicSeconds+((after-before)/1000.0-lastFrameLogicSeconds)*0.2;
  
  for (int i=0; i<soundChannels.length; i++) {
    soundChannels[i].update();
  }
}

void topLevelCatch(Function f) {
  try {
    f();
  } on GameEndError catch (e) {
  } catch (e, s) {
    crash("Uncaught exception", e, s);
  }
}