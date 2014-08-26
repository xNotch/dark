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


bool GAME_ORIGINAL_RESOLUTION = true; // Original doom was 320x200 pixels
bool GAME_ORIGINAL_SCREEN_ASPECT_RATIO = false; // Original doom was 4:3.
bool GAME_ORIGINAL_PIXEL_ASPECT_RATIO = true; // Original doom used slightly vertically stretched pixels (320x200 pixels in 4:3)

double GAME_MIN_ASPECT_RATIO = 4/3; // Letterbox if aspect ratio is lower than this
double GAME_MAX_ASPECT_RATIO = 2.35/1.0; // Pillarbox if aspect ratio is higher than this


const TEXTURE_ATLAS_SIZE = 2048;


int screenWidth, screenHeight;


var canvas;
GL.RenderingContext gl;

HashMap<GL.Texture, Sprites> spriteMaps = new HashMap<GL.Texture, Sprites>();
Walls walls;
Floors floors;

void addSpriteMap(GL.Texture texture) {
  spriteMaps[texture] = new Sprites(spriteShader, texture);
}

void addSprite(Sprite sprite) {
  spriteMaps[sprite.texture].addSprite(sprite);
}

void addWall(Wall wall) {
  if (wall.texture==null) return;
  if (walls==null) walls = new Walls(wallShader, null);
  walls.addWall(wall);
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

  floors = new Floors(floorShader, null);
  
  wadFile.load("doom.wad", start);
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
    if (GAME_ORIGINAL_PIXEL_ASPECT_RATIO) gameHeight=240/200;
  
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
double playerRot = 0.0;

void start() {
  floors.texture = flatMap.values.first.imageAtlas.texture;

  modelMatrix = new Matrix4.identity();
  viewMatrix = new Matrix4.identity();
  window.requestAnimationFrame(render);
}

double lastTime = -1.0;
void render(double time) {
  if (lastTime==-1.0) lastTime = time;
  double passedTime = (time-lastTime)/1000.0; // in seconds
  
  if (passedTime>0.1) passedTime = 0.1;
  if (passedTime<0.0) passedTime = 0.0;
  lastTime = time;
  
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
  
  playerPos.y = wadFile.level.bsp.findSector(playerPos.xz).floorHeight.toDouble()+50;
  
  projectionMatrix = makePerspectiveMatrix(60*PI/180,  screenWidth/screenHeight,  0.1,  10000.0).scale(-1.0, 1.0, 1.0);
  if (GAME_ORIGINAL_PIXEL_ASPECT_RATIO && !GAME_ORIGINAL_RESOLUTION) {
    // If the original aspect ratio is set, this scaling is done elsewhere.
    projectionMatrix = projectionMatrix.scale(1.0, 240/200, 1.0);
  }
  viewMatrix = new Matrix4.identity().rotateY(playerRot).translate(-playerPos);

  gl.viewport(0,  0,  screenWidth,  screenHeight);
  gl.enable(GL.CULL_FACE);
  gl.enable(GL.DEPTH_TEST);
  gl.depthFunc(GL.ALWAYS);
  floors.render(wadFile.level.bsp, playerPos);
  gl.depthFunc(GL.LEQUAL);
  
  walls.render();
  gl.depthFunc(GL.LESS);
  spriteMaps.values.forEach((sprites)=>sprites.render());
  
  window.requestAnimationFrame(render);
  
  int error = gl.getError();
  if (error!=0) {
    print("Error: $error");
  }
}