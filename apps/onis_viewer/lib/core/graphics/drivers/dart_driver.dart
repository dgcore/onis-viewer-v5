import 'package:flutter/material.dart';
import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';

///////////////////////////////////////////////////////////////////////
// context
///////////////////////////////////////////////////////////////////////

class OsDartDriverContext extends OsDriverContext {
  Canvas? canvas;
  final Paint _paint = Paint();
  Color clearColor = Colors.black;
  OsDartDriverContext(super.driver);

  /*@override
  bool isInitialized() {
    return true;
  }*/

  /*@override
  void getSize(List<double> size) {
    size[0] = 0;
    size[1] = 0;
  }*/

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

  // Getters:
  @override
  String get id => 'DART';

  // Operations:
  //OsDriver copy();

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
    return true;
  }

  @override
  bool popClipping() {
    if (_currentContext == null || _currentContext!.canvas == null) {
      return false;
    }
    _currentContext!.canvas!.restore();
    return true;
  }

  @override
  bool disableClipping() {
    return false;
  }

  @override
  bool isClippingEnabled() {
    return false;
  }

  @override
  void getClipArea(List<double> output) {}

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
    return null;
  }

  //Text:
  @override
  OsDriverText? createText(String fontName, double fontSize, String value,
      bool dynamic, OsDriverCharacterList? dynamicList) {
    return null;
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
// driver_image
///////////////////////////////////////////////////////////////////////

/*abstract class OsDriverImage {
  //public initWithFrame(frame =OsDicomFrame):void;
  //public initWithPixels(width =number, height =number, pixelFormat =number, pixels =Uint8ClampedArray):boolean { return false; }
  //public initFromImageData(data =ImageData):boolean { return false; }

  //Draw:
  bool willDraw(OsDriverContext ctx);
  void draw(OsDriver driver, OsRenderInfo info, bool useAlpha);

  //Filter:
  int get filterType;
  set filterType(int type);
}*/

///////////////////////////////////////////////////////////////////////
// driver_text
///////////////////////////////////////////////////////////////////////

/*abstract class OsDriverText {
  static const alignCenter = 0;
  static const alignLeft = 1;
  static const alignRight = 2;

  //text:
  String get text;
  set text(String str);

  //color:
  void setColor4d(double red, double green, double blue, double alpha);
  void setColor4i(int red, int green, int blue, int alpha);
  void setColor4iv(List<int> rgba);
  void setColor3h(String value);
  void setColorString(String value);

  //alignment:
  int get alignment;
  set alignment(int type);

  //word wrap:
  bool get wordWrap;
  set wordWrap(bool enable);

  //antialiasing:
  bool get antialiasing;
  set antialiasing(bool use);
  bool isUsingAntialiasing();

  //font:
  void setFont(String name, int size);
  String getFont(int size);

  //Draw:
  bool willDraw(OsDriverContext ctx);
  void draw(OsDriver driver, OsRenderInfo info);

  //Dynamic:
  bool isDynamic();
  OsDriverCharacterList? getDynamicCharacterList();
}*/
