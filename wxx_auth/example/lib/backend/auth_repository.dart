import 'package:wxx_auth/wxx_auth.dart';

import 'api_client.dart';
import 'models.dart';

/// 后端登录业务封装：把插件登录拿到的 [AuthUser] 转换为后端要求的请求体，
/// 调用 `/api/auth/signin` 换取 JWT，并提供 `/api/user/profile` 查询。
class AuthRepository {
  AuthRepository(this.api);

  final ApiClient api;

  /// 按 provider 提取三方凭证并发送登录请求。
  ///
  /// - Google : `idToken`
  /// - Apple  : `identityToken`（首次授权附 `fullName`）
  /// - TapTap : `accessToken` + `openId`(+ `unionId` + `macKey`)
  Future<SignInResult> signIn(AuthUser user) async {
    final body = <String, dynamic>{'provider': user.providerId};

    switch (user.providerId) {
      case 'google':
        body['idToken'] = user.idToken;
        break;

      case 'apple':
        body['identityToken'] = user.identityToken;
        final raw = user.raw;
        final given = raw?['givenName'] as String?;
        final family = raw?['familyName'] as String?;
        // Apple 姓名仅在首次授权返回且不在 JWT 中，需客户端一并提交。
        if ((given?.isNotEmpty ?? false) || (family?.isNotEmpty ?? false)) {
          body['fullName'] = <String, dynamic>{
            'givenName': given ?? '',
            'familyName': family ?? '',
          };
        }
        break;

      case 'taptap':
        // 关键：accessToken 必须是真实的 kid 字符串，macKey 必须传真实值（不能为 null）。
        // 二者由 flutter_taptap 从 SDK 的 AccessToken 对象中提取（原生层已修正），
        // 切勿把 AccessToken 整个对象（或其 toString()）传过来。
        final kid = user.accessToken;
        if (kid == null || kid.isEmpty) {
          throw const AuthException('TapTap 登录缺少 accessToken(kid)', 'missing_token');
        }
        body['accessToken'] = kid;
        body['openId'] = user.id;
        final raw = user.raw;
        body['unionId'] = raw?['unionId'];
        final macKey = raw?['macKey'] as String?;
        if (macKey == null || macKey.isEmpty) {
          throw const AuthException('TapTap 登录缺少 macKey', 'missing_mac_key');
        }
        body['macKey'] = macKey;
        break;
    }

    final data = await api.postJson('/api/auth/signin', body);
    final token = data['access_token'] as String;
    api.setToken(token); // 保存 JWT，后续请求自动携带
    final result = SignInResult.fromJson(data);
    // 打印后端登录结果（便于联调）
    // ignore: avoid_print
    print('[RESULT] signin(provider=${user.providerId}) -> uuid=${result.user.uuid}, '
        'isNew=${result.isNew}, email=${result.user.email ?? '-'}, '
        'name=${result.user.displayName ?? '-'}');
    return result;
  }

  /// 获取当前登录用户资料（需鉴权，自动携带 Bearer token）。
  Future<ProfileResult> profile() async {
    final data = await api.getJson('/api/user/profile');
    final result = ProfileResult.fromJson(data);
    // 打印后端用户资料结果（便于联调）
    // ignore: avoid_print
    print('[RESULT] profile -> uuid=${result.user.uuid}, '
        'email=${result.user.email ?? '-'}, '
        'name=${result.user.displayName ?? '-'}, '
        'providers=[${result.providers.map((p) => '${p.provider}:${p.providerUserId}').join(', ')}]');
    return result;
  }

  /// 后端自检（无需鉴权），用于确认模块路由与配置已加载。
  Future<PingResult> ping() async {
    final data = await api.ping();
    final result = PingResult.fromJson(data);
    // 打印自检结果（便于联调）
    // ignore: avoid_print
    print('[RESULT] ping -> ok=${result.ok}, providers=[${result.providers.join(', ')}]');
    return result;
  }

  /// 退出：清理本地保存的 JWT（插件侧的多方式登出由 [WxxAuth] 负责）。
  void signOut() => api.clearToken();
}
