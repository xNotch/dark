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

const GAME_WIDTH = 320; 
const GAME_HEIGHT = 200-32; 
const TEXTURE_ATLAS_SIZE = 2048;


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
  canvas.setAttribute("width",  "${GAME_WIDTH}px");
  canvas.setAttribute("height",  "${GAME_HEIGHT}px");
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
  double xScale = width/GAME_WIDTH;
  double yScale = height/GAME_HEIGHT;
  if (xScale<yScale) {
    int newHeight = (GAME_HEIGHT*xScale).floor(); 
    canvas.setAttribute("style",  "width: ${width}px; height:${newHeight}px; left:0px; top:${(height-newHeight)~/3}px;");
  } else {
    int newWidth= (GAME_WIDTH*yScale).floor(); 
    canvas.setAttribute("style",  "width: ${newWidth}px; height:${height}px; left:${(width-newWidth)~/2}px; top:0px;");
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

  print("Starting!");
  modelMatrix = new Matrix4.identity();
  viewMatrix = new Matrix4.identity();
  projectionMatrix = makePerspectiveMatrix(60*PI/180,  GAME_WIDTH/GAME_HEIGHT,  0.1,  10000.0).scale(-1.0, 1.0, 1.0);

  //Texture spriteSheet = new Texture("sprites.png");
//  Texture.loadAll();

  //sprites = new Sprites(testShader, spriteSheet.texture);
/*  for (int i=0; i<100; i++) {
    double x = random.nextInt(GAME_WIDTH).toDouble();
    double y = random.nextInt(GAME_HEIGHT).toDouble();
    double r = 1.0;
    double g = 1.0;
    double b = 1.0;
    double a = 1.0;
    Sprite sprite = new Sprite(x-16, y-8, 2048.0, 2048.0, 0.0, 0.0, r, g, b, a); 
    sprites.addSprite(sprite);
    spriteList.add(sprite);
  }*/
//  sprites.addSprite(new Sprite(0.0, 0.0, 2048.0, 2048.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0));
  
/*  wall = new Sprites(testShader, spriteSheet.texture);
  for (int xx=0; xx<5; xx++) {
    for (int yy=0; yy<8; yy++) {
      double x = (xx+0.5)/5.0+(random.nextDouble()-0.5)*0.1;
      double y = -0.5+(yy+0.5)/8.0+(random.nextDouble()-0.5)*0.1;
      double z = 0.0+(random.nextDouble()-0.5)*0.1;
      double br = 1.0-random.nextDouble()*0.1;
      double r = (1.0-random.nextDouble()*0.1)*br;
      double g = (1.0-random.nextDouble()*0.1)*br;
      double b = (1.0-random.nextDouble()*0.1)*br;
      wall.addSprite(new Sprite(x, y, z, -16.0, -8.0, 32.0, 16.0, 32.0, 0.0, r, g, b));
    }
  }*/

  //  sprites.addSprite(new Sprite(0.0, 0.0, 0.0, -8.0, -8.0, 16.0, 16.0, 0.0, 0.0, 1.0, 1.0, 1.0));
//  sprites.addSprite(new Sprite(0.0, 0.0, 0.0, -8.0, -8.0, 16.0, 16.0, 0.0, 0.0, 1.0, 1.0, 1.0));
  
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
  playerPos.x-=(sin(playerRot)*iY-cos(playerRot)*iX)*passedTime*200.0;
  playerPos.z-=(cos(playerRot)*iY+sin(playerRot)*iX)*passedTime*200.0;
  
  playerPos.y = wadFile.level.bsp.findSector(playerPos.xz).floorHeight.toDouble()+50;
  
  viewMatrix = new Matrix4.identity().rotateY(playerRot).translate(-playerPos);
  
  gl.clearColor(0.0, 0.0, 0.0, 1.0);
  gl.clear(GL.DEPTH_BUFFER_BIT | GL.COLOR_BUFFER_BIT);
  gl.enable(GL.CULL_FACE);
  gl.enable(GL.DEPTH_TEST);
  gl.depthFunc(GL.ALWAYS);
  floors.render(wadFile.level.bsp, playerPos);
  gl.depthFunc(GL.EQUAL);
  
  walls.render();
  gl.depthFunc(GL.LESS);
  spriteMaps.values.forEach((sprites)=>sprites.render());
  
  window.requestAnimationFrame(render);
  
  int error = gl.getError();
  if (error!=0) {
    print("Error: $error");
  }
}