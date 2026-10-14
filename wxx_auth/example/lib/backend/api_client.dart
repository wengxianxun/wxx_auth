import 'dart:convert';

import 'package:http/http.dart' as http;

/// 是否打印 API 调用日志（含 URL / 请求头 / 请求体 / 状态码 / 响应体）。
/// 接入后端调试时设为 true；正式发布可设为 false。
const bool kEnableApiLog = true;

void _logApi(String line) {
  if (kEnableApiLog) {
    // ignore: avoid_print
    print('[API] $line');
  }
}

/// 本地后端基地址（SpeedPHP 入口文件）。
///
/// 若你的服务器已通过 .htaccess 隐藏 index.php，可改为
/// `'http://192.168.31.76/nboxphp'`，并把下面的接口路径改为
/// `'/api/auth/signin'` 之前不带 `/index.php`。
const String kBackendBaseUrl = 'http://192.168.31.76/nboxphp';

/// 极简 HTTP 封装：负责 JSON 编解码、Bearer token 注入与统一错误解析。
class ApiClient {
  ApiClient({this.baseUrl = kBackendBaseUrl}) : _client = http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _accessToken;

  /// 已签发的后台 JWT（signin 成功后设置）。
  String? get accessToken => _accessToken;

  void setToken(String token) => _accessToken = token;
  void clearToken() => _accessToken = null;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json; charset=utf-8',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = _uri(path);
    _logApi('→ POST $url');
    _logApi('  headers: ${_redactHeaders(_headers)}');
    _logApi('  body: ${_pretty(body)}');
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(response, 'POST', url);
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final url = _uri(path);
    _logApi('→ GET $url');
    _logApi('  headers: ${_redactHeaders(_headers)}');
    final response = await _client.get(url, headers: _headers);
    return _handle(response, 'GET', url);
  }

  /// 后端自检（`GET /api/auth/ping`，无需鉴权），确认模块路由与配置已加载。
  Future<Map<String, dynamic>> ping() => getJson('/api/auth/ping');

  Map<String, dynamic> _handle(http.Response response, String method, Uri url) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'unexpected_response');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _logApi('← $method $url ${response.statusCode}');
      _logApi('  response: ${_pretty(decoded)}');
      return decoded;
    }
    _logApi('← $method $url ${response.statusCode} (ERROR)');
    _logApi('  response: ${_pretty(decoded)}');
    throw ApiException(
      response.statusCode,
      decoded['error']?.toString() ?? 'unknown_error',
    );
  }
}

/// 把请求体/响应体格式化为可读字符串（便于控制台查看）。
String _pretty(Object? value) {
  try {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(value);
  } catch (_) {
    return value.toString();
  }
}

/// 对 Authorization 头做脱敏，避免 token 直接打进日志。
String _redactHeaders(Map<String, String> headers) {
  final entries = headers.entries.map((e) {
    if (e.key.toLowerCase() == 'authorization') {
      final token = e.value;
      final short = token.length > 16 ? '${token.substring(0, 16)}…' : token;
      return '${e.key}: $short (redacted)';
    }
    return '${e.key}: ${e.value}';
  });
  return '{${entries.join(', ')}}';
}

/// 后端返回的结构化异常（含 HTTP 状态码与 error 字段）。
class ApiException implements Exception {
  const ApiException(this.statusCode, this.error);

  final int statusCode;
  final String error;

  @override
  String toString() => 'ApiException($statusCode): $error';
}
