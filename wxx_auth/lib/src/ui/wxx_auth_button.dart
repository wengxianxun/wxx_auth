import 'package:flutter/material.dart';

/// 登录按钮的样式配置。
class WxxAuthButtonStyle {
  const WxxAuthButtonStyle({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.borderRadius = 8,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final double borderRadius;
}

/// 通用品牌化登录按钮（左侧图标 + 居中文案 + 加载态）。
///
/// Google 等自定义按钮复用此组件；Apple 直接使用官方 [SignInWithAppleButton]。
class WxxAuthButton extends StatelessWidget {
  const WxxAuthButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.style,
    this.loading = false,
    this.height = 50,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? icon;
  final WxxAuthButtonStyle? style;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final s = style ??
        const WxxAuthButtonStyle(
          backgroundColor: Colors.white,
          textColor: Color(0xFF1F1F1F),
          borderColor: Color(0xFFDADCE0),
        );
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: s.backgroundColor,
          foregroundColor: s.textColor,
          disabledForegroundColor: s.textColor.withValues(alpha: 0.6),
          disabledBackgroundColor: s.backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(s.borderRadius),
            side: s.borderColor != null
                ? BorderSide(color: s.borderColor!)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: s.textColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: icon,
                    ),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: s.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
