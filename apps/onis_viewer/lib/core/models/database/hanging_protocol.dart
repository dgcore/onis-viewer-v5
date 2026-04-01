///////////////////////////////////////////////////////////////////////
// HpDicomTag
///////////////////////////////////////////////////////////////////////
library;

class HpDicomTag {
  int tag;
  String vr;
  int matching;
  String value;
  String description;

  HpDicomTag(
      {required this.tag,
      required this.description,
      required this.vr,
      required this.matching,
      required this.value});

  HpDicomTag clone() {
    return HpDicomTag(
        tag: tag,
        description: description,
        vr: vr,
        matching: matching,
        value: value);
  }
}
