/// 后端返回的用户模型（对应 `users` 表对外字段）。
class BackendUser {
  const BackendUser({
    required this.uuid,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.lastLoginAt,
  });

  factory BackendUser.fromJson(Map<String, dynamic> json) => BackendUser(
        uuid: json['uuid'] as String,
        email: json['email'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        lastLoginAt: json['last_login_at'] as String?,
      );

  final String uuid;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? lastLoginAt;
}

/// 登录接口返回：后台自签 JWT + 用户信息。
class SignInResult {
  const SignInResult({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.isNew,
    required this.user,
  });

  factory SignInResult.fromJson(Map<String, dynamic> json) => SignInResult(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String? ?? 'Bearer',
        expiresIn: json['expires_in'] as int? ?? 0,
        isNew: json['is_new'] as bool? ?? false,
        user: BackendUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final bool isNew;
  final BackendUser user;
}

/// 已绑定的第三方登录方式（体现「一人多平台」）。
class ProfileProvider {
  const ProfileProvider({
    required this.provider,
    required this.providerUserId,
    this.email,
    this.unionId,
    this.createdAt,
  });

  factory ProfileProvider.fromJson(Map<String, dynamic> json) => ProfileProvider(
        provider: json['provider'] as String,
        providerUserId: json['provider_user_id'] as String,
        email: json['email'] as String?,
        unionId: json['union_id'] as String?,
        createdAt: json['created_at'] as String?,
      );

  final String provider;
  final String providerUserId;
  final String? email;
  final String? unionId;
  final String? createdAt;
}

/// 获取用户信息接口返回：用户 + 已绑平台列表。
class ProfileResult {
  const ProfileResult({required this.user, required this.providers});

  factory ProfileResult.fromJson(Map<String, dynamic> json) => ProfileResult(
        user: BackendUser.fromJson(json['user'] as Map<String, dynamic>),
        providers: (json['providers'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => ProfileProvider.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final BackendUser user;
  final List<ProfileProvider> providers;
}

/// 后端自检接口（`GET /api/auth/ping`）返回：模块是否就绪 + 已配置的登录方式。
class PingResult {
  const PingResult({required this.ok, required this.providers});

  factory PingResult.fromJson(Map<String, dynamic> json) => PingResult(
        ok: json['ok'] as bool? ?? false,
        providers: (json['provider'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList(),
      );

  final bool ok;
  final List<String> providers;
}
