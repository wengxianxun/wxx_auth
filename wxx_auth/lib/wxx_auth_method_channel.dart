import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wxx_auth_platform_interface.dart';

/// An implementation of [WxxAuthPlatform] that uses method channels.
class MethodChannelWxxAuth extends WxxAuthPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wxx_auth');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
