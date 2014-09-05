library WadExplorer;

import "dart:html";

import "dart:async";
import "dart:math";
import "dart:collection";
import "dart:typed_data";
import "wad/wad.dart" as WAD;


void main() {
  print("Loading WAD file");
  attemptToLoadWadData(["originaldoom/doom.wad", "freedoom/doom.wad"]).then((data) {
    WAD.WadFile wadFile = new WAD.WadFile.read(data); 
    wadFileLoaded(wadFile);
  });
}

Future<ByteData> attemptToLoadWadData(List<String> urls) {
  Completer<ByteData> completer = new Completer<ByteData>();
  
  Future<ByteData> future = loadByteDataFromUrl(urls[0]).then((byteData) {
    completer.complete(byteData);
  }).catchError((e) {
    if (urls.length>1) {
      print("Can't find ${urls[0]}, trying ${urls[1]}");
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

Future<ByteData> loadByteDataFromUrl(String url) {
  Completer<ByteData> completer = new Completer<ByteData>();
  ByteData result;
  HttpRequest request = new HttpRequest();
  request.open("get",  url);
  request.responseType = "arraybuffer";
  request.onProgress.every((progressEvent) {
    print(".");
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

void wadFileLoaded(WAD.WadFile wadFile) {
  WAD.Palette palette = wadFile.palette.palettes[0];
  
  Element content = querySelector("#content");
  List<String> spriteNames = new List<String>.from(wadFile.sprites.keys.where((name) {
    if (!(name.length==6 || name.length==8)) {
      print(name);
      return false;
    }
    if (name.substring(4, 6)=="A0" || name.substring(4, 6)=="A1") return true;
    if (name.length==8) {
      if (name.substring(6, 8)=="A0" || name.substring(6, 8)=="A1") return true;
    }
    return false;
  }));
  spriteNames.sort((s0, s1)=>s0.compareTo(s1));
  spriteNames.forEach((name) {
    name = name.substring(0, 4);
    ParagraphElement p = new ParagraphElement();
    p.appendText("$name [");
    int frame = 0;
    CanvasElement canvas = new CanvasElement();
    content.append(canvas);
    content.append(p);
    List<AnchorElement> allAnchors = new List<AnchorElement>();
    do {
      WAD.Image image = findFrame(wadFile, name, frame);
      if (frame==0) setFrame(canvas, image, palette);
      if (image!=null) {
        if (frame>0) p.appendText(",");

        AnchorElement a = new AnchorElement();
        if (frame==0) {
          a.setAttribute("style", "color:#ffff88");
        }
        allAnchors.add(a);
        p.append(a);
        
        a.onMouseOver.listen((e) {
          setFrame(canvas, image, palette);
          allAnchors.forEach((aa)=>aa.setAttribute("style", ""));
          a.setAttribute("style", "color:#ffff88");
        });
        a.text = "$frame";
        
        frame++;
      } else {
        break;
      }
    } while (true);
    p.appendText("]");
  });
}

WAD.Image findFrame(WAD.WadFile wadFile, String spriteName, int frame) {
  WAD.Image result = null;
  String frameName = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".substring(frame, frame+1);
  wadFile.sprites.keys.forEach((name) {
    if (name.startsWith(spriteName) && (name.length==6 || name.length==8)) {
      if (name.substring(4, 6)=="${frameName}0" || name.substring(4, 6)=="${frameName}1") {
        print("$frameName -> $name (${name.substring(4, 6)})");
        result = wadFile.sprites[name];
      }
      if (name.length==8) {
        // TODO: Mirror the frame omg lol
        if (name.substring(6, 8)=="${frameName}0" || name.substring(6, 8)=="${frameName}1") result = wadFile.sprites[name];
      }
    }
  });
  return result;
}

void setFrame(CanvasElement canvas, WAD.Image image, WAD.Palette palette) {
  canvas.width = 320;
  canvas.height = 200-32;
  //CanvasElement canvas = new CanvasElement(width: image.width, height: image.height);
  CanvasRenderingContext2D ctx = canvas.getContext("2d");
  ImageData img = ctx.getImageData(0, 0, canvas.width, canvas.height);
  img.data.fillRange(0,  canvas.width*canvas.height, 0);
  for (int y=0; y<image.height; y++) {
    for (int x=0; x<image.width; x++) {
      int pixel = image.pixels[x+y*image.width];
      int xx = x-image.xCenter;
      int yy = y-image.yCenter;
      if (image.xCenter>0 || image.yCenter>0) {
        xx+=canvas.width~/2;
        yy+=canvas.height-32;
      }
      if (pixel>=0 && xx>=0 && yy>=0 && xx<canvas.width && yy<canvas.height) {
        int i = xx+yy*canvas.width;
        img.data[i*4+0] = palette.r[pixel];
        img.data[i*4+1] = palette.g[pixel];
        img.data[i*4+2] = palette.b[pixel];
        img.data[i*4+3] = 255;
      }
    }
  }
  ctx.putImageData(img,  0,  0);
}