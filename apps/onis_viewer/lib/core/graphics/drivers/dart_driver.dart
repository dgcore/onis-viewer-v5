import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:onis_viewer/core/dicom/dicom_bridge_frame.dart';
import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';
import 'package:onis_viewer/core/math/matrix.dart';

///////////////////////////////////////////////////////////////////////
// context
///////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
// OsTextCacheWeb
///////////////////////////////////////////////////////////////////////

class OsTextCache {
  int maxEntries = 20;
  WeakReference<Object>? handle;
  List<OsDriverText> videoTexts = [];

  OsTextCache(OsDriverText text, Object? data) {
    videoTexts.add(text);
    if (data != null) handle = WeakReference<Object>(data);
  }
}

class OsDartDriverContext extends OsDriverContext {
  Canvas? canvas;
  final Paint _paint = Paint();
  Color clearColor = Colors.black;
  final List<OsTextCache> _texts = [];
  int _maxTexEntries = 20;

  OsDartDriverContext(super.driver);

  //--------------------------------------------
  //video text
  //--------------------------------------------

  @override
  bool registerText(OsDriverText item, Object data) {
    OsDriver? localDriver = driver;
    if (localDriver == null) return false;
    if (!identical(localDriver.currentContext, this)) {
      localDriver.currentContext = this;
    }
    for (int i = 0; i < _texts.length; i++) {
      OsTextCache tmp = _texts[i];

      if (tmp.handle != null && identical(tmp.handle!.target, data)) {
        for (int j = 0; j < _texts[i].videoTexts.length; j++) {
          if (_texts[i].videoTexts[j].text == item.text) return false;
        }
        _texts[i].videoTexts.add(item);
        return true;
      }
    }
    OsTextCache info = OsTextCache(item, data);
    _texts.add(info);
    return true;
  }

  @override
  OsDriverText? findText(
      Object data, String value, String fontName, int fontSize) {
    for (int i = 0; i < _texts.length; i++) {
      OsTextCache tmp = _texts[i];
      if (tmp.handle != null && identical(tmp.handle!.target, data)) {
        for (int j = 0; j < _texts[i].videoTexts.length; j++) {
          List<int> candidateFontSize = [0];
          String candidateFontName =
              _texts[i].videoTexts[j].getFont(candidateFontSize);
          if (candidateFontSize[0] == fontSize &&
              candidateFontName == fontName &&
              _texts[i].videoTexts[j].text == value) {
            return _texts[i].videoTexts[j];
          }
        }
      }
    }
    return null;
  }

  @override
  void cleanTexts() {
    OsDriver? localDriver = driver;
    if (localDriver == null) return;
    if (!identical(localDriver.currentContext, this)) {
      localDriver.currentContext = this;
    }
    for (int i = 0; i < _texts.length; i++) {
      OsTextCache tmp = _texts[i];
      if (tmp.handle == null || tmp.handle!.target == null) {
        _texts.removeAt(i);
        i--;
      }
    }
    int dif = _texts.length - _maxTexEntries;
    for (int i = 0; i < dif; i++) {
      _texts.removeAt(0);
    }
  }

  @override
  void resetTexts() {
    OsDriver? localDriver = driver;
    if (localDriver == null) return;
    if (!identical(localDriver.currentContext, this)) {
      localDriver.currentContext = this;
    }
    _texts.clear();
  }

  @override
  void setMaximumVideoTextEntries(int maxValue) {
    if (maxValue > 0 && maxValue < 10000) _maxTexEntries = maxValue;
  }

  //--------------------------------------------
  //character list
  //--------------------------------------------

  @override
  OsDriverCharacterList? createCharacterList(String id) {
    return null;
  }

  @override
  OsDriverCharacterList? findCharacterList(String id) {
    return null;
  }

  @override
  bool removeCharacterList(String id) {
    return false;
  }

  //--------------------------------------------
  //colors
  //--------------------------------------------
  /*void setClearColor4d(double red, double green, double blue, double alpha) {
		_clearColor = 'rgba(' + Math.round(red*255) + ',' + Math.round(green*255) + ',' + Math.round(blue*255) + ',' + alpha + ')';
	}

	public setClearColor4i(red =number, green =number, blue =number, alpha =number):void {
		_clearColor = 'rgba(' + red + ',' + green + ',' + blue + ',' + alpha/255.0 + ')';
	}

	public setClearColor4iv(rgba =[number, number, number, number]):void {
		_clearColor = 'rgba(' + rgba[0] + ',' + rgba[1] + ',' + rgba[2] + ',' + rgba[3]/255.0 + ')';
	}

	public getClearColorAsString():string {
		return _clearColor;
	}

	public setColor4d(red =number, green =number, blue =number, alpha =number):void {
		_color = 'rgba(' + Math.round(red*255) + ',' + Math.round(green*255) + ',' + Math.round(blue*255) + ',' + alpha + ')';
	}

	public setColor4i(red =number, green =number, blue =number, alpha =number):void {
		_color = 'rgba(' + red + ',' + green + ',' + blue + ',' + alpha/255.0 + ')';
	}

	public setColor4iv(rgba =number[]):void {
		_color = 'rgba(' + rgba[0] + ',' + rgba[1] + ',' + rgba[2] + ',' + rgba[3]/255.0 + ')';
	}

	public setColor3h(value =string):void {
		_color = value;
	}

	public setColorString(value =string):void {
		_color = value;
	}
	
	public getColorAsString():string {
		return _color;
	}

	//--------------------------------------------
	//line
	//--------------------------------------------
	public setLineWidth(width =number) {
		_lineWidth = width;
	}
	
	public getLineWidth():number {
		return _lineWidth;
	}

	public setLineStipple(enable =boolean):boolean { 
		_lineStipple = enable;
		return true; 
	}

	public isLineStippleEnabled():boolean {
		return _lineStipple;
	}

	//--------------------------------------------
	//point size
	//--------------------------------------------
	
	public setPointSize(size =number) {
		_pointSize = size;
	}

	public getPointSize():number {
		return _pointSize;
	}*/

  //operations:
  /*@override
  void resize(double width, double height) {}

  @override
  void setTargetBuffer(int target) {}

  @override
  void swappBuffers() {}

  //character list:
  @override
  OsDriverCharacterList? createCharacterList(String id) {
    return null;
  }

  @override
  OsDriverCharacterList? findCharacterList(String id) {
    return null;
  }

  @override
  bool removeCharacterList(String id) {
    return false;
  }

  //capacity:
  @override
  void getMaximumTextureSize(List<double> size) {
    size[0] = 0;
    size[1] = 0;
  }

  //cleanup:
  @override
  void cleanup() {}*/
}

///////////////////////////////////////////////////////////////////////
// driver
///////////////////////////////////////////////////////////////////////

class OsDartDriver extends OsDriver {
  OsDartDriverContext? _currentContext;
  final List<double> _viewport = [0, 0, 0, 0];
  int _clipDepth = 0;
  final List<Rect> _clipStack = [];

  // Getters:
  @override
  String get id => 'DART';

  // Context:
  @override
  OsDriverContext createContext() {
    return OsDartDriverContext(this);
  }

  @override
  OsDriverContext? get currentContext => _currentContext;

  @override
  set currentContext(OsDriverContext? ctx) {
    _currentContext = ctx as OsDartDriverContext?;
  }

  //viewport:
  @override
  void setViewport(
      double offsetX, double offsetY, double width, double height) {
    _viewport[0] = offsetX;
    _viewport[1] = offsetY;
    _viewport[2] = width;
    _viewport[3] = height;
  }

  @override
  void getViewport(List<double> viewport) {
    viewport[0] = _viewport[0];
    viewport[1] = _viewport[1];
    viewport[2] = _viewport[2];
    viewport[3] = _viewport[3];
  }

  // Clipping:
  @override
  bool pushClipping(
      double offsetX, double offsetY, double width, double height) {
    if (_currentContext == null || _currentContext!.canvas == null) {
      return false;
    }
    _currentContext!.canvas!.save();
    Rect clipRect = Rect.fromLTWH(offsetX, offsetY, width, height);
    _currentContext!.canvas!.clipRect(clipRect);
    _clipStack.add(clipRect);
    _clipDepth++;
    return true;
  }

  @override
  bool popClipping() {
    if (currentContext == null || _currentContext!.canvas == null) {
      return false;
    }
    _currentContext!.canvas!.restore();
    if (_clipDepth > 0) {
      _clipDepth--;
      if (_clipStack.isNotEmpty) _clipStack.removeLast();
    }
    return true;
  }

  @override
  bool disableClipping() {
    return false;
  }

  @override
  bool isClippingEnabled() {
    return _clipDepth > 0;
  }

  @override
  void getClipArea(List<double> output) {
    if (_clipStack.isEmpty) {
      if (output.length >= 4) {
        output[0] = 0;
        output[1] = 0;
        output[2] = 0;
        output[3] = 0;
      }
      return;
    }
    Rect effective = _clipStack.first;
    for (int i = 1; i < _clipStack.length; i++) {
      effective = effective.intersect(_clipStack[i]);
    }
    if (output.length >= 4) {
      output[0] = effective.left;
      output[1] = effective.top;
      output[2] = effective.width;
      output[3] = effective.height;
    }
  }

  // Clear:
  @override
  void setClearColor4d(double red, double green, double blue, double alpha) {}

  @override
  void setClearColor4i(int red, int green, int blue, int alpha) {
    _currentContext?.clearColor = Color.fromARGB(alpha, red, green, blue);
  }

  @override
  void clearBuffers() {
    _currentContext?.canvas
        ?.drawColor(_currentContext?.clearColor ?? Colors.black, BlendMode.src);
  }

  @override
  void resetTransform() {}

  // Colors:
  @override
  void setColor4d(double red, double green, double blue, double alpha) {}
  @override
  void setColor4i(int red, int green, int blue, int alpha) {
    _currentContext?._paint.color = Color.fromARGB(alpha, red, green, blue);
  }

  @override
  void setColor4iv(List<int> rgba) {}
  @override
  void setColor3h(String value) {}
  @override
  void setColorString(String value) {}

  //Line:
  @override
  void setLineWidth(double width) {}
  @override
  bool enableLineStipple(bool enable) {
    return false;
  }

  //Point size:
  @override
  void setPointSize(double size) {}

  //Draw:
  @override
  void fillSolidRect(OsRenderInfo info, double width, double height) {
    _currentContext?._paint.style = PaintingStyle.fill;
    _currentContext?._paint.isAntiAlias = true;
    _currentContext?.canvas?.drawRect(
      Rect.fromLTWH(
          info.worldMat.mat[12], info.worldMat.mat[13], width, height),
      _currentContext?._paint ?? Paint(),
    );
  }

  @override
  void drawLine(
      OsRenderInfo info, double x1, double y1, double x2, double y2) {}
  @override
  void drawRect(
      OsRenderInfo info, double x1, double y1, double x2, double y2) {}
  @override
  void drawPoint(OsRenderInfo info, double x, double y) {}
  @override
  void drawEllipse(OsRenderInfo info, double a, double b) {}
  @override
  void fillTriangle(
      OsRenderInfo info, List<double> a, List<double> b, List<double> c) {}
  @override
  void drawImage(OsRenderInfo info, OsDriverImage image, double offsetX,
      double offsetY, double width, double height) {}

  //Images:
  @override
  OsDriverImage? createImage() {
    return OsDartDriverImage();
  }

  //Text:
  @override
  OsDriverText? createText(String fontName, double fontSize, String value,
      bool dynamic, OsDriverCharacterList? dynamicList) {
    return OsDartDriverText(fontName, fontSize.toInt());
  }

  @override
  void startDrawingMultipleTexts() {}
  @override
  void stopDrawingMultipleTexts() {}
  @override
  bool isDrawingMultipleTexts() {
    return false;
  }

  //Hardware:
  @override
  bool isHardwareRenderer() {
    return false;
  }

  //depth buffer:
  @override
  void enableDepthTest(bool enable) {}
}

///////////////////////////////////////////////////////////////////////
// OsDartDriverText
///////////////////////////////////////////////////////////////////////

class OsDartDriverImage extends OsDriverImage {
  ui.Image? _bmp;
  int _width = 0;
  int _height = 0;
  int _filterType = 0;

  @override
  bool initWithFrame(DicomBridgeFrame frame) {
    final dims = frame.getDimensions();
    if (dims == null) return false;
    final width = dims.$1;
    final height = dims.$2;
    if (width <= 0 || height <= 0) return false;
    final pixels = Uint8List(width * height * 4);
    if (!frame.createBitmap(
      bits: 32,
      inverseColor: false,
      pixels: pixels,
      width: width,
      height: height,
    )) {
      return false;
    }
    return initWithPixels(width: width, height: height, pixels: pixels);
  }

  bool initWithPixels({
    required int width,
    required int height,
    required Uint8List pixels,
  }) {
    if (width <= 0 || height <= 0) return false;
    if (pixels.length < width * height * 4) return false;
    _width = width;
    _height = height;
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        _bmp = image;
      },
    );
    return true;
  }

  bool initFromImageData(ui.Image image) {
    _bmp = image;
    _width = image.width;
    _height = image.height;
    return true;
  }

  // Draw:
  @override
  bool willDraw(OsDriverContext ctx) {
    //return _bmp == null;
    return false;
  }

  @override
  void draw(OsDriver driver, OsRenderInfo info, bool useAlpha) {
    if (_bmp == null || _width <= 0 || _height <= 0) return;
    final context = driver.currentContext;
    if (context is! OsDartDriverContext || context.canvas == null) return;

    final viewport = <double>[0, 0, 0, 0];
    driver.getViewport(viewport);
    final globalMatrix = OsMatrix();
    globalMatrix.mat[0] = viewport[2] * 0.5;
    globalMatrix.mat[5] = -viewport[3] * 0.5;
    globalMatrix.mat[12] = viewport[2] * 0.5 + viewport[0];
    globalMatrix.mat[13] = viewport[3] * 0.5 + viewport[1];

    final invertMatrix = OsMatrix();
    invertMatrix.mat[5] = -1;

    info.pushMatrix();
    final scaleToOneMatrix = OsMatrix();
    scaleToOneMatrix.mat[0] = 1.0 / _width;
    scaleToOneMatrix.mat[5] = 1.0 / _height;
    info.applyWorldTransformation(scaleToOneMatrix);

    globalMatrix.postMultiply(info.projMat);
    globalMatrix.postMultiply(info.viewMat);
    globalMatrix.postMultiply(info.worldMat);
    globalMatrix.postMultiply(invertMatrix);
    info.popMatrix();

    final canvas = context.canvas!;
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality =
          _filterType == 0 ? FilterQuality.none : FilterQuality.medium;

    canvas.save();
    canvas.transform(Float64List.fromList(globalMatrix.mat));
    canvas.drawImage(_bmp!, Offset(-_width * 0.5, -_height * 0.5), paint);
    canvas.restore();
  }

  // Filter:
  @override
  set filterType(int type) {
    _filterType = type;
  }

  @override
  int get filterType {
    return _filterType;
  }
}

///////////////////////////////////////////////////////////////////////
// OsDartDriverText
///////////////////////////////////////////////////////////////////////

class OsDartDriverText extends OsDriverText {
  String _text = '';
  bool _wordWrap = false;
  final List<double> marginSize = [0.0, 0.0];
  final List<double> frameSize = [0.0, 0.0];
  final List<double> frameLimits = [0.0, 0.0];
  final List<double> trueTextSize = [0.0, 0.0];
  String _fontName = '';
  int _fontSize = 12;
  int _alignment = OsDriverText.alignCenter;
  bool useAntialiasing = false;
  Color textColor = Colors.black;
  TextSpan? textSpan;
  TextPainter? textPainter;

  OsDartDriverText(fontName, fontSize) {
    setFont(fontName, fontSize);
  }

  //--------------------------------------------
  //text
  //--------------------------------------------

  @override
  set text(String str) {
    if (_text != str) {
      _text = str;
      textSpan = null;
      textPainter = null;
    }
  }

  @override
  String get text {
    return _text;
  }

  //--------------------------------------------
  //alignment
  //--------------------------------------------

  @override
  set alignment(int type) {
    if (_alignment != type) {
      _alignment = type;
      if (frameLimits[0] != 0 && frameSize[0] > frameLimits[0]) {
        textSpan = null;
        textPainter = null;
      }
    }
  }

  @override
  int get alignment {
    return _alignment;
  }

  //--------------------------------------------
  //word wrap
  //--------------------------------------------

  @override
  set wordWrap(bool enable) {
    if (_wordWrap != enable) {
      textSpan = null;
      textPainter = null;
    }
    _wordWrap = enable;
  }

  @override
  bool get wordWrap {
    return _wordWrap;
  }

  //--------------------------------------------
  //font
  //--------------------------------------------

  @override
  void setFont(String name, int size) {
    _fontName = name;
    _fontSize = size;
    textSpan = null;
    textPainter = null;
  }

  @override
  String getFont(List<int>? size) {
    if (size != null && size.isNotEmpty) {
      size[0] = _fontSize;
    }
    return _fontName;
  }

  //--------------------------------------------
  //color
  //--------------------------------------------

  @override
  void setColor4i(int red, int green, int blue, int alpha) {
    textColor = Color.fromARGB(alpha, red, green, blue);
  }

  //--------------------------------------------
  //antialiasing
  //--------------------------------------------

  @override
  set antialiasing(bool use) {
    useAntialiasing = use;
    textSpan = null;
    textPainter = null;
  }

  @override
  bool get antialiasing {
    return useAntialiasing;
  }

  //--------------------------------------------
  //Dynamic
  //--------------------------------------------

  @override
  bool isDynamic() {
    return false;
  }

  @override
  OsDriverCharacterList? getDynamicCharacterList() {
    return null;
  }

  //--------------------------------------------
  //frame
  //--------------------------------------------

  void setFrameLimits(double width, double height) {
    if (frameLimits[0] != width) {
      if (width == 0) {
        if (frameSize[0] < frameLimits[0]) {
          textSpan = null;
          textPainter = null;
        }
      } else {
        if (width < frameSize[0]) {
          textSpan = null;
          textPainter = null;
        } else if (frameSize[0] < frameLimits[0]) {
          textSpan = null;
          textPainter = null;
        }
      }
      frameLimits[0] = width;
    }
    if (frameLimits[1] != height) {
      if (height == 0) {
        if (frameSize[1] < frameLimits[1]) {
          textSpan = null;
          textPainter = null;
        }
      } else {
        if (height < frameSize[1]) {
          textSpan = null;
          textPainter = null;
        } else if (frameSize[1] < frameLimits[1]) {
          textSpan = null;
          textPainter = null;
        }
      }
      frameLimits[1] = height;
    }
  }

  void getFrameLimits(List<double> widthHeight) {
    widthHeight[0] = frameLimits[0];
    widthHeight[1] = frameLimits[1];
  }

  @override
  bool getFrameSize(OsDriver driver, List<double> widthHeight) {
    if (textSpan == null || textPainter == null) {
      if (preRender(driver)) {
        widthHeight[0] = frameSize[0];
        widthHeight[1] = frameSize[1];
      } else {
        return false;
      }
    } else {
      widthHeight[0] = frameSize[0];
      widthHeight[1] = frameSize[1];
    }
    return true;
  }

  //--------------------------------------------
  //Draw
  //--------------------------------------------

  bool preRender(OsDriver driver) {
    if (textSpan == null) {
      TextStyle style =
          TextStyle(fontSize: _fontSize.toDouble(), color: textColor);
      textSpan = TextSpan(style: style, text: text);
      textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      textPainter!.layout();
    }

    if (_wordWrap) {
      if (frameLimits[0] == 0 && frameLimits[1] == 0) {
        _wordWrap = false;
      }
    }

    List<double> boundingBox = [0, 0, 2048, 2048];
    if (_wordWrap) {
      if (frameLimits[0] - marginSize[0] * 2 <= 0 ||
          frameLimits[1] - marginSize[1] * 2 <= 0) {
        boundingBox[2] = 0;
        boundingBox[3] = 0;
      } else {
        boundingBox[2] = textPainter!.width;
        boundingBox[3] = _fontSize.toDouble();
      }
    } else {
      boundingBox[2] = textPainter!.width;
      boundingBox[3] = _fontSize.toDouble();
    }

    List<double> imageSize = [0, 0];
    imageSize[0] = boundingBox[2];
    imageSize[1] = boundingBox[3];

    frameSize[0] = imageSize[0].toDouble();
    frameSize[1] = imageSize[1].toDouble();
    if (imageSize[0].toDouble().abs() - frameSize[0] > 0.05) {
      frameSize[0] += 1.0;
    }
    if (imageSize[1].toDouble().abs() - frameSize[1] > 0.05) {
      frameSize[1] += 1.0;
    }

    frameSize[0] += marginSize[0] * 2.0;
    frameSize[1] += marginSize[1] * 2.0;

    trueTextSize[0] = imageSize[0].floorToDouble();
    trueTextSize[1] = imageSize[1].floorToDouble();

    if (frameLimits[0] != 0) {
      if (frameSize[0] > frameLimits[0]) frameSize[0] = frameLimits[0];
    }

    if (frameLimits[1] != 0) {
      if (frameSize[1] > frameLimits[1]) frameSize[1] = frameLimits[1];
    }

    return true;
  }

  //--------------------------------------------
  //Draw
  //--------------------------------------------

  @override
  bool willDraw(OsDriverContext ctx) {
    return true;
  }

  @override
  void draw(OsDriver driver, OsRenderInfo info) {
    OsDartDriverContext? context =
        driver.currentContext as OsDartDriverContext?;
    if (context == null || context.canvas == null) return;

    List<double> viewport = [0, 0, 0, 0];
    driver.getViewport(viewport);

    OsMatrix viewportMatrix = OsMatrix();
    viewportMatrix.mat[0] = viewport[2] * 0.5;
    viewportMatrix.mat[5] = -viewport[3] * 0.5;
    viewportMatrix.mat[12] = viewport[2] * 0.5 + viewport[0];
    viewportMatrix.mat[13] = viewport[3] * 0.5 + viewport[1];

    OsMatrix invertMatrix = OsMatrix();
    invertMatrix.mat[5] = -1;

    //Calculate the global matrix:
    OsMatrix globalMatrix = viewportMatrix;
    globalMatrix.postMultiply(info.projMat);
    globalMatrix.postMultiply(info.viewMat);
    globalMatrix.postMultiply(info.worldMat);
    globalMatrix.postMultiply(invertMatrix);

    //transform:
    context.canvas!.save();
    context.canvas!.transform(Float64List.fromList(globalMatrix.mat));

    List<double> pos = [0, 0];
    bool wordWrap = _wordWrap;
    if (wordWrap) {
      if (frameLimits[0] == 0 && frameLimits[1] == 0) wordWrap = false;
    }

    if (frameSize[0] >= 1.0 && frameSize[1] >= 1.0) {
      if (wordWrap) {
        pos[0] = -frameSize[0] * 0.5 + marginSize[0];
        pos[1] = -frameSize[1] * 0.5 + marginSize[1];
      } else {
        if (alignment == OsDriverText.alignLeft) {
          pos[0] = -frameSize[0] * 0.5 + marginSize[0];
          pos[1] = -frameSize[1] * 0.5 + marginSize[1];
        } else if (alignment == OsDriverText.alignCenter) {
          pos[0] = -frameSize[0] * 0.5 +
              marginSize[0] -
              trueTextSize[0] * 0.5 +
              (frameSize[0] - 2 * marginSize[0]) * 0.5;
          pos[1] = -frameSize[1] * 0.5 + marginSize[1];
        } else if (alignment == OsDriverText.alignRight) {
          pos[0] = -frameSize[0] * 0.5 +
              marginSize[0] -
              trueTextSize[0] +
              (frameSize[0] - 2 * marginSize[0]);
          pos[1] = -frameSize[1] * 0.5 + marginSize[1];
        }

        //draw:
        textPainter!.layout();

        double width = textPainter!.width;
        double height = textPainter!.height;

        textPainter!
            .paint(context.canvas!, Offset(-width * 0.5, -height * 0.5));
      }

      //restore:
      context.canvas!.restore();
    }
  }
}
