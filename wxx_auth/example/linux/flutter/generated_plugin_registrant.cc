//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <wxx_auth/wxx_auth_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) wxx_auth_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "WxxAuthPlugin");
  wxx_auth_plugin_register_with_registrar(wxx_auth_registrar);
}
