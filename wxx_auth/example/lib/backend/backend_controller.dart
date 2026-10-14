import 'package:get/get.dart';
import 'package:wxx_auth/wxx_auth.dart';

import 'api_client.dart';
import 'auth_repository.dart';
import 'models.dart';

/// 示例用的后端状态控制器（GetX）。
///
/// 职责：
/// 1. 监听插件登录结果（[WxxAuth.controller.user]），登录成功后自动调后端
///    校验并换取 JWT；退出后清理 token。
/// 2. 管理后端返回的用户信息、profile（已绑平台）与错误状态，供 UI 展示。
///
/// 注意：这是一个**示例层**，不属于插件本身。生产应用可把 token 持久化到
/// 安全存储（如 flutter_secure_storage），而非仅存内存。
class BackendController extends GetxController {
  BackendController(this.repository);

  final AuthRepository repository;

  /// 最近一次 signin 结果（含 JWT 与后端用户）。
  final Rxn<SignInResult> signInResult = Rxn<SignInResult>();

  /// 是否正在向后端换 JWT。
  final RxBool isSigningInBackend = false.obs;

  /// 后端错误信息（为空表示无错误）。
  final RxString backendError = ''.obs;

  /// 当前用户的 profile（已绑平台列表）。
  final Rxn<ProfileResult> profile = Rxn<ProfileResult>();

  /// 是否正在加载 profile。
  final RxBool isLoadingProfile = false.obs;

  /// 后端自检结果（`GET /api/auth/ping`）。
  final Rxn<PingResult> pingResult = Rxn<PingResult>();

  /// 是否正在自检。
  final RxBool isPinging = false.obs;

  /// 自检错误信息。
  final RxString pingError = ''.obs;

  late final Worker _worker;

  @override
  void onInit() {
    super.onInit();
    // 若 init 时已通过 autoRestore 恢复了登录态，先补一次后端校验。
    final current = WxxAuth.controller.user.value;
    if (current != null) _exchangeToken(current);
    // 之后监听登录/退出变化。
    _worker = ever<AuthUser?>(WxxAuth.controller.user, (user) {
      if (user != null) {
        _exchangeToken(user);
      } else {
        signInResult.value = null;
        profile.value = null;
        repository.signOut();
      }
    });
  }

  @override
  void onClose() {
    _worker.dispose();
    super.onClose();
  }

  Future<void> _exchangeToken(AuthUser user) async {
    isSigningInBackend.value = true;
    backendError.value = '';
    try {
      signInResult.value = await repository.signIn(user);
    } on ApiException catch (e) {
      backendError.value = '后端校验失败：${_describeApiError(e)}';
    } on AuthException catch (e) {
      backendError.value = '登录凭证异常：${e.message}';
    } catch (e) {
      backendError.value = '网络错误：$e';
    } finally {
      isSigningInBackend.value = false;
    }
  }

  /// 拉取当前用户信息（含已绑定的第三方平台）。
  Future<void> loadProfile() async {
    if (repository.api.accessToken == null) return;
    isLoadingProfile.value = true;
    backendError.value = '';
    try {
      profile.value = await repository.profile();
    } on ApiException catch (e) {
      backendError.value = '获取资料失败：${_describeApiError(e)}';
    } catch (e) {
      backendError.value = '网络错误：$e';
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// 后端自检（无需鉴权）：确认模块路由与配置已加载。
  Future<void> ping() async {
    isPinging.value = true;
    pingError.value = '';
    try {
      pingResult.value = await repository.ping();
    } on ApiException catch (e) {
      pingError.value = '自检失败：${_describeApiError(e)}';
    } catch (e) {
      pingError.value = '网络错误：$e';
    } finally {
      isPinging.value = false;
    }
  }
  static String _describeApiError(ApiException e) {
    const messages = <String, String>{
      'invalid_request': '请求格式不正确（应为 JSON）',
      'unsupported_provider': '不支持的登录方式（仅 google/apple/taptap）',
      'verify_error': '后台校验三方凭证时出错（可能网络拉取公钥失败）',
      'invalid_credentials': '三方凭证校验失败（签名/aud/exp 不匹配，或 TapTap 回查不一致）',
      'server_error': '服务器落库异常，请稍后重试',
      'unauthorized': '缺少登录凭证',
      'invalid_token': '登录凭证无效或已过期',
      'user_not_found_or_disabled': '用户不存在或已被封禁',
    };
    final detail = messages[e.error] ?? e.error;
    return '$detail（${e.statusCode} ${e.error}）';
  }
}
