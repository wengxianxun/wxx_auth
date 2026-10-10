import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'wxx_auth_method_channel.dart';

abstract class WxxAuthPlatform extends PlatformInterface {
  /// Constructs a WxxAuthPlatform.
  WxxAuthPlatform() : super(token: _token);

  static final Object _token = Object();

  static WxxAuthPlatform _instance = MethodChannelWxxAuth();

  /// The default instance of [WxxAuthPlatform] to use.
  ///
  /// Defaults to [MethodChannelWxxAuth].
  static WxxAuthPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WxxAuthPlatform] when
  /// they register themselves.
  static set instance(WxxAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
