/// TapTap 防沉迷（实名 / 未成年人保护）合规状态。
///
/// 状态码与 `flutter_taptap` 的 [registerComplianceCallback] 回调一致。
enum TaptapComplianceStatus {
  /// 未初始化 / 尚未拿到任何回调。
  none,

  /// 500：玩家未受限制，正常进入游戏。
  success,

  /// 1000：退出防沉迷认证，游戏应返回登录页。
  exited,

  /// 1001：用户点击切换账号，游戏应返回登录页。
  switchAccount,

  /// 1030：用户当前时段无法进行游戏。
  periodRestrict,

  /// 1050：用户无可玩时长。
  durationLimit,

  /// 1100：当前用户因年龄限制无法进入游戏。
  ageLimit,

  /// 1200：数据请求失败（客户端 / 网络错误）。
  networkError,

  /// 9002：用户关闭了实名窗，可重新开始认证。
  realNameStop,

  /// 其它未知状态码。
  unknown,
}

extension TaptapComplianceStatusX on TaptapComplianceStatus {
  /// 是否允许继续游戏（仅 [success] 视为通过）。
  bool get canPlay => this == TaptapComplianceStatus.success;

  /// 是否受到限制（需返回登录页或阻断游戏）。
  bool get isRestricted =>
      this != TaptapComplianceStatus.success &&
      this != TaptapComplianceStatus.none &&
      this != TaptapComplianceStatus.unknown;
}

/// 防沉迷校验结果。
class TaptapComplianceResult {
  const TaptapComplianceResult({
    required this.status,
    this.code,
    this.remainingTime,
    this.message,
  });

  /// 合规状态。
  final TaptapComplianceStatus status;

  /// 原始状态码（来自 TapTap 回调）。
  final int? code;

  /// 剩余可玩时长（秒）。
  /// - `>= 0`：剩余可玩秒数；
  /// - `-1`：用户未登录或数据未初始化；
  /// - `-2`：用户不受时长限制（如成年人）。
  final int? remainingTime;

  /// 可选提示信息（异常时填入）。
  final String? message;

  bool get canPlay => status.canPlay;
  bool get isRestricted => status.isRestricted;

  @override
  String toString() =>
      'TaptapComplianceResult(status: $status, code: $code, '
      'remainingTime: $remainingTime)';

  /// 将回调中的数字状态码映射为 [TaptapComplianceStatus]。
  static TaptapComplianceStatus fromCode(int code) {
    switch (code) {
      case 500:
        return TaptapComplianceStatus.success;
      case 1000:
        return TaptapComplianceStatus.exited;
      case 1001:
        return TaptapComplianceStatus.switchAccount;
      case 1030:
        return TaptapComplianceStatus.periodRestrict;
      case 1050:
        return TaptapComplianceStatus.durationLimit;
      case 1100:
        return TaptapComplianceStatus.ageLimit;
      case 1200:
        return TaptapComplianceStatus.networkError;
      case 9002:
        return TaptapComplianceStatus.realNameStop;
      default:
        return TaptapComplianceStatus.unknown;
    }
  }
}
