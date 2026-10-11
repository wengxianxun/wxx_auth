/// 登录成功后的用户信息模型。
///
/// 同时兼容 Google 与 Apple 两种来源：
/// - Google 的 idToken / accessToken 落在 [idToken] / [accessToken]。
/// - Apple 的 identityToken 落在 [identityToken]，授权码落在 [authorizationCode]。
class AuthUser {
  const AuthUser({
    required this.providerId,
    this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.accessToken,
    this.identityToken,
    this.authorizationCode,
    this.raw,
  });

  /// 来源登录方式 id，例如 `'google'`、`'apple'`。
  final String providerId;

  /// 第三方平台分配的用户唯一标识。
  final String? id;

  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Google：JWT id_token（用于后端校验）。
  final String? idToken;

  /// Google：OAuth access_token。
  final String? accessToken;

  /// Apple：identityToken（JWT）。
  final String? identityToken;

  /// Apple：authorizationCode（需发给后端换取 session）。
  final String? authorizationCode;

  /// 各平台原始的返回对象，便于取出额外字段。
  final Map<String, dynamic>? raw;

  AuthUser copyWith({
    String? providerId,
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? idToken,
    String? accessToken,
    String? identityToken,
    String? authorizationCode,
    Map<String, dynamic>? raw,
  }) {
    return AuthUser(
      providerId: providerId ?? this.providerId,
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      idToken: idToken ?? this.idToken,
      accessToken: accessToken ?? this.accessToken,
      identityToken: identityToken ?? this.identityToken,
      authorizationCode: authorizationCode ?? this.authorizationCode,
      raw: raw ?? this.raw,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'idToken': idToken,
      'accessToken': accessToken,
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
    };
  }

  @override
  String toString() {
    return 'AuthUser(providerId: $providerId, id: $id, email: $email, '
        'displayName: $displayName)';
  }
}

/// 登录过程统一抛出的异常。
class AuthException implements Exception {
  const AuthException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException(${code ?? 'unknown'}): $message';
}
