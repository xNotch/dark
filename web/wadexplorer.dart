library WadExplorer;

import "dart:html";

import "dart:async";
import "dart:math";
import "dart:collection";
import "dart:typed_data";
import "dart:web_audio";
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

SpanElement lastSelectedName;
AnchorElement lastSelectedA;
AudioContext audioContext;

void wadFileLoaded(WAD.WadFile wadFile) {
  WAD.Palette palette = wadFile.palette.palettes[0];
  
  Element content = querySelector("#content");
  audioContext = new AudioContext();
  
  ParagraphElement sp = new ParagraphElement();
  bool first = true;
  List<String> sampleNames = new List<String>.from(wadFile.samples.keys);
  sampleNames.sort((s0, s1)=>s0.compareTo(s1));
  sampleNames.forEach((name) {
    WAD.Sample sample = wadFile.samples[name];
    AudioBuffer audioBuffer;
    if (sample==null) {
      audioBuffer = audioContext.createBuffer(1, 1000, 44000);
    } else {
      audioBuffer = audioContext.createBuffer(1,  sample.sampleCount*4, sample.rate*4);
      Float32List bufferData = audioBuffer.getChannelData(0);
      for (int i=0; i<sample.sampleCount*4; i++) {
        bufferData[i] = (sample.samples[i~/4]/255.0)*2.0-1.0;
      }
    }

    if (!first) {
      sp.appendText(" ");
    } else {
      first = false;
    }
    AnchorElement a = new AnchorElement(href: "#${name.substring(2)}");
    a.onClick.listen((e) {
      AudioBufferSourceNode abs = audioContext.createBufferSource();
      abs.buffer = audioBuffer;
      abs.connectNode(audioContext.destination);
      abs.start(0.0);
    });
    a.text = name.substring(2);
    sp.append(a);
  });
  content.append(sp);
  
  List<String> spriteNames = new List<String>.from(wadFile.sprites.keys.where((name) {
    if (!(name.length==6 || name.length==8)) {
      return false;
    }
    if (name.substring(4, 6)=="A0" || name.substring(4, 6)=="A1") return true;
    if (name.length==8) {
      if (name.substring(6, 8)=="A0" || name.substring(6, 8)=="A1") return true;
    }
    return false;
  }));
  CanvasElement canvas = new CanvasElement();
  content.append(canvas);
  
  first = true;
  spriteNames.sort((s0, s1)=>s0.compareTo(s1));
  spriteNames.forEach((name) {
    if (!first) {
      content.appendHtml("<br>");
    } else {
      first = false;
    }
    name = name.substring(0, 4);
//    ParagraphElement p = new ParagraphElement();
    SpanElement nameSpan = new SpanElement();
    nameSpan.appendHtml("$name: ");
    content.append(nameSpan);
    int frame = 0;


    
    List<AnchorElement> allAnchors = new List<AnchorElement>();
    List<WAD.Image> images = new List<WAD.Image>(); 
    do {
      WAD.Image image = findFrame(wadFile, name, frame);
      if (image!=null) {
        images.add(image);
        frame++;
      } else {
        break;
      }
    } while (true);
    
    int x0 = 0;
    int y0 = 0;
    int x1 = 0;
    int y1 = 0;
    for (int i=0; i<images.length; i++) {
      WAD.Image image = images[i];
      if (i==0) {
        x0 = -image.xCenter;
        y0 = -image.yCenter;
        x1 = -image.xCenter+image.width;
        y1 = -image.yCenter+image.height;
      } else {
        if (x0 > -image.xCenter) x0 = -image.xCenter;
        if (y0 > -image.yCenter) y0 = -image.yCenter;
        
        if (x1 < -image.xCenter+image.width) x1 = -image.xCenter+image.width;
        if (y1 < -image.yCenter+image.height) y1 = -image.yCenter+image.height;
      }
    }
    
    for (int i=0; i<images.length; i++) {
      WAD.Image image = images[i];
//      if (i>0) p.appendText(",");

      AnchorElement a = new AnchorElement(href: "${image.name}_$i");
      if (frame==0) {
        a.setAttribute("style", "color:#ffff88");
      }
      allAnchors.add(a);
      content.append(a);
      
      a.onMouseOver.listen((e) {
        if (lastSelectedName!=null) {
          lastSelectedName.setAttribute("style",  "");
        }
        if (lastSelectedA!=null) {
          lastSelectedA.setAttribute("style",  "");          
        }
        setFrame(x0, y0, x1, y1, canvas, image, palette);
        a.setAttribute("style", "color:#ffffFF;");
        nameSpan.setAttribute("style", "color:#ffffff;");
        lastSelectedName = nameSpan;
        lastSelectedA = a;
      });
      String frameName = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".substring(i, i+1);
      a.text = "$frameName";
    }
  });

  List<String> wallTextureNames = new List<String>.from(wadFile.wallTextures.keys);
  wallTextureNames.sort((s0, s1)=>s0.compareTo(s1));
  wallTextureNames.forEach((name) {
    print(name);
    if (!first) {
      content.appendHtml("<br>");
    } else {
      first = false;
    }
    int frame = 0;
    
    WAD.Image image = wadFile.wallTextures[name];
    
    int x0 = -image.xCenter;
    int y0 = -image.yCenter;
    int x1 = -image.xCenter+image.width;
    int y1 = -image.yCenter+image.height;
    
    AnchorElement a = new AnchorElement(href: "${image.name}");
    a.text = name;
    content.append(a);
    
    a.onMouseOver.listen((e) {
      if (lastSelectedName!=null) {
        lastSelectedName.setAttribute("style",  "");
      }
      if (lastSelectedA!=null) {
        lastSelectedA.setAttribute("style",  "");          
      }
      setFrame(x0, y0, x1, y1, canvas, image, palette);
      a.setAttribute("style", "color:#ffffFF;");
      lastSelectedName = null;
      lastSelectedA = a;
    });
  });  
}

WAD.Image findFrame(WAD.WadFile wadFile, String spriteName, int frame) {
  WAD.Image result = null;
  String frameName = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".substring(frame, frame+1);
  wadFile.sprites.keys.forEach((name) {
    if (name.startsWith(spriteName) && (name.length==6 || name.length==8)) {
      if (name.substring(4, 6)=="${frameName}0" || name.substring(4, 6)=="${frameName}1") {
        result = wadFile.sprites[name];
      }
      if (name.length==8) {
        if (name.substring(6, 8)=="${frameName}0" || name.substring(6, 8)=="${frameName}1") {
          print("$frameName -> $name (${name.substring(4, 6)})");
          result = new WAD.Image.mirror(wadFile.sprites[name]);
          print("$result");
        }
      }
    }
  });
  return result;
}

void setFrame(int x0, int y0, int x1, int y1, CanvasElement canvas, WAD.Image image, WAD.Palette palette) {
  int scale = 2;
  int w = x1-x0;
  int h = y1-y0;
  w*=scale;
  h*=scale;
  print("$w, $h from $x0, $y0 -> $x1, $y1");
  canvas.width = w;
  canvas.height = h;
  //CanvasElement canvas = new CanvasElement(width: image.width, height: image.height);
  CanvasRenderingContext2D ctx = canvas.getContext("2d");
  ImageData img = ctx.getImageData(0, 0, w, h);
  img.data.fillRange(0, w*h, 0);
  for (int y=0; y<image.height*scale; y++) {
    for (int x=0; x<image.width*scale; x++) {
      int pixel = image.pixels[(x~/scale)+(y~/scale)*image.width];
      int xx = (x-image.xCenter*scale-x0*scale);
      int yy = (y-image.yCenter*scale-y0*scale);
      if (pixel>=0 && xx>=0 && yy>=0 && xx<w && yy<h) {
        int i = xx+yy*w;
        img.data[i*4+0] = palette.r[pixel];
        img.data[i*4+1] = palette.g[pixel];
        img.data[i*4+2] = palette.b[pixel];
        img.data[i*4+3] = 255;
      }
    }
  }
  ctx.putImageData(img,  0,  0);
}