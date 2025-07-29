/// ONIS Viewer API - Singleton class for accessing application-wide functionality
class OVApi {
  static final OVApi _instance = OVApi._internal();

  factory OVApi() {
    return _instance;
  }

  OVApi._internal();

  static OVApi get instance => _instance;

  String get version => '5.0.0';
  String get name => 'ONIS Viewer';
  bool get isInitialized => true;

  @override
  String toString() {
    return 'OVApi(version: $version, name: $name)';
  }
}
