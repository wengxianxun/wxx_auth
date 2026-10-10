#ifndef FLUTTER_PLUGIN_WXX_AUTH_PLUGIN_H_
#define FLUTTER_PLUGIN_WXX_AUTH_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace wxx_auth {

class WxxAuthPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WxxAuthPlugin();

  virtual ~WxxAuthPlugin();

  // Disallow copy and assign.
  WxxAuthPlugin(const WxxAuthPlugin&) = delete;
  WxxAuthPlugin& operator=(const WxxAuthPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace wxx_auth

#endif  // FLUTTER_PLUGIN_WXX_AUTH_PLUGIN_H_
