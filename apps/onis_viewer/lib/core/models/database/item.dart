class Item {
  static final kBaseSeqKey = "seq";
  static final kBaseUidKey = "uid";

  static final kClone = 0;
  static final kMerge = 1;
  static final kInter = 2;

  String id = '';
  int flags = 0xFFFFFF;
  String version = '1.0.0';
  WeakReference<Item>? _wparent;
  final List<Item> _children = [];

  Item();

  Item? clone(bool children) {
    return null;
  }

  bool hasFlag(int flag) => (flags & flag) != 0;

  bool haveSameProperties(Item item) {
    return compare(item) == 0;
  }

  int compare(Item item) {
    return 0;
  }

  Item? get parent => _wparent?.target;

  void clearChildren() {
    while (_children.isNotEmpty) {
      _children[0].setParent(null);
    }
  }

  void getChildren(List<Item> children, bool all) {
    for (int i = 0; i < _children.length; i++) {
      children.add(_children[i]);
      if (all) _children[i].getChildren(children, all);
    }
  }

  List<Item> get children => List.unmodifiable(_children);

  void setParent(Item? parent) {
    Item? currentParent = parent;
    if (currentParent == parent) return;
    if (currentParent != null) {
      currentParent._children.remove(this);
      _wparent = null;
    }
    if (parent != null) {
      parent._children.add(this);
      _wparent = WeakReference(parent);
    }
  }

  bool copyTo(Item target, int mode) {
    if (runtimeType != target.runtimeType) return false;
    if (version != target.version) return false;
    return true;
  }

  void toJson(Map<String, dynamic> json) {
    json['id'] = id;
    json['version'] = version;
    json['flags'] = flags;
  }
}
