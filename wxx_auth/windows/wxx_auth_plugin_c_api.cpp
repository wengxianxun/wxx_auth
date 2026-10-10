#include "include/wxx_auth/wxx_auth_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "wxx_auth_plugin.h"

void WxxAuthPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  wxx_auth::WxxAuthPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
