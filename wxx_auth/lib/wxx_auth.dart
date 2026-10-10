
import 'wxx_auth_platform_interface.dart';

class WxxAuth {
  Future<String?> getPlatformVersion() {
    return WxxAuthPlatform.instance.getPlatformVersion();
  }
}
