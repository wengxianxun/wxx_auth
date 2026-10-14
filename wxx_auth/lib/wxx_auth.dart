import 'package:get/get.dart';

import 'src/config/wxx_auth_config.dart';
import 'src/controller/wxx_auth_controller.dart';
import 'src/ui/wxx_auth_view.dart';
import 'wxx_auth_platform_interface.dart';

export 'src/config/wxx_auth_config.dart';
export 'src/controller/wxx_auth_controller.dart';
export 'src/core/auth_method.dart';
export 'src/models/auth_user.dart';
export 'src/models/taptap_compliance.dart';
export 'src/ui/wxx_auth_button.dart';
export 'src/ui/wxx_auth_view.dart';

/// wxx_auth 第三方登录整合插件入口。
///
/// 使用流程：
/// 1. 在 `main()` 中调用 [WxxAuth.init] 统一配置要启用的登录方式；
/// 2. 在 UI 中放入 [WxxAuthView]；
/// 3. 通过 [WxxAuth.controller] 读取登录状态或调用登出。
///
/// 状态管理基于 GetX（[WxxAuthController]），无需额外引入状态库。
class WxxAuth {
  WxxAuth._();

  static WxxAuthController? _controller;

  /// 全局登录控制器。未调用 [init] 前访问会抛异常。
  static WxxAuthController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('WxxAuth.init() 尚未调用，请先在 main() 中初始化。');
    }
    return c;
  }

  /// 统一初始化。根据 [config] 构建并注册各登录方式（可选、可扩展）。
  ///
  /// - [config.methods] 决定启用哪些登录方式；
  /// - [config.autoRestore] 决定是否尝试静默恢复已有会话。
  static Future<WxxAuthController> init(WxxAuthConfig config) async {
    final methods = config.buildMethods();
    // 各登录方式平台级 SDK 初始化（如 TapTap 需要 clientId/clientToken 预热）。
    // 幂等，且需在恢复会话 / 登录之前完成。
    await Future.wait(methods.map((m) => m.initialize()));
    final controller = WxxAuthController(
      methods,
      ui: config.ui,
      autoRestore: config.autoRestore,
    );
    if (Get.isRegistered<WxxAuthController>()) {
      await Get.delete<WxxAuthController>(force: true);
    }
    Get.put(controller, permanent: true);
    _controller = controller;
    if (config.autoRestore) {
      // 异步恢复会话，不阻塞应用启动。
      controller.restoreSession();
    }
    return controller;
  }

  /// 保留的兼容方法（来自插件脚手架），返回平台版本字符串。
  static Future<String?> getPlatformVersion() =>
      WxxAuthPlatform.instance.getPlatformVersion();
}
