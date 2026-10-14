import 'package:get/get.dart';

import '../config/wxx_auth_config.dart';
import '../core/auth_method.dart';
import '../models/auth_user.dart';
import '../models/taptap_compliance.dart';
import '../providers/taptap_auth.dart';

/// 基于 GetX 的登录状态控制器（全局单例，由 [WxxAuth.init] 注册）。
///
/// 负责：当前登录用户 [user]、全局/单方式加载态、错误信息，以及
/// 统一的 [signInWith] / [signOut] / [restoreSession] 入口。
class WxxAuthController extends GetxController {
  WxxAuthController(
    this.methods, {
    required this.ui,
    this.autoRestore = true,
  });

  /// 已配置的登录方式。
  final List<AuthMethod> methods;

  /// UI 配置（供 [WxxAuthView] 读取）。
  final WxxAuthUiConfig ui;

  /// 是否自动恢复会话。
  final bool autoRestore;

  /// 当前登录用户（未登录为 null）。
  final Rxn<AuthUser> user = Rxn<AuthUser>();

  /// 是否正在执行任意登录/登出动作。
  final RxBool isLoading = false.obs;

  /// 最近一次错误信息（为空表示无错误）。
  final RxString error = ''.obs;

  /// 正在登录中的方式 id 集合（用于按钮加载态）。
  final RxList<String> signingIn = <String>[].obs;

  /// TapTap 防沉迷校验结果（非 TapTap 登录或已关闭时为 null）。
  final Rxn<TaptapComplianceResult> compliance = Rxn<TaptapComplianceResult>();

  AuthMethod? methodById(String id) =>
      methods.where((m) => m.id == id).firstOrNull;

  bool isSigningIn(String id) => signingIn.contains(id);

  /// 静默恢复已有会话（遍历各方式，命中第一个有效会话即返回）。
  Future<void> restoreSession() async {
    for (final m in methods) {
      try {
        final u = await m.getCurrentUser();
        if (u != null) {
          user.value = u;
          return;
        }
      } catch (_) {
        // 忽略单个登录方式的恢复失败
      }
    }
  }

  /// 通过方式 id 发起登录（如 `'google'`、`'apple'`）。
  Future<void> signInWith(String methodId) async {
    if (signingIn.contains(methodId)) return;
    final method = methodById(methodId);
    if (method == null) {
      error.value = '未配置的登录方式: $methodId';
      return;
    }
    signingIn.add(methodId);
    signingIn.refresh();
    error.value = '';
    isLoading.value = true;
    try {
      final u = await method.signIn();
      user.value = u;
      // 若本次登录为 TapTap 且开启了防沉迷，记录校验结果。
      if (method is TaptapAuth) compliance.value = method.lastCompliance;
    } on AuthException catch (e) {
      // 用户主动取消（如 Google 取消）不视为错误，不展示错误提示。
      if (e.code != 'cancelled') error.value = e.message;
    } catch (e) {
      error.value = '登录失败：$e';
    } finally {
      signingIn.remove(methodId);
      signingIn.refresh();
      if (signingIn.isEmpty) isLoading.value = false;
    }
  }

  /// 退出所有已配置的登录方式，并清空本地会话。
  Future<void> signOut() async {
    for (final m in methods) {
      try {
        await m.signOut();
      } catch (_) {
        // 忽略单一登出异常
      }
    }
    user.value = null;
    error.value = '';
    compliance.value = null;
  }
}
