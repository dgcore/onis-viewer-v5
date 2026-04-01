import 'package:onis_viewer/core/dicom/dicom_frame.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';

///////////////////////////////////////////////////////////////////////
// character
///////////////////////////////////////////////////////////////////////

class OsDriverCharacter {
  int value = 0;
  final List<double> frameSize = [0.0, 0.0];
  final List<int> textureSize = [0, 0];
  void draw(OsDriver driver, OsRenderInfo info) {}
}

///////////////////////////////////////////////////////////////////////
// character_list
///////////////////////////////////////////////////////////////////////

abstract class OsDriverCharacterList {
  String get id;
  OsDriverCharacter? get(int character);
  OsDriverCharacter? add(int character);
  bool setFont(String name, int size);
  String getFontName();
  int getFontSize();
  OsDriverContext? getContext();
  void useAntialisasing(bool use);
  bool isUsingAntialiasing();
}

///////////////////////////////////////////////////////////////////////
// context
///////////////////////////////////////////////////////////////////////

abstract class OsDriverContext {
  final WeakReference<OsDriver> _wDriver;

  OsDriverContext(OsDriver driver) : _wDriver = WeakReference(driver);

  /*void dispose() {
    cleanup();
  }*/

  //properties:
  /*bool isInitialized();
  void getSize(List<double> size) {
    size[0] = 0;
    size[1] = 0;
  }*/

  OsDriver? get driver => _wDriver.target;

  //operations:
  //void resize(double width, double height);
  //void setTargetBuffer(int target);
  //void swappBuffers();

  //video text:
  bool registerText(OsDriverText item, Object data);
  OsDriverText? findText(
      Object data, String value, String fontName, int fontSize);
  void cleanTexts();
  void resetTexts();
  void setMaximumVideoTextEntries(int maxValue);

  //character list:
  OsDriverCharacterList? createCharacterList(String id);
  OsDriverCharacterList? findCharacterList(String id);
  bool removeCharacterList(String id);

  //capacity:
  //void getMaximumTextureSize(List<double> size);

  //cleanup:
  //void cleanup();
}

///////////////////////////////////////////////////////////////////////
// driver
///////////////////////////////////////////////////////////////////////

abstract class OsDriver {
  // Getters:
  String get id;

  // Operations:
  //OsDriver copy();

  // Context:
  OsDriverContext createContext();
  OsDriverContext? get currentContext;
  set currentContext(OsDriverContext? ctx);

  //viewport:
  void setViewport(double offsetX, double offsetY, double width, double height);
  void getViewport(List<double> viewport);

  // Clipping:
  bool pushClipping(
      double offsetX, double offsetY, double width, double height);
  bool popClipping();
  bool disableClipping();
  bool isClippingEnabled();
  void getClipArea(List<double> output);

  // Clear:
  void setClearColor4d(double red, double green, double blue, double alpha);
  void setClearColor4i(int red, int green, int blue, int alpha);
  void clearBuffers();
  void resetTransform();

  // Colors:
  void setColor4d(double red, double green, double blue, double alpha) {}
  void setColor4i(int red, int green, int blue, int alpha) {}
  void setColor4iv(List<int> rgba) {}
  void setColor3h(String value) {}
  void setColorString(String value) {}

  //Line:
  void setLineWidth(double width);
  bool enableLineStipple(bool enable);

  //Point size:
  void setPointSize(double size);

  //Draw:
  void fillSolidRect(OsRenderInfo info, double width, double height);
  void drawLine(OsRenderInfo info, double x1, double y1, double x2, double y2);
  void drawRect(OsRenderInfo info, double x1, double y1, double x2, double y2);
  void drawPoint(OsRenderInfo info, double x, double y);
  void drawEllipse(OsRenderInfo info, double a, double b);
  void fillTriangle(
      OsRenderInfo info, List<double> a, List<double> b, List<double> c);
  void drawImage(OsRenderInfo info, OsDriverImage image, double offsetX,
      double offsetY, double width, double height);

  //Images:
  OsDriverImage? createImage();
  //Text:
  OsDriverText? createText(String fontName, double fontSize, String value,
      bool dynamic, OsDriverCharacterList? dynamicList);
  void startDrawingMultipleTexts();
  void stopDrawingMultipleTexts();
  bool isDrawingMultipleTexts();

  //Hardware:
  bool isHardwareRenderer();

  //depth buffer:
  void enableDepthTest(bool enable);
}

///////////////////////////////////////////////////////////////////////
// driver_image
///////////////////////////////////////////////////////////////////////

abstract class OsDriverImage {
  bool initWithFrame(DicomFrame frame);

  //public initWithFrame(frame =OsDicomFrame):void;
  //public initWithPixels(width =number, height =number, pixelFormat =number, pixels =Uint8ClampedArray):boolean { return false; }
  //public initFromImageData(data =ImageData):boolean { return false; }

  //Draw:
  bool willDraw(OsDriverContext ctx);
  void draw(OsDriver driver, OsRenderInfo info, bool useAlpha);

  //Filter:
  int get filterType;
  set filterType(int type);
}

///////////////////////////////////////////////////////////////////////
// driver_text
///////////////////////////////////////////////////////////////////////

abstract class OsDriverText {
  static const alignCenter = 0;
  static const alignLeft = 1;
  static const alignRight = 2;

  //text:
  String get text;
  set text(String str);

  //color:
  void setColor4i(int red, int green, int blue, int alpha);

  //alignment:
  int get alignment;
  set alignment(int type);

  //word wrap:
  bool get wordWrap;
  set wordWrap(bool enable);

  //antialiasing:
  bool get antialiasing;
  set antialiasing(bool use);

  //font:
  void setFont(String name, int size);
  String getFont(List<int>? size);

  // frame:
  bool getFrameSize(OsDriver driver, List<double> widthHeight);

  //Draw:
  bool willDraw(OsDriverContext ctx);
  void draw(OsDriver driver, OsRenderInfo info);

  //Dynamic:
  bool isDynamic();
  OsDriverCharacterList? getDynamicCharacterList();
}
