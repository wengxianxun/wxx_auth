import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/wxx_auth_controller.dart';

/// 登录视图：根据已配置的登录方式动态渲染按钮。
///
/// 可直接作为页面主体，也可放在 [Dialog] / [BottomSheet] 中使用。
/// 所有状态（用户、加载、错误）均来自 GetX 的 [WxxAuthController]。
class WxxAuthView extends StatelessWidget {
  const WxxAuthView({
    this.title,
    this.subtitle,
    this.spacing,
    this.padding,
    this.showErrors,
    super.key,
  });

  /// 覆盖 [WxxAuthUiConfig.title]。
  final String? title;

  /// 覆盖 [WxxAuthUiConfig.subtitle]。
  final String? subtitle;

  /// 覆盖 [WxxAuthUiConfig.buttonSpacing]。
  final double? spacing;

  /// 覆盖 [WxxAuthUiConfig.padding]。
  final EdgeInsetsGeometry? padding;

  /// 覆盖 [WxxAuthUiConfig.showErrors]。
  final bool? showErrors;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WxxAuthController>();
    return Obx(() {
      final ui = controller.ui;
      final t = title ?? ui.title;
      final sub = subtitle ?? ui.subtitle;
      final sp = spacing ?? ui.buttonSpacing;
      final pad = padding ?? ui.padding;
      final showErr = showErrors ?? ui.showErrors;

      final children = <Widget>[];
      if (t != null) {
        children.add(Text(t, style: Theme.of(context).textTheme.titleLarge));
        children.add(const SizedBox(height: 8));
      }
      if (sub != null) {
        children.add(
          Text(
            sub,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        );
        children.add(const SizedBox(height: 24));
      }
      for (var i = 0; i < controller.methods.length; i++) {
        final m = controller.methods[i];
        children.add(
          m.buildButton(
            onPressed: () => controller.signInWith(m.id),
            loading: controller.isSigningIn(m.id),
          ),
        );
        if (i < controller.methods.length - 1) {
          children.add(SizedBox(height: sp));
        }
      }
      if (showErr && controller.error.value.isNotEmpty) {
        children.add(const SizedBox(height: 12));
        children.add(
          Text(
            controller.error.value,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
      }
      return Padding(
        padding: pad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    });
  }
}
