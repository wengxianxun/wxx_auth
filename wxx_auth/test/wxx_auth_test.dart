import 'package:flutter_test/flutter_test.dart';
import 'package:wxx_auth/wxx_auth.dart';
import 'package:wxx_auth/wxx_auth_platform_interface.dart';
import 'package:wxx_auth/wxx_auth_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWxxAuthPlatform
    with MockPlatformInterfaceMixin
    implements WxxAuthPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WxxAuthPlatform initialPlatform = WxxAuthPlatform.instance;

  test('$MethodChannelWxxAuth is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWxxAuth>());
  });

  test('getPlatformVersion', () async {
    WxxAuth wxxAuthPlugin = WxxAuth();
    MockWxxAuthPlatform fakePlatform = MockWxxAuthPlatform();
    WxxAuthPlatform.instance = fakePlatform;

    expect(await wxxAuthPlugin.getPlatformVersion(), '42');
  });
}
